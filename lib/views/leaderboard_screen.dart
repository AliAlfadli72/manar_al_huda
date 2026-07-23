import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/quiz_provider.dart';
import '../services/firebase_service.dart';
import '../models/scholar_rank.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _activeTab = 'leaderboard'; // 'leaderboard' or 'achievements'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = _auth.currentUser;
      if (user != null) {
        final quizProvider = Provider.of<QuizProvider>(context, listen: false);
        FirebaseService().syncLocalStats(
          points: quizProvider.totalPoints,
          streak: quizProvider.streakCount,
        );
      }
    });
  }

  IconData _getAvatarIcon(String avatarId) {
    switch (avatarId) {
      case 'avatar_student':
        return Icons.school_rounded; // طالب العلم
      case 'avatar_book':
        return Icons.auto_stories_rounded; // القارئ
      case 'avatar_beacon':
        return Icons.explore_rounded; // المنارة
      case 'avatar_star':
        return Icons.workspace_premium_rounded; // النجم
      case 'avatar_shield':
        return Icons.shield_rounded; // الحامي
      case 'avatar_light':
        return Icons.lightbulb_rounded; // نور العلم
      default:
        return Icons.person_rounded;
    }
  }

  Color _getAvatarColor(String avatarId) {
    switch (avatarId) {
      case 'avatar_student':
        return const Color(0xFF00AFA3); // Soft Electric Teal
      case 'avatar_book':
        return const Color(0xFFD97706); // Amber Gold
      case 'avatar_beacon':
        return const Color(0xFF8B5CF6); // Purple
      case 'avatar_star':
        return const Color(0xFF2563EB); // Sapphire
      case 'avatar_shield':
        return const Color(0xFF10B981); // Emerald
      case 'avatar_light':
        return const Color(0xFFEC4899); // Pink
      default:
        return const Color(0xFF94A3B8); // Slate
    }
  }

  Future<int> _getUserRank(int myPoints) async {
    if (myPoints <= 0) return 0;
    try {
      final aggregateQuery = _firestore
          .collection('users')
          .where('points', isGreaterThan: myPoints);
      final countSnapshot = await aggregateQuery.count().get();
      return (countSnapshot.count ?? 0) + 1;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Modern neutral slate
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00AFA3)),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              )
            : null,
        title: Text(
          'قائمة الشرف والمتميزين',
          style: GoogleFonts.cairo(
            color: const Color(0xFF0F172A),
            fontSize: 19.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Custom Tab Bar Switcher
          _buildTabSwitcher(),
          
          Expanded(
            child: _activeTab == 'leaderboard'
                ? _buildLeaderboardTab(currentUser)
                : _buildAchievementsTab(currentUser),
          ),
        ],
      ),
    );
  }

  // 1. Sliding custom Tab Bar Switcher
  Widget _buildTabSwitcher() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Container(
        height: 46.0,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _activeTab = 'achievements';
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _activeTab == 'achievements' ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: _activeTab == 'achievements'
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.05),
                              blurRadius: 6.0,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        color: _activeTab == 'achievements' ? const Color(0xFF00AFA3) : const Color(0xFF64748B),
                        size: 18.0,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        'معرض الأوسمة',
                        style: GoogleFonts.cairo(
                          color: _activeTab == 'achievements' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _activeTab = 'leaderboard';
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4.0),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _activeTab == 'leaderboard' ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: _activeTab == 'leaderboard'
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.05),
                              blurRadius: 6.0,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        color: _activeTab == 'leaderboard' ? const Color(0xFF00AFA3) : const Color(0xFF64748B),
                        size: 18.0,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        'لوحة المتصدرين',
                        style: GoogleFonts.cairo(
                          color: _activeTab == 'leaderboard' ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Leaderboard Tab Content View
  Widget _buildLeaderboardTab(User? currentUser) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .orderBy('points', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00AFA3)));
        }

        final docs = snapshot.data?.docs ?? [];
        final List<Map<String, dynamic>> usersList = docs.map((doc) => doc.data()).toList();

        // Inject mock users if list is empty to make it look premium
        if (usersList.length < 5) {
          final List<Map<String, dynamic>> mockUsers = [
            {'name': 'عبد الرحمن خالد', 'avatar': 'avatar_student', 'points': 450, 'wins': 12, 'losses': 3, 'streak': 5, 'uid': 'mock1'},
            {'name': 'سارة أحمد', 'avatar': 'avatar_shield', 'points': 380, 'wins': 9, 'losses': 2, 'streak': 4, 'uid': 'mock2'},
            {'name': 'عمر الفاروق', 'avatar': 'avatar_star', 'points': 310, 'wins': 7, 'losses': 4, 'streak': 3, 'uid': 'mock3'},
            {'name': 'مريم أمين', 'avatar': 'avatar_beacon', 'points': 250, 'wins': 5, 'losses': 2, 'streak': 2, 'uid': 'mock4'},
            {'name': 'أنس بن مالك', 'avatar': 'avatar_book', 'points': 180, 'wins': 3, 'losses': 1, 'streak': 2, 'uid': 'mock5'},
          ];

          for (var mock in mockUsers) {
            final exists = usersList.any((u) => u['uid'] == mock['uid'] || u['name'] == mock['name']);
            if (!exists && usersList.length < 10) {
              usersList.add(mock);
            }
          }
          usersList.sort((a, b) => (b['points'] as int? ?? 0).compareTo(a['points'] as int? ?? 0));
        }

        // Split into Top 3 and the Rest
        final Map<String, dynamic>? firstPlace = usersList.isNotEmpty ? usersList[0] : null;
        final Map<String, dynamic>? secondPlace = usersList.length > 1 ? usersList[1] : null;
        final Map<String, dynamic>? thirdPlace = usersList.length > 2 ? usersList[2] : null;

        final List<Map<String, dynamic>> restList = usersList.length > 3 ? usersList.sublist(3) : [];

        // Check if current user is in top 20
        bool isCurrentUserInTop20 = false;
        int currentUserPoints = 0;
        String currentUserAvatar = 'avatar_student';
        String currentUserName = '';

        for (int i = 0; i < usersList.length; i++) {
          if (usersList[i]['uid'] == currentUser?.uid) {
            isCurrentUserInTop20 = true;
            break;
          }
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: currentUser != null
              ? _firestore.collection('users').doc(currentUser.uid).snapshots()
              : const Stream.empty(),
          builder: (context, userProfileSnapshot) {
            if (userProfileSnapshot.hasData && userProfileSnapshot.data!.exists) {
              final uData = userProfileSnapshot.data!.data()!;
              currentUserPoints = uData['points'] ?? 0;
              currentUserAvatar = uData['avatar'] ?? 'avatar_student';
              currentUserName = uData['name'] ?? '';
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 3D Podium for Top 3
                        if (firstPlace != null) ...[
                          _build3DPodium(firstPlace, secondPlace, thirdPlace),
                          const SizedBox(height: 25.0),
                        ],

                        // Rest List
                        if (restList.isNotEmpty) ...[
                          Text(
                            'المنافسون المتميزون',
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF00AFA3),
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          const SizedBox(height: 10.0),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: restList.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8.0),
                            itemBuilder: (context, index) {
                              final user = restList[index];
                              final rank = index + 4;
                              final isMe = user['uid'] == currentUser?.uid;

                              return _buildLeaderboardRow(
                                rank: rank,
                                user: user,
                                isMe: isMe,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Sticky User Rank Bar (if outside top 20)
                if (currentUser != null && !isCurrentUserInTop20 && currentUserPoints > 0)
                  FutureBuilder<int>(
                    future: _getUserRank(currentUserPoints),
                    builder: (context, rankSnapshot) {
                      final myRank = rankSnapshot.data ?? 0;
                      if (myRank == 0) return const SizedBox();

                      return _buildStickyUserRankBar(
                        rank: myRank,
                        name: currentUserName,
                        avatarId: currentUserAvatar,
                        points: currentUserPoints,
                      );
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // 3. Achievements Tab Content View
  Widget _buildAchievementsTab(User? currentUser) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: currentUser != null
          ? _firestore.collection('users').doc(currentUser.uid).snapshots()
          : const Stream.empty(),
      builder: (context, profileSnapshot) {
        int points = 0;
        int wins = 0;
        int streak = 0;

        if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
          final uData = profileSnapshot.data!.data()!;
          points = uData['points'] ?? 0;
          wins = uData['wins'] ?? 0;
          streak = uData['streak'] ?? 0;
        } else {
          // Fallback to provider stats if offline/no profile loaded
          final quizProvider = Provider.of<QuizProvider>(context, listen: false);
          points = quizProvider.totalPoints;
          streak = quizProvider.streakCount;
        }

        final badges = _getPlayerBadgesList(points, wins, streak);

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          itemCount: badges.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14.0,
            mainAxisSpacing: 14.0,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final badge = badges[index];
            return _buildAchievementCard(badge);
          },
        );
      },
    );
  }

  // Build Single Achievement Grid Card
  Widget _buildAchievementCard(PlayerBadgeModel badge) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: badge.isUnlocked ? badge.color.withOpacity(0.3) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.015),
            blurRadius: 8.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _showBadgeDetailsDialog(badge);
          },
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon Container
                Align(
                  alignment: Alignment.centerRight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: badge.isUnlocked ? badge.color.withOpacity(0.12) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          badge.icon,
                          color: badge.isUnlocked ? badge.color : const Color(0xFF94A3B8),
                          size: 22.0,
                        ),
                      ),
                      if (!badge.isUnlocked)
                        const Positioned(
                          bottom: 0,
                          left: 0,
                          child: Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 12.0),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12.0),

                // Badge Name
                Text(
                  badge.title,
                  style: GoogleFonts.cairo(
                    color: badge.isUnlocked ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    fontSize: 13.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),

                // Description
                Expanded(
                  child: Text(
                    badge.description,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF64748B),
                      fontSize: 10.5,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10.0),

                // Progress Indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: LinearProgressIndicator(
                        value: badge.progress,
                        minHeight: 4.0,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          badge.isUnlocked ? badge.color : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      badge.progressLabel,
                      style: GoogleFonts.cairo(
                        color: badge.isUnlocked ? badge.color : const Color(0xFF94A3B8),
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 3D Game-Style Podium stands
  Widget _build3DPodium(
    Map<String, dynamic> first,
    Map<String, dynamic>? second,
    Map<String, dynamic>? third,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AFA3).withOpacity(0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place (Left)
              if (second != null)
                _buildPodiumBlock(
                  user: second,
                  rank: 2,
                  blockHeight: 85.0,
                  avatarSize: 55.0,
                  colors: [const Color(0xFFCBD5E1), const Color(0xFF94A3B8)], // Silver
                  badgeIcon: Icons.stars_rounded,
                  badgeColor: const Color(0xFF475569),
                ).animate().slideY(begin: 0.25, end: 0, duration: 450.ms),

              // 1st Place (Center)
              _buildPodiumBlock(
                user: first,
                rank: 1,
                blockHeight: 115.0,
                avatarSize: 72.0,
                colors: [const Color(0xFFFBBF24), const Color(0xFFD97706)], // Gold
                badgeIcon: Icons.workspace_premium_rounded,
                badgeColor: const Color(0xFFB45309),
              ).animate().scale(duration: 400.ms).slideY(begin: 0.15, end: 0, duration: 400.ms),

              // 3rd Place (Right)
              if (third != null)
                _buildPodiumBlock(
                  user: third,
                  rank: 3,
                  blockHeight: 65.0,
                  avatarSize: 50.0,
                  colors: [const Color(0xFFFDBA74), const Color(0xFFC2410C)], // Bronze
                  badgeIcon: Icons.military_tech_rounded,
                  badgeColor: const Color(0xFF7C2D12),
                ).animate().slideY(begin: 0.3, end: 0, duration: 500.ms),
            ],
          ),
        ],
      ),
    );
  }

  // Helper to build a single podium block stand
  Widget _buildPodiumBlock({
    required Map<String, dynamic> user,
    required int rank,
    required double blockHeight,
    required double avatarSize,
    required List<Color> colors,
    required IconData badgeIcon,
    required Color badgeColor,
  }) {
    final String name = user['name'] ?? '';
    final int points = user['points'] ?? 0;
    final String avatarId = user['avatar'] ?? 'avatar_student';
    final Color avatarColor = _getAvatarColor(avatarId);

    return GestureDetector(
      onTap: () => _showPlayerProfileDialog(user),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with Trophy/Crown sits on top
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Avatar Circle
              Container(
                padding: EdgeInsets.all(rank == 1 ? 8.0 : 6.0),
                decoration: BoxDecoration(
                  color: avatarColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colors[1],
                    width: rank == 1 ? 2.5 : 1.5,
                  ),
                ),
                child: Icon(
                  _getAvatarIcon(avatarId),
                  color: avatarColor,
                  size: avatarSize * 0.5,
                ),
              ),

              // Gold crown/wreath emblem on top of 1st place
              if (rank == 1)
                Positioned(
                  top: -14.0,
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFF59E0B),
                    size: 22.0,
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1800.ms),
                ),

              // Small rank badge at the bottom of the avatar circle
              Positioned(
                bottom: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.0),
                  ),
                  child: Icon(badgeIcon, color: Colors.white, size: 10.0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Podium column stand
          Container(
            width: 85.0,
            height: blockHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors[1].withOpacity(0.2),
                  blurRadius: 8.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Large Rank Number
                Text(
                  rank.toString(),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: rank == 1 ? 28.0 : 22.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Points
                Text(
                  '$points ن',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: rank == 1 ? 11.5 : 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6.0),

          // Name pill under stand
          SizedBox(
            width: 85.0,
            child: Text(
              name,
              style: GoogleFonts.cairo(
                color: const Color(0xFF0F172A),
                fontSize: rank == 1 ? 12.0 : 11.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Redesigned Leaderboard Row
  Widget _buildLeaderboardRow({
    required int rank,
    required Map<String, dynamic> user,
    required bool isMe,
  }) {
    final String name = user['name'] ?? '';
    final String avatarId = user['avatar'] ?? 'avatar_student';
    final int points = user['points'] ?? 0;
    final Color avatarColor = _getAvatarColor(avatarId);

    return GestureDetector(
      onTap: () => _showPlayerProfileDialog(user),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF00AFA3).withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(
            color: isMe ? const Color(0xFF00AFA3) : const Color(0xFFE2E8F0),
            width: isMe ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.015),
              blurRadius: 8.0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Score Points capsule
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF00AFA3).withOpacity(0.12) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Text(
                '$points ن',
                style: GoogleFonts.outfit(
                  color: isMe ? const Color(0xFF00AFA3) : const Color(0xFF0F172A),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Spacer(),

            // Name + Rank title
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF0F172A),
                      fontSize: 13.0,
                      fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    ScholarRank.getRank(points).title,
                    style: GoogleFonts.cairo(
                      color: ScholarRank.getRank(points).color,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),

            // Avatar circle
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getAvatarIcon(avatarId),
                color: avatarColor,
                size: 18.0,
              ),
            ),
            const SizedBox(width: 12.0),

            // Hexagon Rank badge container
            _buildRankHexagon(rank),
          ],
        ),
      ),
    );
  }

  // Hexagon styled Rank indicator
  Widget _buildRankHexagon(int rank) {
    Color bg = const Color(0xFFF1F5F9);
    Color textCol = const Color(0xFF64748B);

    if (rank == 1) {
      bg = const Color(0xFFFEF3C7); // Light gold
      textCol = const Color(0xFFD97706);
    } else if (rank == 2) {
      bg = const Color(0xFFF1F5F9); // Light silver
      textCol = const Color(0xFF475569);
    } else if (rank == 3) {
      bg = const Color(0xFFFEE2E2); // Light bronze
      textCol = const Color(0xFF991B1B);
    }

    return Container(
      width: 26.0,
      height: 26.0,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: textCol.withOpacity(0.3), width: 1.0),
      ),
      alignment: Alignment.center,
      child: Text(
        rank.toString(),
        style: GoogleFonts.outfit(
          color: textCol,
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Sticky User Rank Bar
  Widget _buildStickyUserRankBar({
    required int rank,
    required String name,
    required String avatarId,
    required int points,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF00AFA3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AFA3).withOpacity(0.12),
            blurRadius: 10.0,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Points
            Text(
              '$points ن',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),

            // Message text
            Text(
              'ترتيبك الحالي في لوحة الشرف',
              style: GoogleFonts.cairo(
                color: Colors.white.withOpacity(0.85),
                fontSize: 11.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12.0),

            // User Name
            Text(
              name,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.all(5.0),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getAvatarIcon(avatarId),
                color: Colors.white,
                size: 14.0,
              ),
            ),
            const SizedBox(width: 12.0),

            // Rank Badge
            Text(
              '#$rank',
              style: GoogleFonts.outfit(
                color: const Color(0xFFCCFBF1),
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1.0, end: 0, duration: 300.ms);
  }

  // Interactive Player Profile Sheet (Redesigned with Win Rate circular gauge)
  void _showPlayerProfileDialog(Map<String, dynamic> user) {
    final String name = user['name'] ?? '';
    final String avatarId = user['avatar'] ?? 'avatar_student';
    final int points = user['points'] ?? 0;
    final int wins = user['wins'] ?? 0;
    final int losses = user['losses'] ?? 0;
    final int streak = user['streak'] ?? 0;

    final Color avatarColor = _getAvatarColor(avatarId);
    final badges = _getPlayerBadgesList(points, wins, streak);

    // Calculate Win Rate Ratio
    final double winRate = (wins + losses) > 0 ? wins / (wins + losses) : 0.0;
    final int winRatePercent = (winRate * 100).toInt();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.0),
          topRight: Radius.circular(28.0),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Drag Handle
                Center(
                  child: Container(
                    width: 40.0,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),

                // Title bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'بطاقة تفاصيل اللاعب',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF00AFA3),
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48.0), // spacer to balance close button
                  ],
                ),
                const SizedBox(height: 10.0),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // Large Avatar Circle
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: avatarColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                            border: Border.all(color: avatarColor, width: 2.5),
                          ),
                          child: Icon(
                            _getAvatarIcon(avatarId),
                            color: avatarColor,
                            size: 46.0,
                          ),
                        ),
                        const SizedBox(height: 10.0),

                        // Player Name
                        Text(
                          name,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF0F172A),
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        // Rank Pill & Progress
                        const SizedBox(height: 6.0),
                        Builder(
                          builder: (context) {
                            final rank = ScholarRank.getRank(points);
                            final progress = ScholarRank.getProgressToNext(points, rank);
                            final progressLabel = ScholarRank.getProgressLabel(points, rank);

                            return Column(
                              children: [
                                // Rank Tag
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: rank.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(100.0),
                                    border: Border.all(color: rank.color, width: 1.0),
                                  ),
                                  child: Text(
                                    '${rank.icon} ${rank.title}',
                                    style: GoogleFonts.cairo(
                                      color: rank.color,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10.0),

                                // Progress to next rank
                                if (ScholarRank.getNextRank(rank) != null) ...[
                                  SizedBox(
                                    width: 200.0,
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10.0),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            minHeight: 5.5,
                                            backgroundColor: const Color(0xFFE2E8F0),
                                            valueColor: AlwaysStoppedAnimation<Color>(rank.color),
                                          ),
                                        ),
                                        const SizedBox(height: 5.0),
                                        Text(
                                          progressLabel,
                                          style: GoogleFonts.cairo(
                                            color: const Color(0xFF64748B),
                                            fontSize: 10.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24.0),

                        // Analytical Row (Win Rate circular indicator + mini description)
                        Container(
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'تحليل أداء المواجهات الثنائية',
                                      style: GoogleFonts.cairo(
                                        color: const Color(0xFF0F172A),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      'إجمالي المواجهات: ${wins + losses} جولات تنافسية في المبارزة الفورية مع لاعبي منار الهدى.',
                                      style: GoogleFonts.cairo(
                                        color: const Color(0xFF64748B),
                                        fontSize: 10.5,
                                        height: 1.4,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              
                              // Win Rate Circular progress
                              CircularPercentIndicator(
                                radius: 28.0,
                                lineWidth: 4.5,
                                percent: winRate,
                                center: Text(
                                  '$winRatePercent%',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF10B981),
                                  ),
                                ),
                                progressColor: const Color(0xFF10B981),
                                backgroundColor: const Color(0xFFE2E8F0),
                                circularStrokeCap: CircularStrokeCap.round,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14.0),

                        // Stats Bento Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 2.1,
                          crossAxisSpacing: 12.0,
                          mainAxisSpacing: 12.0,
                          children: [
                            _buildPlayerStatItem('النقاط التراكمية', '$points ن', Icons.star_rounded, const Color(0xFF2563EB)),
                            _buildPlayerStatItem('الانتصارات', '$wins فوز', Icons.flash_on_rounded, const Color(0xFF10B981)),
                            _buildPlayerStatItem('الخسارات', '$losses خسارة', Icons.heart_broken_rounded, const Color(0xFFEF4444)),
                            _buildPlayerStatItem('التتابع اليومي', '$streak يوم', Icons.local_fire_department_rounded, const Color(0xFFEC4899)),
                          ],
                        ),
                        const SizedBox(height: 25.0),

                        // Badges Title
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'أوسمة اللاعب المستحقة ✦',
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF0F172A),
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10.0),

                        // Achievements Grid inside Sheet
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: badges.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 12.0,
                            childAspectRatio: 0.85,
                          ),
                          itemBuilder: (context, index) {
                            final badge = badges[index];
                            return Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10.0),
                                      decoration: BoxDecoration(
                                        color: badge.isUnlocked
                                            ? badge.color.withOpacity(0.12)
                                            : const Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: badge.isUnlocked ? badge.color : const Color(0xFFE2E8F0),
                                          width: badge.isUnlocked ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Icon(
                                        badge.icon,
                                        color: badge.isUnlocked ? badge.color : const Color(0xFF94A3B8),
                                        size: 20.0,
                                      ),
                                    ),
                                    if (!badge.isUnlocked)
                                      const Positioned(
                                        bottom: -2,
                                        right: -2,
                                        child: Icon(Icons.lock_rounded, color: Color(0xFF64748B), size: 10.0),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  badge.title,
                                  style: GoogleFonts.cairo(
                                    color: badge.isUnlocked ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                                    fontSize: 9.5,
                                    fontWeight: badge.isUnlocked ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 15.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Bento stat card builder
  Widget _buildPlayerStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.015),
            blurRadius: 6.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.cairo(
                  color: const Color(0xFF64748B),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: GoogleFonts.cairo(
                  color: const Color(0xFF0F172A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Achievement details display dialog
  void _showBadgeDetailsDialog(PlayerBadgeModel badge) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8.0),
              // Large Badge Icon
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: badge.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: badge.color, width: 2.5),
                ),
                child: Icon(
                  badge.icon,
                  color: badge.color,
                  size: 38.0,
                ),
              ),
              const SizedBox(height: 16.0),

              // Title
              Text(
                badge.title,
                style: GoogleFonts.cairo(
                  fontSize: 17.0,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),

              // Description
              Text(
                badge.description,
                style: GoogleFonts.cairo(
                  fontSize: 13.0,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20.0),

              // Status indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: badge.isUnlocked ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      badge.isUnlocked ? 'الوسام مفعّل ومكتمل!' : 'الوسام مغلق حالياً',
                      style: GoogleFonts.cairo(
                        color: badge.isUnlocked ? const Color(0xFF065F46) : const Color(0xFF64748B),
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Icon(
                      badge.isUnlocked ? Icons.verified_rounded : Icons.lock_rounded,
                      color: badge.isUnlocked ? const Color(0xFF065F46) : const Color(0xFF64748B),
                      size: 16.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'أغلق',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF00AFA3),
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Create standard badges list
  List<PlayerBadgeModel> _getPlayerBadgesList(int points, int wins, int streak) {
    return [
      PlayerBadgeModel(
        title: 'وسام طلب العلم',
        description: 'البداية المباركة والرحلة في تحصيل العلوم الشرعية والعقدية بالمنارة.',
        icon: Icons.auto_stories_rounded,
        color: const Color(0xFF14B8A6),
        isUnlocked: true,
        progress: 1.0,
        progressLabel: 'مكتمل بنجاح 🎉',
      ),
      PlayerBadgeModel(
        title: 'فارس المواجهة',
        description: 'تحقيق أول فوز تاريخي في مبارزة المعرفة الفورية الثنائية أونلاين.',
        icon: Icons.flash_on_rounded,
        color: const Color(0xFFD97706),
        isUnlocked: wins >= 1,
        progress: wins >= 1 ? 1.0 : 0.0,
        progressLabel: 'الانتصارات: $wins / 1',
      ),
      PlayerBadgeModel(
        title: 'المبارز المغوار',
        description: 'إثبات الفصاحة والذكاء والفوز في 5 مبارزات ثنائية فورية أونلاين.',
        icon: Icons.military_tech_rounded,
        color: const Color(0xFFEC4899),
        isUnlocked: wins >= 5,
        progress: (wins / 5.0).clamp(0.0, 1.0),
        progressLabel: 'الانتصارات: $wins / 5',
      ),
      PlayerBadgeModel(
        title: 'المواظب العنيد',
        description: 'المحافظة على الحضور والتعلم لتتابع يومي لمدة 3 أيام متتالية.',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFEF4444),
        isUnlocked: streak >= 3,
        progress: (streak / 3.0).clamp(0.0, 1.0),
        progressLabel: 'أيام التتابع: $streak / 3',
      ),
      PlayerBadgeModel(
        title: 'المنارة الذهبية',
        description: 'المواظبة والاستمرارية في التتابع اليومي للتعلم لمدة 7 أيام متتالية.',
        icon: Icons.explore_rounded,
        color: const Color(0xFF8B5CF6),
        isUnlocked: streak >= 7,
        progress: (streak / 7.0).clamp(0.0, 1.0),
        progressLabel: 'أيام التتابع: $streak / 7',
      ),
      PlayerBadgeModel(
        title: 'قارئ النور',
        description: 'حيازة ما يزيد على 200 نقطة إجمالية من خلال الإجابة على الاختبارات.',
        icon: Icons.star_rounded,
        color: const Color(0xFF2563EB),
        isUnlocked: points >= 200,
        progress: (points / 200.0).clamp(0.0, 1.0),
        progressLabel: 'النقاط: $points / 200',
      ),
      PlayerBadgeModel(
        title: 'حامي العقيدة',
        description: 'حيازة 500 نقطة إجمالية وتثبيت المعارف الأساسية في الشريعة.',
        icon: Icons.shield_rounded,
        color: const Color(0xFF10B981),
        isUnlocked: points >= 500,
        progress: (points / 500.0).clamp(0.0, 1.0),
        progressLabel: 'النقاط: $points / 500',
      ),
      PlayerBadgeModel(
        title: 'المفكر الأكبر',
        description: 'بلوغ ذروة العلم بالمنارة وحيازة 1000 نقطة إجمالية في لوحة الشرف.',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFF59E0B),
        isUnlocked: points >= 1000,
        progress: (points / 1000.0).clamp(0.0, 1.0),
        progressLabel: 'النقاط: $points / 1000',
      ),
    ];
  }
}

class PlayerBadgeModel {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final double progress;
  final String progressLabel;

  PlayerBadgeModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.progress,
    required this.progressLabel,
  });
}
