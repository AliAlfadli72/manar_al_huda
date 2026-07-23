import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/quiz_provider.dart';
import '../models/category.dart';
import '../models/scholar_rank.dart';
import 'quiz_play_screen.dart';
import 'library_screen.dart';
import 'review_mistakes_screen.dart';
import 'profile_screen.dart';
import 'online_duel_setup_screen.dart';
import 'leaderboard_screen.dart';
import 'encyclopedia_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isEncyclopediaMode = false;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<QuizProvider>();
      provider.loadCategories();
      provider.initDailyTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF), // Clean Neutral White
        body: Consumer<QuizProvider>(
          builder: (context, provider, child) {
            return IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeTab(provider),
                const LibraryScreen(),
                const LeaderboardScreen(),
                const ProfileScreen(),
              ],
            );
          },
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
        floatingActionButton: _currentIndex == 0 ? _buildDailyHabitsFAB(context) : null,
      ),
    );
  }

  Widget _buildHomeTab(QuizProvider provider) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Header
            _buildHeader(provider),
            const SizedBox(height: 20.0),

            // Mode Selector Toggle
            _buildModeSelector(),
            const SizedBox(height: 25.0),

            // Quick Access Learning Tools (Library & Review Mistakes)
            _buildLearningToolsCards(context, provider),
            const SizedBox(height: 25.0),

            // Category Path Map title
            Text(
              'مسارات المعرفة والتعلم',
              style: GoogleFonts.cairo(
                color: const Color(0xFF00AFA3), // Soft Electric Teal
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0),
            const SizedBox(height: 15.0),

            // Category Path Timeline
            _buildCategoryPathMap(provider),
            const SizedBox(height: 50.0), // Proper padding at bottom to resolve overflow
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Slate 100
        borderRadius: BorderRadius.circular(100.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isEncyclopediaMode = true;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  color: _isEncyclopediaMode ? const Color(0xFF00AFA3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(100.0),
                ),
                child: Center(
                  child: Text(
                    'موسوعة السير والتاريخ 📚',
                    style: GoogleFonts.cairo(
                      color: _isEncyclopediaMode ? Colors.white : const Color(0xFF64748B),
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isEncyclopediaMode = false;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  color: !_isEncyclopediaMode ? const Color(0xFF00AFA3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(100.0),
                ),
                child: Center(
                  child: Text(
                    'مسار العلوم الشرعية 🕌',
                    style: GoogleFonts.cairo(
                      color: !_isEncyclopediaMode ? Colors.white : const Color(0xFF64748B),
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AFA3).withOpacity(0.06),
            blurRadius: 20.0,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
      padding: EdgeInsets.only(
        top: 8.0,
        bottom: bottomPadding > 0 ? bottomPadding + 6.0 : 16.0, // Generous padding to avoid Android 3-button bar overlap
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'الرئيسية'),
            _buildNavItem(1, Icons.library_books_rounded, 'المكتبة'),
            _buildNavItem(2, Icons.emoji_events_rounded, 'المتصدرين'),
            _buildNavItem(3, Icons.person_rounded, 'حسابي'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final activeColor = const Color(0xFF00AFA3); // Soft Electric Teal
    final inactiveColor = const Color(0xFF94A3B8); // Slate Gray

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24.0,
            ),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: GoogleFonts.cairo(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 11.0,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(QuizProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top row with Logo and Info Icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Info Icon (on the left)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                    title: Text(
                      'منارة الهدى',
                      style: GoogleFonts.cairo(color: const Color(0xFF00AFA3), fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                    content: Text(
                      'تطبيق منارة الهدى هو رفيقك لتعلم العلوم الشرعية والتاريخ الإسلامي وسير الخلفاء بأسلوب عصري وتفاعلي موثق.',
                      style: GoogleFonts.cairo(color: const Color(0xFF475569), fontSize: 14.5),
                      textAlign: TextAlign.right,
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('حسناً', style: GoogleFonts.cairo(color: const Color(0xFF00AFA3), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),

            // App Brand Name & Subtitle
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end, // Right-aligned text
                  children: [
                    Text(
                      'منارة الهدى',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF0F172A), // Rich Navy
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'تطبيقك التعليمي الشرعي الموثق',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF64748B),
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10.0),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00AFA3).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.explore_rounded, // Compass/Navigation Icon
                    color: Color(0xFF00AFA3),
                    size: 24.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        
        const SizedBox(height: 20.0),
        
        // Greeting Header (e.g. "أهلاً بك يا طالب العلم 👋")
        StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            final user = authSnapshot.data;
            if (user == null) {
              return Text(
                'أهلاً بك في منارة الهدى 👋',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF0F172A),
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              );
            }
            
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, profileSnapshot) {
                String displayName = 'طالب العلم';
                if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
                  displayName = profileSnapshot.data!.data()?['name'] ?? 'طالب العلم';
                }
                
                return Text(
                  'مرحباً بك يا $displayName 👋',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF0F172A),
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                );
              },
            );
          },
        ),
        
        const SizedBox(height: 15.0),
        
        // Clean Slate Divider Line
        Container(
          height: 1.0,
          color: const Color(0xFFE2E8F0),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }


  Widget _buildBentoStats(QuizProvider provider) {
    final currentRank = ScholarRank.getRank(provider.totalPoints);
    return Column(
      children: [
        Row(
          children: [
            // Level / Scholar Rank Card (60%) - Centerpiece with deep indigo-to-teal gradient
            Expanded(
              flex: 3,
              child: Container(
                height: 95.0,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF00AFA3)], // Deep Indigo to Soft Teal
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.0), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.12),
                      blurRadius: 15.0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Detailed gold trophy with gradient background
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded, // 3D-like gold trophy icon
                        color: Color(0xFFFBBF24), // Vibrant gold
                        size: 32.0,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'الرتبة العلمية',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFFCCFBF1),
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Row(
                          children: [
                            Text(
                              currentRank.icon,
                              style: const TextStyle(fontSize: 16.0),
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              currentRank.title,
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            // Total Points Card (40%) - Styled with Sapphire
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                  );
                },
                child: Container(
                  height: 95.0,
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.015),
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Color(0xFF2563EB), size: 24.0),
                      const SizedBox(height: 4.0),
                      Text(
                        '${provider.totalPoints} ن',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF2563EB), // Sapphire
                          fontSize: 18.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'عرض الترتيب 🏆',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF64748B),
                          fontSize: 9.0,
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
        const SizedBox(height: 12.0),
        Row(
          children: [
            // Streak Bento
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'التتابع اليومي',
                          style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 11.0, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${provider.streakCount} أيام',
                          style: GoogleFonts.cairo(color: const Color(0xFF00AFA3), fontSize: 13.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10.0),
                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFFEF4444), size: 22.0),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            // High Score Bento
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'أعلى نتيجة',
                          style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 11.0, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${provider.highScore} ن',
                          style: GoogleFonts.cairo(color: const Color(0xFF00AFA3), fontSize: 13.0, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10.0),
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFF2563EB), size: 22.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 150.ms, duration: 500.ms);
  }

  Widget _buildLearningToolsCards(BuildContext context, QuizProvider provider) {
    final int wrongCount = provider.wrongQuestionsCount;
    return Row(
      children: [
        // Library Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LibraryScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00AFA3).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_stories_rounded,
                      color: Color(0xFF00AFA3),
                      size: 22.0,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'مكتبة المنارة',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF00AFA3),
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'اقرأ وتدبر الشواهد',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF64748B),
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12.0),

        // Wrong Questions Card
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReviewMistakesScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: wrongCount > 0 
                      ? const Color(0xFFEF4444).withOpacity(0.4) 
                      : const Color(0xFFE2E8F0), 
                  width: wrongCount > 0 ? 1.2 : 1.0,
                ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (wrongCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            '$wrongCount',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        const SizedBox(),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: wrongCount > 0 
                              ? const Color(0xFFEF4444).withOpacity(0.08) 
                              : const Color(0xFF64748B).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.assignment_late_rounded,
                          color: wrongCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                          size: 22.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    'مراجعة أخطائي',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF00AFA3),
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    wrongCount > 0 ? 'صحح $wrongCount أسئلة متعثرة' : 'لا أخطاء حالياً، أحسنت!',
                    style: GoogleFonts.cairo(
                      color: wrongCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildBentoItem({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22.0),
              Text(
                title,
                style: GoogleFonts.cairo(
                  color: const Color(0xFF64748B),
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.cairo(
                  color: const Color(0xFF0F172A),
                  fontSize: 18.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.cairo(
                  color: const Color(0xFF64748B),
                  fontSize: 9.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChallengeCard(QuizProvider provider) {
    final quranCat = provider.categories.isNotEmpty
        ? provider.categories.first
        : Category(
            id: 'quran',
            name: 'علوم القرآن',
            description: '',
            icon: Icons.book,
            color: const Color(0xFF00AFA3),
            isLocked: false,
          );

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00AFA3), // Electric Teal
            Color(0xFF1E3A8A), // Deep Royal Indigo
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00AFA3).withOpacity(0.12),
            blurRadius: 15.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(100.0),
                ),
                child: Text(
                  'مكافأة +25 نقطة',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF22D3EE),
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'التحدي اليومي',
                style: GoogleFonts.cairo(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            'اختبر علمك في علوم القرآن الكريم والتفسير الميسر للآيات لتكسب نقاطاً إضافية اليوم.',
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 18.0),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizPlayScreen(
                    category: quranCat,
                    level: quranCat.currentLevel,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF00AFA3),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            ),
            child: Text(
              'ابدأ التحدي الآن',
              style: GoogleFonts.cairo(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 550.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildOnlineDuelCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white, // Clean White Background
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.18), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.02),
            blurRadius: 15.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(100.0),
                ),
                child: Text(
                  'تحدٍ مباشر أونلاين ⚡',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF2563EB), // Sapphire
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'مبارزة المعرفة أونلاين',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF0F172A), // Navy Text
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            'تحدَّ أصدقاءك في مبارزة علمية دينية مباشرة أونلاين، وأثبت سرعة إجابتك وقوة معلوماتك!',
            style: GoogleFonts.cairo(
              color: const Color(0xFF1E293B), // Navy Body Text
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 18.0),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)], // Sapphire to Royal Indigo
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnlineDuelSetupScreen(),
                  ),
                ).then((_) => setState(() {}));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.flash_on_rounded, color: Colors.white),
                  const SizedBox(width: 8.0),
                  Text(
                    'ابدأ التحدي الآن',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30.0),
        ],
      ),
    );
  }

  Widget _buildCategoryPathMap(QuizProvider provider) {
    if (provider.categories.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00AFA3)),
      );
    }

    final filteredList = provider.categories.where((cat) {
      final isEnc = cat.id.startsWith('enc_');
      return _isEncyclopediaMode ? isEnc : !isEnc;
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final category = filteredList[index];
        final isLast = index == filteredList.length - 1;
        return _buildCategoryNode(category, index, isLast);
      },
    );
  }

  Widget _buildCategoryNode(Category category, int index, bool isLast) {
    final isLocked = category.isLocked;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sleek Vertical Track & Circular Badge Segment
        SizedBox(
          width: 45.0,
          child: Column(
            children: [
              // Upper line connector
              Container(
                width: 1.5,
                height: 25.0,
                color: index == 0 ? Colors.transparent : (isLocked ? const Color(0xFFE2E8F0) : const Color(0xFF00AFA3)),
              ),
              // Circular Level Badge on the track itself
              Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  color: isLocked ? Colors.white : const Color(0xFF00AFA3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isLocked ? const Color(0xFFCBD5E1) : const Color(0xFF1E3A8A),
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (!isLocked)
                      BoxShadow(
                        color: const Color(0xFF00AFA3).withOpacity(0.25),
                        blurRadius: 6.0,
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${category.currentLevel}',
                    style: GoogleFonts.outfit(
                      color: isLocked ? const Color(0xFF64748B) : Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Lower line connector
              Container(
                width: 1.5,
                height: 35.0,
                color: isLast ? Colors.transparent : (isLocked ? const Color(0xFFE2E8F0) : const Color(0xFF00AFA3)),
              ),
            ],
          ),
        ),
        
        // Category Card Module
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(top: 8.0, bottom: 8.0),
            decoration: BoxDecoration(
              color: isLocked ? Colors.white.withOpacity(0.6) : Colors.white,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(
                color: isLocked
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF00AFA3).withOpacity(0.2),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.015),
                  blurRadius: 10.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: InkWell(
                onTap: isLocked
                    ? () {
                        HapticFeedback.heavyImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'أكمل المرحلة السابقة لفتح هذا المسار!',
                              style: GoogleFonts.cairo(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                    : () {
                        HapticFeedback.lightImpact();
                        if (_isEncyclopediaMode) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EncyclopediaDetailScreen(
                                category: category,
                              ),
                            ),
                          ).then((_) => setState(() {}));
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => QuizPlayScreen(
                                category: category,
                                level: category.currentLevel,
                              ),
                            ),
                          );
                        }
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
                  child: Row(
                    children: [
                      // Lock indicator or arrow
                      if (isLocked)
                        const Icon(
                          Icons.lock_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20.0,
                        )
                      else
                        const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF00AFA3),
                          size: 16.0,
                        ),
                        
                      const Spacer(),
                      
                      // Category details
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              category.name,
                              style: GoogleFonts.cairo(
                                color: isLocked ? const Color(0xFF64748B) : const Color(0xFF0F172A), // Rich Navy
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              category.description,
                              style: GoogleFonts.cairo(
                                color: isLocked ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontSize: 11.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 12.0),
                      
                      // Beautiful Bespoke Micro-Icons/Avatars with premium background
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: isLocked ? const Color(0xFFF1F5F9) : category.color.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category.icon,
                          color: isLocked ? const Color(0xFF94A3B8) : category.color,
                          size: 26.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildDailyHabitsFAB(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, provider, child) {
        return FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.mediumImpact();
            _showDailyHabitsBottomSheet(context, provider);
          },
          backgroundColor: const Color(0xFF00AFA3), // Soft Electric Teal
          elevation: 6.0,
          highlightElevation: 8.0,
          label: Row(
            children: [
              Text(
                'المهام والتحديات',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13.0,
                ),
              ),
              const SizedBox(width: 8.0),
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFFBBF24),
                size: 20.0,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDailyHabitsBottomSheet(BuildContext context, QuizProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final List<Map<String, dynamic>> dailyTasks = [
              {
                'id': 'daily_quran',
                'title': 'الورد القرآني اليومي',
                'subtitle': 'قراءة حزب أو صفحة من القرآن الكريم',
                'points': 3,
                'icon': Icons.auto_stories_rounded,
                'color': const Color(0xFF14B8A6),
              },
              {
                'id': 'daily_morning_azkar',
                'title': 'أذكار الصباح',
                'subtitle': 'المحافظة على الذكر في الصباح',
                'points': 2,
                'icon': Icons.wb_sunny_rounded,
                'color': const Color(0xFFF59E0B),
              },
              {
                'id': 'daily_evening_azkar',
                'title': 'أذكار المساء',
                'subtitle': 'المحافظة على الذكر في المساء',
                'points': 2,
                'icon': Icons.nightlight_round,
                'color': const Color(0xFF8B5CF6),
              },
              {
                'id': 'daily_prayer',
                'title': 'صلاة الجماعة',
                'subtitle': 'أداء الصلوات المفروضة جماعة',
                'points': 3,
                'icon': Icons.mosque_rounded,
                'color': const Color(0xFF10B981),
              },
            ];

            int completedCount = 0;
            for (var task in dailyTasks) {
              if (provider.isDailyTaskCompleted(task['id'] as String)) {
                completedCount++;
              }
            }
            final progressPercentage = completedCount / dailyTasks.length;

            final quranCat = provider.categories.isNotEmpty
                ? provider.categories.first
                : Category(
                    id: 'quran',
                    name: 'علوم القرآن',
                    description: '',
                    icon: Icons.book,
                    color: const Color(0xFF00AFA3),
                    isLocked: false,
                  );

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 50.0,
                          height: 5.0,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          ),
                          Text(
                            'مركز الأنشطة والتحديات ⚡',
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF0F172A),
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'الورد والمهام الإيمانية',
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF0F172A),
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          const Icon(Icons.today_rounded, color: Color(0xFF00AFA3), size: 20.0),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Container(
                        padding: const EdgeInsets.all(14.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00AFA3).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(color: const Color(0xFF00AFA3).withOpacity(0.12), width: 1.0),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(progressPercentage * 100).toInt()}% اكتمل',
                                  style: GoogleFonts.cairo(
                                    color: const Color(0xFF00AFA3),
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'أنجزت $completedCount من أصل ${dailyTasks.length} أوراد',
                                  style: GoogleFonts.cairo(
                                    color: const Color(0xFF0F172A),
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: LinearProgressIndicator(
                                value: progressPercentage,
                                minHeight: 6.0,
                                backgroundColor: Colors.white,
                                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00AFA3)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Column(
                        children: dailyTasks.map((task) {
                          final taskId = task['id'] as String;
                          final isCompleted = provider.isDailyTaskCompleted(taskId);
                          final taskColor = task['color'] as Color;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            decoration: BoxDecoration(
                              color: isCompleted ? taskColor.withOpacity(0.03) : Colors.white,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: isCompleted ? taskColor.withOpacity(0.25) : const Color(0xFFE2E8F0),
                                width: 1.0,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                              leading: Text(
                                '+${task['points']} ن',
                                style: GoogleFonts.outfit(
                                  color: isCompleted ? taskColor : const Color(0xFF64748B),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              title: Text(
                                task['title'] as String,
                                style: GoogleFonts.cairo(
                                  color: const Color(0xFF0F172A),
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                ),
                                textAlign: TextAlign.right,
                              ),
                              trailing: GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  provider.toggleDailyTask(taskId, task['points'] as int);
                                  setSheetState(() {});
                                  setState(() {});
                                },
                                child: Container(
                                  width: 24.0,
                                  height: 24.0,
                                  decoration: BoxDecoration(
                                    color: isCompleted ? taskColor : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isCompleted ? taskColor : const Color(0xFFCBD5E1),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isCompleted
                                      ? const Icon(Icons.check, color: Colors.white, size: 14.0)
                                      : null,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'التحديات اليومية والمباشرة',
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF0F172A),
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6.0),
                          const Icon(Icons.flash_on_rounded, color: Color(0xFFFBBF24), size: 20.0),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00AFA3), Color(0xFF1E3A8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00AFA3).withOpacity(0.1),
                              blurRadius: 10.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    'مكافأة +25 نقطة',
                                    style: GoogleFonts.cairo(
                                      color: const Color(0xFF22D3EE),
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  'التحدي اليومي',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'اختبر علمك في علوم القرآن الكريم والتفسير الميسر للآيات لتكسب نقاطاً إضافية اليوم.',
                              style: GoogleFonts.cairo(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12.0,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 12.0),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuizPlayScreen(
                                      category: quranCat,
                                      level: quranCat.currentLevel,
                                    ),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF00AFA3),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                              ),
                              child: Text(
                                'ابدأ التحدي الآن',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              blurRadius: 10.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Text(
                                    'مباشر أونلاين ⚡',
                                    style: GoogleFonts.cairo(
                                      color: const Color(0xFF60A5FA),
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  'مبارزة المعرفة أونلاين',
                                  style: GoogleFonts.cairo(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              'تحدَّ أصدقاءك في مبارزة علمية دينية مباشرة أونلاين، وأثبت سرعة إجابتك وقوة معلوماتك!',
                              style: GoogleFonts.cairo(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12.0,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 12.0),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const OnlineDuelSetupScreen(),
                                  ),
                                ).then((_) => setState(() {}));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF2563EB),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                              ),
                              child: Text(
                                'ابدأ المبارزة الآن',
                                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.0 + MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
