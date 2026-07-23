import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/quiz_provider.dart';
import '../models/category.dart';
import '../services/encyclopedia_content_service.dart';
import 'quiz_play_screen.dart';

class EncyclopediaDetailScreen extends StatefulWidget {
  final Category category;

  const EncyclopediaDetailScreen({
    super.key,
    required this.category,
  });

  @override
  State<EncyclopediaDetailScreen> createState() => _EncyclopediaDetailScreenState();
}

class _EncyclopediaDetailScreenState extends State<EncyclopediaDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final activeColor = widget.category.color;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50 background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: activeColor),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.category.name,
          style: GoogleFonts.cairo(
            color: const Color(0xFF0F172A),
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<QuizProvider>(
        builder: (context, provider, child) {
          // Find the updated category state from provider
          final currentCategory = provider.categories.firstWhere(
            (c) => c.id == widget.category.id,
            orElse: () => widget.category,
          );
          
          final int userLevel = currentCategory.currentLevel;
          final int totalLevels = currentCategory.totalLevels;
          final double progressPercent = (userLevel - 1) / totalLevels;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Premium Category Header Card
                  _buildHeaderCard(currentCategory, userLevel, progressPercent, activeColor),
                  const SizedBox(height: 25.0),

                  // Section Title
                  Text(
                    'مسار المراحل الزمنية',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF0F172A),
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 15.0),

                  // Chronological Timeline list of 5 stages
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: totalLevels,
                    itemBuilder: (context, index) {
                      final int stageNum = index + 1;
                      final bool isCompleted = stageNum < userLevel;
                      final bool isActive = stageNum == userLevel;
                      final bool isLocked = stageNum > userLevel;

                      final lesson = EncyclopediaContentService.getLesson(widget.category.id, stageNum);

                      return _buildTimelineNode(
                        stageNum: stageNum,
                        isCompleted: isCompleted,
                        isActive: isActive,
                        isLocked: isLocked,
                        lesson: lesson,
                        activeColor: activeColor,
                        onTap: isLocked
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                _openReadingView(context, currentCategory, stageNum, lesson);
                              },
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(Category category, int userLevel, double progressPercent, Color activeColor) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: activeColor.withOpacity(0.15), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      category.name,
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF0F172A),
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      category.description,
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF64748B),
                        fontSize: 12.0,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 15.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  color: activeColor,
                  size: 28.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20.0),
          Container(
            height: 1.0,
            color: const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 15.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'المرحلة $userLevel من ${category.totalLevels}',
                style: GoogleFonts.cairo(
                  color: activeColor,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'التقدم الإجمالي بالموسوعة',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF64748B),
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: LinearProgressIndicator(
              value: progressPercent.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
              minHeight: 8.0,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildTimelineNode({
    required int stageNum,
    required bool isCompleted,
    required bool isActive,
    required bool isLocked,
    required EncyclopediaLesson? lesson,
    required Color activeColor,
    required VoidCallback? onTap,
  }) {
    if (lesson == null) return const SizedBox();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Content Card
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: const EdgeInsets.only(bottom: 20.0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: isLocked ? Colors.white.withOpacity(0.65) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20.0),
                    bottomRight: Radius.circular(20.0),
                    topLeft: Radius.circular(8.0),
                    bottomLeft: Radius.circular(8.0),
                  ),
                  border: Border(
                    right: BorderSide(
                      color: isLocked
                          ? const Color(0xFFE2E8F0)
                          : (isActive ? activeColor : const Color(0xFFF59E0B).withOpacity(0.4)),
                      width: 1.0,
                    ),
                    top: BorderSide(
                      color: isLocked
                          ? const Color(0xFFE2E8F0)
                          : (isActive ? activeColor : const Color(0xFFFBBF24).withOpacity(0.3)),
                      width: 1.0,
                    ),
                    bottom: BorderSide(
                      color: isLocked
                          ? const Color(0xFFE2E8F0)
                          : (isActive ? activeColor : const Color(0xFFFBBF24).withOpacity(0.3)),
                      width: 1.0,
                    ),
                    left: BorderSide(
                      color: isLocked
                          ? const Color(0xFFCBD5E1)
                          : (isActive ? activeColor : const Color(0xFFF59E0B)),
                      width: isActive ? 4.0 : 3.0, // Left colored vertical strip facing the timeline
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isActive
                          ? activeColor.withOpacity(0.04)
                          : const Color(0xFF0F172A).withOpacity(0.015),
                      blurRadius: 12.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Arrow/lock indicator on the left side of the card
                    if (isLocked)
                      const Icon(Icons.lock_rounded, color: Color(0xFF94A3B8), size: 20.0)
                    else if (isCompleted)
                      const Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 22.0)
                    else
                      Icon(Icons.play_circle_fill_rounded, color: activeColor, size: 24.0)
                          .animate(onPlay: (c) => c.repeat())
                          .shimmer(duration: 1500.ms),
                    
                    const SizedBox(width: 12.0),

                    // Text Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  lesson.title,
                                  style: GoogleFonts.cairo(
                                    color: isLocked ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.right,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                                decoration: BoxDecoration(
                                  color: isLocked
                                      ? const Color(0xFFE2E8F0)
                                      : (isActive ? activeColor.withOpacity(0.1) : const Color(0xFFFFFBEB)),
                                  borderRadius: BorderRadius.circular(8.0),
                                  border: Border.all(
                                    color: isLocked
                                        ? Colors.transparent
                                        : (isActive ? activeColor.withOpacity(0.2) : const Color(0xFFFDE68A)),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  'المرحلة $stageNum',
                                  style: GoogleFonts.cairo(
                                    color: isLocked ? const Color(0xFF64748B) : (isActive ? activeColor : const Color(0xFFD97706)),
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            lesson.subtitle,
                            style: GoogleFonts.cairo(
                              color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Timeline Indicator Column (the vertical track)
          const SizedBox(width: 15.0),
          Column(
            children: [
              // Circle Node Badge (Wax Seal style)
              if (isActive)
                Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [activeColor, activeColor.withRed(20).withGreen(160)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeColor.withOpacity(0.4),
                        blurRadius: 10.0,
                        spreadRadius: 3.0,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.8),
                        blurRadius: 2.0,
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 15.0,
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.12, 1.12), duration: 1200.ms, curve: Curves.easeInOut)
              else if (isCompleted)
                Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withOpacity(0.3),
                        blurRadius: 6.0,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16.0,
                    ),
                  ),
                )
              else
                Container(
                  width: 32.0,
                  height: 32.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_rounded,
                      color: Color(0xFF94A3B8),
                      size: 13.0,
                    ),
                  ),
                ),
              // Vertical Track Line (Dashed custom painter)
              Expanded(
                child: CustomPaint(
                  size: const Size(2.0, double.infinity),
                  painter: DashedLinePainter(
                    color: isLocked ? const Color(0xFFE2E8F0) : activeColor.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (stageNum * 80).ms, duration: 400.ms).slideY(begin: 0.05, end: 0);
  }

  void _openReadingView(BuildContext context, Category category, int level, EncyclopediaLesson? lesson) {
    if (lesson == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EncyclopediaReadingScreen(
          category: category,
          level: level,
          lesson: lesson,
        ),
      ),
    );
  }
}

/// Immersive Reading and Study Screen
class EncyclopediaReadingScreen extends StatelessWidget {
  final Category category;
  final int level;
  final EncyclopediaLesson lesson;

  const EncyclopediaReadingScreen({
    super.key,
    required this.category,
    required this.level,
    required this.lesson,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = category.color;
    final bool isUserCurrentLevel = category.currentLevel == level;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5), // Warm Parchment/Book Page background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: activeColor, size: 26.0),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Center(
              child: Text(
                'دراسة المرحلة $level',
                style: GoogleFonts.cairo(
                  color: activeColor,
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Reading Progress Indicator (Just a subtle aesthetic line)
            Container(
              height: 2.0,
              width: double.infinity,
              color: activeColor.withOpacity(0.1),
              child: FractionallySizedBox(
                alignment: Alignment.centerRight, // RTL reading flow
                widthFactor: 1.0,
                child: Container(
                  color: activeColor,
                ),
              ).animate().shimmer(duration: 1.seconds),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Lesson Title
                    Text(
                      lesson.title,
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF2C1810), // Rich Sepia/Dark brown
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 6.0),
                    
                    // Subtitle
                    Text(
                      lesson.subtitle,
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF8C7A6B),
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 25.0),

                    // Key Takeaways Bento Card
                    _buildKeyTakeaways(context, activeColor),
                    const SizedBox(height: 30.0),

                    // Paragraphs of Prose
                    ...lesson.paragraphs.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Text(
                        p,
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF2C1810),
                          fontSize: 16.0,
                          height: 1.8, // Comfortable line spacing for reading
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    )),
                    const SizedBox(height: 15.0),

                    // Quote Container Block
                    if (lesson.quoteText.isNotEmpty) ...[
                      _buildQuoteBlock(activeColor),
                      const SizedBox(height: 40.0),
                    ],
                  ],
                ),
              ),
            ),

            // Action footer
            _buildActionFooter(context, activeColor, isUserCurrentLevel),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyTakeaways(BuildContext context, Color activeColor) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: activeColor.withOpacity(0.12), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C1810).withOpacity(0.015),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'النقاط المستخلصة للدرس',
                style: GoogleFonts.cairo(
                  color: activeColor,
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8.0),
              Icon(Icons.star_rounded, color: activeColor, size: 20.0),
            ],
          ),
          const SizedBox(height: 12.0),
          ...lesson.keyPoints.map((point) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    point,
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF5C4A3C),
                      fontSize: 12.5,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8.0),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: CircleAvatar(
                    radius: 3.5,
                    backgroundColor: activeColor,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildQuoteBlock(Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
      decoration: BoxDecoration(
        color: activeColor.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16.0),
        border: Border(
          right: BorderSide(color: activeColor, width: 4.0), // RTL blockquote border
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: activeColor.withOpacity(0.2),
            size: 36.0,
          ),
          Text(
            lesson.quoteText,
            style: GoogleFonts.cairo(
              color: const Color(0xFF2C1810),
              fontSize: 15.0,
              height: 1.7,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12.0),
          Text(
            '— ${lesson.quoteAuthor}',
            style: GoogleFonts.cairo(
              color: const Color(0xFF8C7A6B),
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 450.ms);
  }

  Widget _buildActionFooter(BuildContext context, Color activeColor, bool isCurrent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 15.0,
            offset: const Offset(0, -4),
          )
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isCurrent)
            Text(
              'بإنهاء القراءة، ستنتقل لاختبار المرحلة للتحقق من حفظك وفهمك للمعلومات.',
              style: GoogleFonts.cairo(
                color: const Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            )
          else
            Text(
              'لقد اجتزت هذه المرحلة مسبقاً، يمكنك إعادة الاختبار للمراجعة وتثبيت الحفظ.',
              style: GoogleFonts.cairo(
                color: const Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 12.0),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizPlayScreen(
                    category: category,
                    level: level,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: activeColor,
              foregroundColor: Colors.white,
              elevation: 2.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_turned_in_rounded, size: 20.0),
                const SizedBox(width: 8.0),
                Text(
                  isCurrent ? 'أنهيت القراءة، لنبدأ الاختبار! 📝' : 'إعادة اختبار هذه المرحلة 🔄',
                  style: GoogleFonts.cairo(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;
  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5.0, dashSpace = 4.0, startY = 0.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
