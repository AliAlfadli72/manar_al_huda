import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../services/firebase_service.dart';
import '../models/question.dart';

class OnlineDuelPlayScreen extends StatefulWidget {
  final String roomId;
  final bool isCreator;

  const OnlineDuelPlayScreen({
    super.key,
    required this.roomId,
    required this.isCreator,
  });

  @override
  State<OnlineDuelPlayScreen> createState() => _OnlineDuelPlayScreenState();
}

class _OnlineDuelPlayScreenState extends State<OnlineDuelPlayScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  
  // Local game states
  int _localQuestionIndex = 0;
  bool _isAnswered = false;
  
  // Timer settings
  int _timeLeft = 30;
  int _totalTimeForQuestion = 30;
  Timer? _timer;
  
  // To avoid duplicate advancement triggers
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    _startLocalTimer(30);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLocalTimer(int duration) {
    _timer?.cancel();
    setState(() {
      _timeLeft = duration;
      _totalTimeForQuestion = duration;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        // Time ran out, submit incorrect answer automatically
        if (!_isAnswered) {
          _handleAnswerSelection(-1, false, null);
        }
      }
    });
  }

  Future<void> _handleAnswerSelection(int optionIndex, bool isCorrect, Question? question) async {
    if (_isAnswered || question == null) return;

    _timer?.cancel();
    setState(() {
      _isAnswered = true;
    });

    // Submit to Firestore
    await _firebaseService.submitAnswer(
      roomId: widget.roomId,
      questionId: question.id,
      selectedIndex: optionIndex,
      isCorrect: isCorrect,
      timeLeft: _timeLeft,
    );
  }

  IconData _getAvatarIcon(String avatarId) {
    switch (avatarId) {
      case 'avatar_student': return Icons.school_rounded;
      case 'avatar_book': return Icons.menu_book_rounded;
      case 'avatar_beacon': return Icons.wb_sunny_rounded;
      case 'avatar_star': return Icons.star_rounded;
      case 'avatar_shield': return Icons.verified_user_rounded;
      case 'avatar_light': return Icons.tips_and_updates_rounded;
      default: return Icons.person_rounded;
    }
  }

  Color _getAvatarColor(String avatarId) {
    switch (avatarId) {
      case 'avatar_student': return const Color(0xFF2DD4BF);
      case 'avatar_book': return const Color(0xFFF59E0B);
      case 'avatar_beacon': return const Color(0xFFEC4899);
      case 'avatar_star': return const Color(0xFF3B82F6);
      case 'avatar_shield': return const Color(0xFF10B981);
      case 'avatar_light': return const Color(0xFF8B5CF6);
      default: return const Color(0xFF94A3B8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
      stream: _firebaseService.streamDuelRoom(widget.roomId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _localQuestionIndex == 0) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFFFFF), // Clean Neutral White
            body: Center(child: CircularProgressIndicator(color: Color(0xFF00AFA3))),
          );
        }

        if (!snapshot.hasData || !snapshot.data.exists) {
          return Scaffold(
            backgroundColor: const Color(0xFFFFFFFF),
            body: Center(
              child: Text(
                'انتهى التحدي أو تم إلغاء الغرفة.',
                style: GoogleFonts.cairo(color: const Color(0xFF00AFA3), fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        final data = snapshot.data.data() as Map<String, dynamic>;
        final String status = data['status'] ?? 'waiting';
        final int firestoreQuestionIndex = data['currentQuestionIndex'] ?? 0;
        final String creatorUid = data['creatorUid'] ?? '';
        final String joinerUid = data['joinerUid'] ?? '';

        final String creatorName = data['creatorName'] ?? 'لاعب 1';
        final String joinerName = data['joinerName'] ?? 'لاعب 2';
        final String creatorAvatar = data['creatorAvatar'] ?? 'avatar_student';
        final String joinerAvatar = data['joinerAvatar'] ?? 'avatar_student';

        final Map<dynamic, dynamic> scores = data['scores'] ?? {};
        final int creatorScore = scores[creatorUid] ?? 0;
        final int joinerScore = scores[joinerUid] ?? 0;

        final Map<dynamic, dynamic> answers = data['answers'] ?? {};
        final Map<dynamic, dynamic> creatorAnswers = answers[creatorUid] ?? {};
        final Map<dynamic, dynamic> joinerAnswers = answers[joinerUid] ?? {};

        final List<dynamic> questionsRaw = data['questions'] ?? [];
        final List<Question> questions = questionsRaw.map((q) => Question.fromJson(Map<String, dynamic>.from(q))).toList();

        // 1. Check if game is finished
        if (status == 'finished') {
          final String winnerUid = data['winnerUid'] ?? 'draw';
          return _buildFinishedScreen(
            winnerUid: winnerUid,
            creatorUid: creatorUid,
            joinerUid: joinerUid,
            creatorName: creatorName,
            joinerName: joinerName,
            creatorAvatar: creatorAvatar,
            joinerAvatar: joinerAvatar,
            creatorScore: creatorScore,
            joinerScore: joinerScore,
          );
        }

        // 2. React to question advancement from Firestore
        if (firestoreQuestionIndex != _localQuestionIndex) {
          _localQuestionIndex = firestoreQuestionIndex;
          _isAnswered = false;
          _isAdvancing = false;
          
          // Re-calculate dynamic timer length
          final nextQ = questions[_localQuestionIndex];
          int duration = 30;
          if (nextQ.verseOrHadithText != null && nextQ.verseOrHadithText!.length > 40) {
            duration = 45;
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _startLocalTimer(duration);
          });
        }

        final currentQuestion = questions[_localQuestionIndex];
        final String currentQId = currentQuestion.id;

        // Check if players have locked answers
        final bool creatorHasAnswered = creatorAnswers.containsKey(currentQId);
        final bool joinerHasAnswered = joinerAnswers.containsKey(currentQId);

        final bool bothAnswered = creatorHasAnswered && joinerHasAnswered;

        // 3. Advancing Room Index (only Creator triggers Firestore update to prevent racing)
        if (bothAnswered && widget.isCreator && !_isAdvancing) {
          _isAdvancing = true;
          Future.delayed(const Duration(seconds: 3), () async {
            if (_localQuestionIndex < 4) {
              await _firebaseService.advanceDuelQuestion(widget.roomId, _localQuestionIndex + 1);
            } else {
              // End Duel
              String winner = 'draw';
              if (creatorScore > joinerScore) {
                winner = creatorUid;
              } else if (joinerScore > creatorScore) {
                winner = joinerUid;
              }
              await _firebaseService.endDuel(
                roomId: widget.roomId,
                winnerUid: winner,
                creatorUid: creatorUid,
                joinerUid: joinerUid,
                creatorScore: creatorScore,
                joinerScore: joinerScore,
              );
            }
          });
        }

        // Check user's specific state
        final myUid = _firebaseService.currentUser?.uid ?? '';
        final bool hasIAnswered = myUid == creatorUid ? creatorHasAnswered : joinerHasAnswered;
        final bool hasOpponentAnswered = myUid == creatorUid ? joinerHasAnswered : creatorHasAnswered;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC), // Cool Slate White
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFFEF4444)),
              onPressed: () {
                // Confirm exit
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    backgroundColor: Colors.white,
                    title: Text('إنهاء التحدي', style: GoogleFonts.cairo(color: const Color(0xFF00AFA3), fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                    content: Text('هل أنت متأكد من رغبتك في الانسحاب؟ سيتم احتساب النتيجة الحالية.', style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 14.5), textAlign: TextAlign.right),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dialogCtx), child: Text('إلغاء', style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontWeight: FontWeight.bold))),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(dialogCtx);
                          // Set opponent as winner
                          final oppUid = myUid == creatorUid ? joinerUid : creatorUid;
                          await _firebaseService.endDuel(
                            roomId: widget.roomId,
                            winnerUid: oppUid,
                            creatorUid: creatorUid,
                            joinerUid: joinerUid,
                            creatorScore: creatorScore,
                            joinerScore: joinerScore,
                          );
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: Text('انسحاب', style: GoogleFonts.cairo(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
            title: Text(
              'جولة ${firestoreQuestionIndex + 1} من 5',
              style: GoogleFonts.cairo(color: const Color(0xFF0F172A), fontSize: 18.0, fontWeight: FontWeight.bold), // Navy round title
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Real-time Scoreboard Header
                  _buildRealtimeScoreboard(
                    creatorName: creatorName,
                    joinerName: joinerName,
                    creatorAvatar: creatorAvatar,
                    joinerAvatar: joinerAvatar,
                    creatorScore: creatorScore,
                    joinerScore: joinerScore,
                    creatorHasAnswered: creatorHasAnswered,
                    joinerHasAnswered: joinerHasAnswered,
                    creatorUid: creatorUid,
                    joinerUid: joinerUid,
                  ),
                  const SizedBox(height: 20.0),

                  // Timer Bar
                  _buildTimerBar(),
                  const SizedBox(height: 20.0),

                  // Scrollable Question Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Context Card (Quran verse or Hadith text)
                          if (currentQuestion.verseOrHadithText != null) ...[
                            _buildContextCard(currentQuestion.verseOrHadithText!),
                            const SizedBox(height: 16.0),
                          ],

                          // Question Text - Rich Navy
                          Text(
                            currentQuestion.question,
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF0F172A), // Rich Navy
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              height: 1.6, // Clear line spacing
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 20.0),

                          // Options
                          ...List.generate(
                            currentQuestion.options.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: _buildOnlineOptionButton(currentQuestion, index, myUid, creatorUid, creatorAnswers, joinerAnswers),
                            ),
                          ),
                          const SizedBox(height: 20.0),

                          // Status text waiting for opponent
                          if (hasIAnswered && !hasOpponentAnswered)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00AFA3).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(100.0),
                                ),
                                child: Text(
                                  'إجابة ممتازة! بانتظار قفل إجابة منافسك...',
                                  style: GoogleFonts.cairo(color: const Color(0xFF00AFA3), fontSize: 12.5, fontWeight: FontWeight.bold),
                                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms, color: Colors.white),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRealtimeScoreboard({
    required String creatorName,
    required String joinerName,
    required String creatorAvatar,
    required String joinerAvatar,
    required int creatorScore,
    required int joinerScore,
    required bool creatorHasAnswered,
    required bool joinerHasAnswered,
    required String creatorUid,
    required String joinerUid,
  }) {
    final String myUid = _firebaseService.currentUser?.uid ?? '';
    final bool amICreator = myUid == creatorUid;

    final String myName = amICreator ? creatorName : joinerName;
    final String myAvatar = amICreator ? creatorAvatar : joinerAvatar;
    final int myScore = amICreator ? creatorScore : joinerScore;
    final bool haveIAnswered = amICreator ? creatorHasAnswered : joinerHasAnswered;

    final String oppName = amICreator ? joinerName : creatorName;
    final String oppAvatar = amICreator ? joinerAvatar : creatorAvatar;
    final int oppScore = amICreator ? joinerScore : creatorScore;
    final bool hasOppAnswered = amICreator ? joinerHasAnswered : creatorHasAnswered;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // My Profile Card
          _buildScoreCardItem(
            name: myName,
            avatar: myAvatar,
            score: myScore,
            hasAnswered: haveIAnswered,
            color: const Color(0xFF2DD4BF),
          ),

          // VS Divider
          Column(
            children: [
              Text(
                'VS',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF00AFA3), // Soft Electric Teal
                  fontWeight: FontWeight.w900,
                  fontSize: 18.0,
                ),
              ),
              const SizedBox(height: 2.0),
              Container(
                width: 16.0,
                height: 2.0,
                color: const Color(0xFF00AFA3),
              ),
            ],
          ),

          // Opponent Profile Card
          _buildScoreCardItem(
            name: oppName,
            avatar: oppAvatar,
            score: oppScore,
            hasAnswered: hasOppAnswered,
            color: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCardItem({
    required String name,
    required String avatar,
    required int score,
    required bool hasAnswered,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (color == const Color(0xFFEF4444)) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.cairo(color: const Color(0xFF0F172A), fontSize: 13.0, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$score نقطة',
                  style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 12.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(width: 10.0),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: _getAvatarColor(avatar).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: _getAvatarColor(avatar), width: 1.5),
                  ),
                  child: Icon(_getAvatarIcon(avatar), color: _getAvatarColor(avatar), size: 20.0),
                ),
                if (hasAnswered)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 10.0),
                    ),
                  ),
              ],
            ),
          ] else ...[
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: _getAvatarColor(avatar).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: _getAvatarColor(avatar), width: 1.5),
                  ),
                  child: Icon(_getAvatarIcon(avatar), color: _getAvatarColor(avatar), size: 20.0),
                ),
                if (hasAnswered)
                  Positioned(
                    bottom: -2,
                    left: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2.0),
                      decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      child: const Icon(Icons.check, color: Colors.white, size: 10.0),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  name,
                  style: GoogleFonts.cairo(color: const Color(0xFF0F172A), fontSize: 13.0, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$score نقطة',
                  style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 12.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    final double percent = _totalTimeForQuestion > 0 ? _timeLeft / _totalTimeForQuestion : 0.0;
    final color = percent > 0.5
        ? const Color(0xFF00AFA3) // Soft Electric Teal
        : percent > 0.25
            ? const Color(0xFF2563EB) // Sapphire
            : const Color(0xFFDC2626); // Red

    return Container(
      height: 6.0,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerRight,
        widthFactor: percent,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  Widget _buildContextCard(String text) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 125.0),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Keep Light Gold Tint for scriptures
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AFA3).withOpacity(0.03),
            blurRadius: 8.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Text(
            text,
            style: GoogleFonts.amiri(
              color: const Color(0xFF92400E),
              fontSize: 17.0,
              fontWeight: FontWeight.bold,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildOnlineOptionButton(
    Question question,
    int index,
    String myUid,
    String creatorUid,
    Map<dynamic, dynamic> creatorAnswers,
    Map<dynamic, dynamic> joinerAnswers,
  ) {
    final optionText = question.options[index];
    final String currentQId = question.id;

    // Check answers of both players for display
    final bool creatorHasAnswered = creatorAnswers.containsKey(currentQId);
    final bool joinerHasAnswered = joinerAnswers.containsKey(currentQId);
    final bool bothAnswered = creatorHasAnswered && joinerHasAnswered;

    final myAnswers = myUid == creatorUid ? creatorAnswers : joinerAnswers;
    final bool haveIAnswered = myAnswers.containsKey(currentQId);
    final int? mySelection = myAnswers[currentQId] as int?;

    Color buttonBgColor = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0);
    Color textColor = const Color(0xFF0F172A);

    if (haveIAnswered) {
      final isSelected = mySelection == index;
      final isCorrectOption = index == question.correctAnswerIndex;

      if (bothAnswered) {
        // Show correct answers to both after round completes
        if (isCorrectOption) {
          buttonBgColor = const Color(0xFFD1FAE5); // Emerald Green
          borderColor = const Color(0xFF10B981);
          textColor = const Color(0xFF065F46);
        } else if (isSelected) {
          buttonBgColor = const Color(0xFFFEE2E2); // Red
          borderColor = const Color(0xFFEF4444);
          textColor = const Color(0xFF7F1D1D);
        } else {
          buttonBgColor = const Color(0xFFFAF9F6);
          borderColor = const Color(0xFFE2E8F0);
          textColor = const Color(0xFF94A3B8);
        }
      } else {
        // Show selected state only for this player
        if (isSelected) {
          buttonBgColor = const Color(0xFF00AFA3).withOpacity(0.08);
          borderColor = const Color(0xFF00AFA3);
          textColor = const Color(0xFF00AFA3);
        } else {
          buttonBgColor = const Color(0xFFFAF9F6);
          borderColor = const Color(0xFFE2E8F0);
          textColor = const Color(0xFF94A3B8);
        }
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: buttonBgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 8.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          onTap: haveIAnswered
              ? null
              : () => _handleAnswerSelection(index, index == question.correctAnswerIndex, question),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    optionText,
                    style: GoogleFonts.cairo(
                      color: textColor,
                      fontSize: 15.0,
                      fontWeight: haveIAnswered && (mySelection == index || (bothAnswered && index == question.correctAnswerIndex))
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedScreen({
    required String winnerUid,
    required String creatorUid,
    required String joinerUid,
    required String creatorName,
    required String joinerName,
    required String creatorAvatar,
    required String joinerAvatar,
    required int creatorScore,
    required int joinerScore,
  }) {
    // Determine winner details
    final String myUid = _firebaseService.currentUser?.uid ?? '';
    final bool amIWinner = winnerUid == myUid;
    final bool isDraw = winnerUid == 'draw';

    final String winnerName = winnerUid == creatorUid ? creatorName : joinerName;

    // Seeding trigger to save stats in Firestore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firebaseService.endDuel(
        roomId: widget.roomId,
        winnerUid: winnerUid,
        creatorUid: creatorUid,
        joinerUid: joinerUid,
        creatorScore: creatorScore,
        joinerScore: joinerScore,
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Clean Neutral White
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Trophy / Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: isDraw ? const Color(0xFF00AFA3).withOpacity(0.08) : const Color(0xFF2563EB).withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDraw ? const Color(0xFF00AFA3) : const Color(0xFF2563EB), width: 2.0),
                    ),
                    child: Icon(
                      isDraw ? Icons.handshake_rounded : Icons.emoji_events_rounded,
                      color: isDraw ? const Color(0xFF00AFA3) : const Color(0xFF2563EB),
                      size: 70.0,
                    ),
                  ),
                ).animate().scale(duration: 400.ms),
                const SizedBox(height: 24.0),

                // Winner Title
                Text(
                  isDraw
                      ? 'انتهى التحدي بالتعادل!'
                      : (amIWinner ? 'تهانينا! لقد فزت بالتحدي 🎉' : 'حظاً أوفر في المرة القادمة!'),
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF00AFA3), // Soft Electric Teal
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                if (!isDraw) ...[
                  const SizedBox(height: 10.0),
                  Text(
                    'بطل هذه المبارزة هو $winnerName',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF64748B),
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 30.0),

                // Score Details Card
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00AFA3).withOpacity(0.01),
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'النتائج النهائية للمبارزة',
                        style: GoogleFonts.cairo(color: const Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 15.0), // Sapphire
                      ),
                      const SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Creator Score
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(color: _getAvatarColor(creatorAvatar).withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(_getAvatarIcon(creatorAvatar), color: _getAvatarColor(creatorAvatar), size: 24.0),
                              ),
                              const SizedBox(height: 6.0),
                              Text(creatorName, style: GoogleFonts.cairo(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13.0)),
                              Text('$creatorScore نقطة', style: GoogleFonts.outfit(color: const Color(0xFF00AFA3), fontWeight: FontWeight.w900, fontSize: 16.0)),
                            ],
                          ),
                          
                          // Versus line
                          Text('ضد', style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),

                          // Joiner Score
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10.0),
                                decoration: BoxDecoration(color: _getAvatarColor(joinerAvatar).withOpacity(0.1), shape: BoxShape.circle),
                                child: Icon(_getAvatarIcon(joinerAvatar), color: _getAvatarColor(joinerAvatar), size: 24.0),
                              ),
                              const SizedBox(height: 6.0),
                              Text(joinerName, style: GoogleFonts.cairo(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13.0)),
                              Text('$joinerScore نقطة', style: GoogleFonts.outfit(color: const Color(0xFF00AFA3), fontWeight: FontWeight.w900, fontSize: 16.0)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40.0),

                // Exit Button
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AFA3), // Soft Electric Teal
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    elevation: 0,
                  ),
                  child: Text(
                    'العودة للرئيسية',
                    style: GoogleFonts.cairo(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
