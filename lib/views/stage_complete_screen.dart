import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/quiz_provider.dart';
import 'quiz_play_screen.dart';
import '../services/encyclopedia_content_service.dart';
import 'encyclopedia_detail_screen.dart';

class StageCompleteScreen extends StatelessWidget {
  final Category? category;
  final int? level;
  final int score;
  final int totalQuestions;
  final int correctAnswers;

  const StageCompleteScreen({
    super.key,
    this.category,
    this.level,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final double successRate = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 0.0;
    final bool isPassed = correctAnswers > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Clean Neutral White
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Spacer(),

              // Victory Badge
              Center(
                child: Container(
                  width: 140.0,
                  height: 140.0,
                  decoration: BoxDecoration(
                    color: isPassed
                        ? const Color(0xFF00AFA3).withOpacity(0.12) // Soft Electric Teal Tint
                        : const Color(0xFFEF4444).withOpacity(0.12), // Red Tint
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isPassed ? const Color(0xFF00AFA3) : const Color(0xFFEF4444),
                      width: 3.0,
                    ),
                  ),
                  child: Icon(
                    isPassed ? Icons.military_tech_rounded : Icons.info_outline_rounded,
                    color: isPassed ? const Color(0xFF00AFA3) : const Color(0xFFEF4444),
                    size: 80.0,
                  ),
                ),
              )
                  .animate()
                  .scale(duration: 500.ms, curve: Curves.bounceOut)
                  .then()
                  .shake(duration: 400.ms, hz: 4),

              const SizedBox(height: 30.0),

              // Status Title
              Text(
                isPassed ? 'تهانينا المباركة!' : 'حاول مرة أخرى',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF00AFA3), // Soft Electric Teal
                  fontSize: 24.0,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 10.0),

              // Status Description
              Text(
                isPassed
                    ? (category != null && level != null
                        ? 'لقد اجتزت المستوى $level في مسار "${category!.name}" بنجاح وتلقيت مكافأة المعرفة.'
                        : 'لقد قمت بمراجعة وتصحيح الأسئلة المتعثرة بنجاح وتثبيت معارفك الشرعية!')
                    : 'لم تتمكن من إحراز أي إجابة صحيحة في هذا المستوى. ننصحك بإعادة المحاولة لتوسيع معارفك.',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF64748B),
                  fontSize: 14.5,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

              const SizedBox(height: 35.0),

              // Stats Box (Bento-style summary card)
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Accuracy Stat
                    _buildStatCol(
                      label: 'نسبة الدقة',
                      value: '${successRate.toStringAsFixed(0)}%',
                      color: const Color(0xFF00AFA3),
                    ),
                    // Vertical divider
                    Container(height: 40.0, width: 1.0, color: const Color(0xFFE2E8F0)),
                    // Correct/Total Stat
                    _buildStatCol(
                      label: 'الإجابات الصحيحة',
                      value: '$correctAnswers / $totalQuestions',
                      color: const Color(0xFF00AFA3),
                    ),
                    // Vertical divider
                    Container(height: 40.0, width: 1.0, color: const Color(0xFFE2E8F0)),
                    // Score Gained Stat
                    _buildStatCol(
                      label: 'النقاط المكتسبة',
                      value: '+$score',
                      color: const Color(0xFF2563EB), // Sapphire
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.1, end: 0),

              Spacer(flex: 2),

              // Actions Buttons
              Row(
                children: [
                  // Secondary Button (Home)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00AFA3),
                        side: const BorderSide(color: Color(0xFF00AFA3), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                      ),
                      child: Text(
                        'الرئيسية',
                        style: GoogleFonts.cairo(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15.0),

                  // Primary Button (Next Level or Replay)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (category == null || level == null) {
                          // In review mode: restart review quiz if they want to do it again
                          context.read<QuizProvider>().startReviewQuiz();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QuizPlayScreen(),
                            ),
                          );
                        } else {
                          final isEnc = category!.id.startsWith('enc_');
                          if (isEnc && isPassed) {
                            if (level! < 5) {
                              // Go to study/reading screen of next level
                              final nextLevel = level! + 1;
                              final lesson = EncyclopediaContentService.getLesson(category!.id, nextLevel);
                              if (lesson != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EncyclopediaReadingScreen(
                                      category: category!,
                                      level: nextLevel,
                                      lesson: lesson,
                                    ),
                                  ),
                                );
                              } else {
                                // Fallback: pop back to timeline
                                Navigator.pop(context);
                              }
                            } else {
                              // Finished all 5 levels, pop back to timeline
                              Navigator.pop(context);
                            }
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizPlayScreen(
                                  category: category,
                                  level: isPassed ? level! + 1 : level!,
                                ),
                              ),
                            );
                          }
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
                        category == null
                            ? (isPassed ? 'مراجعة المزيد' : 'إعادة المحاولة')
                            : (isPassed 
                                ? (category!.id.startsWith('enc_') && level == 5 
                                    ? 'العودة للموسوعة' 
                                    : 'المستوى التالي') 
                                : 'إعادة المحاولة'),
                        style: GoogleFonts.cairo(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
              const SizedBox(height: 10.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 22.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: GoogleFonts.cairo(
            color: const Color(0xFF64748B),
            fontSize: 10.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
