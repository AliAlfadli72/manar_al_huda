import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/quiz_provider.dart';
import '../models/category.dart';
import '../models/question.dart';
import 'stage_complete_screen.dart';

class QuizPlayScreen extends StatefulWidget {
  final Category? category;
  final int? level;

  const QuizPlayScreen({
    super.key,
    this.category,
    this.level,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  bool _sheetShownForCurrentQuestion = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null && widget.level != null) {
      context.read<QuizProvider>().resetQuizStateSync();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<QuizProvider>().startQuiz(widget.category!, widget.level!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Clean Neutral White
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00AFA3)), // Chevron Back
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.category?.name ?? 'مراجعة الأخطاء',
          style: GoogleFonts.cairo(
            color: const Color(0xFF00AFA3), // Soft Electric Teal
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00AFA3)),
            );
          }

          if (provider.questions.isEmpty) {
            return Center(
              child: Text(
                'لم يتم العثور على أسئلة للمستوى الحالي.',
                style: GoogleFonts.cairo(color: const Color(0xFF0F172A), fontSize: 16.0),
              ),
            );
          }

          final question = provider.questions[provider.currentQuestionIndex];

          // Trigger explanation bottom sheet automatically when answered
          if (provider.isAnswered && !_sheetShownForCurrentQuestion) {
            _sheetShownForCurrentQuestion = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showExplanationSheet(context, provider, question);
            });
          } else if (!provider.isAnswered) {
            _sheetShownForCurrentQuestion = false;
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress indicator line
                  _buildProgressBar(provider),
                  const SizedBox(height: 20.0),

                  // Timer & Question Count Bento Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Question Count
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00AFA3).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: const Color(0xFF00AFA3).withOpacity(0.12), width: 1.0),
                        ),
                        child: Text(
                          'سؤال ${provider.currentQuestionIndex + 1} من ${provider.questions.length}',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF00AFA3),
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Circular Countdown Timer
                      _buildTimer(provider),
                    ],
                  ),
                  const SizedBox(height: 20.0),

                  // Scrollable Question Content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Text context (Quran verse/Hadith text)
                          if (question.verseOrHadithText != null) ...[
                            _buildContextCard(question.verseOrHadithText!),
                            const SizedBox(height: 16.0),
                          ],

                          // Question Text - Rich Navy with clear line spacing
                          Text(
                            question.question,
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF0F172A), // Rich Navy
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              height: 1.6, // Clear line spacing
                            ),
                            textAlign: TextAlign.right,
                          ).animate().fadeIn(duration: 300.ms),
                          const SizedBox(height: 18.0),

                          // Options List (Grouped closely)
                          ...List.generate(
                            question.options.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: _buildOptionButton(provider, question, index),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(QuizProvider provider) {
    final progress = provider.questions.isNotEmpty
        ? (provider.currentQuestionIndex) / provider.questions.length
        : 0.0;
    return Container(
      height: 6.0,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerRight, // RTL progress loading right to left
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF00AFA3), // Soft Electric Teal
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
    );
  }

  Widget _buildTimer(QuizProvider provider) {
    final double percent = provider.totalTimeForQuestion > 0
        ? provider.timeLeft / provider.totalTimeForQuestion
        : 0.0;

    final color = percent > 0.5
        ? const Color(0xFF00AFA3) // Soft Electric Teal
        : percent > 0.25
            ? const Color(0xFF2563EB) // Sapphire
            : const Color(0xFFEF4444); // Neon Red

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AFA3).withOpacity(0.15),
            blurRadius: 10.0,
            spreadRadius: 1.5,
          ),
        ],
      ),
      child: CircularPercentIndicator(
        radius: 25.0,
        lineWidth: 3.5,
        percent: percent,
        center: Text(
          '${provider.timeLeft}',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A), // Navy text for readability
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        progressColor: color,
        backgroundColor: const Color(0xFFE2E8F0),
        circularStrokeCap: CircularStrokeCap.round,
        animateFromLastPercent: true,
      ),
    );
  }

  Widget _buildContextCard(String text) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxHeight: 130.0, // Restrict maximum height to prevent pushing options off-screen
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: const Color(0xFF00AFA3).withOpacity(0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AFA3).withOpacity(0.04),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Text(
            text,
            style: GoogleFonts.amiri(
              color: const Color(0xFF0F172A),
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              height: 1.8,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ).animate().scale(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildOptionButton(QuizProvider provider, Question question, int index) {
    final optionText = question.options[index];
    final isAnswered = provider.isAnswered;
    final isSelected = provider.selectedAnswerIndex == index;
    final isCorrectOption = index == question.correctAnswerIndex;

    Color buttonBgColor = Colors.white;
    Color borderColor = const Color(0xFFE2E8F0);
    Color textColor = const Color(0xFF0F172A);

    if (isAnswered) {
      if (isCorrectOption) {
        // Highlight correct green
        buttonBgColor = const Color(0xFFD1FAE5); // Light Emerald
        borderColor = const Color(0xFF10B981);
        textColor = const Color(0xFF065F46);
      } else if (isSelected) {
        // Highlight incorrect red
        buttonBgColor = const Color(0xFFFEE2E2); // Light Red
        borderColor = const Color(0xFFEF4444);
        textColor = const Color(0xFF7F1D1D);
      } else {
        // Dim other options
        buttonBgColor = const Color(0xFFF8FAFC);
        borderColor = const Color(0xFFE2E8F0);
        textColor = const Color(0xFF94A3B8);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: buttonBgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.01),
            blurRadius: 8.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          onTap: isAnswered ? null : () => provider.selectAnswer(index),
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
                      fontWeight: isSelected || (isAnswered && isCorrectOption)
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 12.0),
                // Indicator circle
                Container(
                  width: 22.0,
                  height: 22.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAnswered
                          ? (isCorrectOption
                              ? const Color(0xFF10B981)
                              : (isSelected ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0)))
                          : const Color(0xFFE2E8F0),
                      width: 2.0,
                    ),
                    color: isAnswered && isCorrectOption
                        ? const Color(0xFF10B981)
                        : isAnswered && isSelected
                            ? const Color(0xFFEF4444)
                            : Colors.transparent,
                  ),
                  child: isAnswered && isCorrectOption
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 14.0)
                      : isAnswered && isSelected
                          ? const Icon(Icons.close_rounded, color: Colors.white, size: 14.0)
                          : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExplanationSheet(BuildContext context, QuizProvider provider, Question question) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (sheetContext) {
        final isCorrect = provider.selectedAnswerIndex == question.correctAnswerIndex;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Pull Bar Indicator
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
                const SizedBox(height: 18.0),

                // Answer Status Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      isCorrect ? 'إجابة صحيحة وموفقة!' : 'إجابة غير صحيحة',
                      style: GoogleFonts.cairo(
                        color: isCorrect ? const Color(0xFF00AFA3) : const Color(0xFFEF4444),
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Icon(
                      isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: isCorrect ? const Color(0xFF00AFA3) : const Color(0xFFEF4444),
                      size: 26.0,
                    ),
                  ],
                ),
                const SizedBox(height: 15.0),

                // Correct Answer Box (Shown if incorrect or timer ran out)
                if (!isCorrect) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5), // Light Emerald
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5), width: 1.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            question.options[question.correctAnswerIndex],
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF065F46),
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          'الجواب الصحيح هو:',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF065F46),
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFF065F46),
                          size: 20.0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15.0),
                ],

                // Explanation / Citation Text Box
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                       width: double.infinity,
                       padding: const EdgeInsets.all(15.0),
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(16.0),
                         border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.end,
                         children: [
                           Text(
                             'التفسير والسند الموثق:',
                             style: GoogleFonts.cairo(
                               color: const Color(0xFF00AFA3),
                               fontSize: 15.0,
                               fontWeight: FontWeight.bold,
                             ),
                             textAlign: TextAlign.right,
                           ),
                           const SizedBox(height: 6.0),
                           Text(
                             question.explanation,
                             style: GoogleFonts.cairo(
                               color: const Color(0xFF0F172A),
                               fontSize: 16.0,
                               height: 1.6,
                             ),
                             textAlign: TextAlign.right,
                           ),
                         ],
                       ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),

                // Action button to continue
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(sheetContext); // Close sheet

                    final hasNext = provider.nextQuestion();
                    if (!hasNext) {
                      // Quiz completed! Go to complete screen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StageCompleteScreen(
                            category: widget.category,
                            level: widget.level,
                            score: provider.score,
                            totalQuestions: provider.questions.length,
                            correctAnswers: provider.correctAnswersCount,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AFA3), // Soft Electric Teal
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    elevation: 0,
                  ),
                  child: Text(
                    'المتابعة',
                    style: GoogleFonts.cairo(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
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
}
