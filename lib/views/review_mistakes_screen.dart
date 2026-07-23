import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../models/question.dart';
import 'quiz_play_screen.dart';

class ReviewMistakesScreen extends StatelessWidget {
  const ReviewMistakesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5), // Warm parchment page background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00AFA3)), // Chevron Back
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'دفتر المذاكرة وتصحيح الأخطاء',
          style: GoogleFonts.cairo(
            color: const Color(0xFF0F172A), // Rich Navy Title
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          final wrongQuestionsCount = provider.wrongQuestionsCount;
          
          final List<Question> questions = wrongQuestionsCount > 0
              ? provider.getWrongQuestionsList()
              : [];

          if (wrongQuestionsCount == 0) {
            return _buildEmptyState(context);
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 15.0),
                  
                  // Leather-bound Journal style Summary Banner
                  Container(
                    padding: const EdgeInsets.all(22.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)], // Slate to Rich Navy
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: const Color(0xFFD97706), width: 1.5), // Elegant Gold Border
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.12),
                          blurRadius: 15.0,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'سجلّ المراجعة وتثبيت العلم',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFFBBF24), // Amber Gold
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'لديك حالياً $wrongQuestionsCount مسائل تحتاج إلى مراجعة وتثبيت للحفظ.',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFE2E8F0),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            provider.startReviewQuiz();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const QuizPlayScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00AFA3), // Soft Electric Teal
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
                            elevation: 0,
                          ),
                          child: Text(
                            'بدء كويز المذاكرة 📝',
                            style: GoogleFonts.cairo(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 25.0),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.bookmark_outline_rounded, color: Color(0xFF00AFA3), size: 20.0),
                      const SizedBox(width: 6.0),
                      Text(
                        'مسائل تحتاج لتمكين وحفظ:',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF00AFA3), // Soft Electric Teal
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10.0),

                  // Questions List
                  Expanded(
                    child: ListView.builder(
                      itemCount: questions.length,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        return _buildQuestionCard(context, provider, question);
                      },
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: const Color(0xFF00AFA3).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: Color(0xFF00AFA3),
                size: 70.0,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.bounceOut),
            const SizedBox(height: 25.0),
            Text(
              'دفترك خالٍ من الأخطاء! 🎉',
              style: GoogleFonts.cairo(
                color: const Color(0xFF00AFA3), // Soft Electric Teal
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'أحسنت القراءة والتعلم. استمر في الحفاظ على هذا الإنجاز الرائع وسعيك لطلب العلم الشرعي الموثوق.',
              style: GoogleFonts.cairo(
                color: const Color(0xFF64748B),
                fontSize: 14.0,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 35.0),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AFA3), // Soft Electric Teal
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 14.0),
                elevation: 0,
              ),
              child: Text(
                'العودة للرئيسية',
                style: GoogleFonts.cairo(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, QuizProvider provider, Question question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15.0),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9), // Warm Vintage Book Page color
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20.0),
          bottomRight: Radius.circular(20.0),
          topLeft: Radius.circular(8.0),
          bottomLeft: Radius.circular(8.0),
        ),
        border: Border(
          right: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
          top: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
          bottom: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
          left: const BorderSide(color: Color(0xFFD97706), width: 3.5), // Elegant Gold strip facing left
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Category & Mastered Checklist Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mastered / Resolve button instead of garbage bin
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  provider.removeWrongQuestion(question.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'تم تمكين المسألة وحذفها من سجلّ الأخطاء بنجاح 🎉',
                            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8.0),
                          const Icon(Icons.check_circle, color: Colors.white, size: 18.0),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
                icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18.0),
                label: Text(
                  'تم التمكين والحفظ',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF10B981),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                  backgroundColor: const Color(0xFFECFDF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              
              // Category tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AFA3).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: const Color(0xFF00AFA3).withOpacity(0.15), width: 0.5),
                ),
                child: Text(
                  _getCategoryArabicName(question.category),
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF00AFA3),
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          
          // Question prompt - Rich Navy with clear line spacing
          Text(
            question.question,
            style: GoogleFonts.cairo(
              color: const Color(0xFF0F172A), // Rich Navy
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              height: 1.6, // Clear line spacing
            ),
            textAlign: TextAlign.right,
          ),
          
          if (question.verseOrHadithText != null && question.verseOrHadithText!.isNotEmpty) ...[
            const SizedBox(height: 10.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5), // Warm parchment
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 1.0),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question.verseOrHadithText!,
                      style: GoogleFonts.amiri(
                        color: const Color(0xFF78350F), // Deep Warm Amber
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const Icon(Icons.menu_book_rounded, color: Color(0xFFF59E0B), size: 18.0),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 14.0),
          const Divider(color: Color(0xFFE2E8F0), height: 1.0),
          const SizedBox(height: 10.0),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Show Tafsir study sheet button
              TextButton.icon(
                onPressed: () => _showExplanationSheet(context, question),
                icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF00AFA3), size: 18.0),
                label: Text(
                  'عرض التفسير والسند',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF00AFA3),
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Correct Answer Label
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        question.options[question.correctAnswerIndex],
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF065F46), // Deep green
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18.0),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showExplanationSheet(BuildContext context, Question question) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAF8F5), // Warm parchment page background
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
      ),
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF8F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pull Bar
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

                  // Header
                  Text(
                    'التفسير والسند الموثق 📖',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFFD97706), // Warm Gold Title
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 15.0),

                  // Content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFDF9), // Warm Vintage Book Page
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 1.0),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.01),
                              blurRadius: 10.0,
                            )
                          ],
                        ),
                        child: Text(
                          question.explanation,
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF2C1810), // Deep brown Ink color
                            fontSize: 15.0,
                            height: 1.7,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  ElevatedButton(
                    onPressed: () => Navigator.pop(sheetContext),
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
                      'أغلق',
                      style: GoogleFonts.cairo(
                        fontSize: 15.0,
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

  String _getCategoryArabicName(String categoryId) {
    switch (categoryId) {
      case 'quran':
        return 'علوم القرآن';
      case 'aqeedah':
        return 'العقيدة والتوحيد';
      case 'fiqh':
        return 'الفقه والشريعة';
      case 'hadith':
        return 'الحديث النبوي';
      case 'seerah':
        return 'السيرة والتاريخ';
      default:
        return 'عام';
    }
  }
}
