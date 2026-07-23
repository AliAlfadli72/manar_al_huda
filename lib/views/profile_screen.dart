import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/firebase_service.dart';
import 'auth/login_screen.dart';
import '../providers/quiz_provider.dart';
import '../models/scholar_rank.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = _firebaseService.currentUser;
      if (user != null) {
        final quizProvider = Provider.of<QuizProvider>(context, listen: false);
        _firebaseService.syncLocalStats(
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

  String _getAvatarLabel(String avatarId) {
    switch (avatarId) {
      case 'avatar_student':
        return 'طالب العلم';
      case 'avatar_book':
        return 'القارئ المتدبر';
      case 'avatar_beacon':
        return 'منارة التوجيه';
      case 'avatar_star':
        return 'النجم اللامع';
      case 'avatar_shield':
        return 'حامي العقيدة';
      case 'avatar_light':
        return 'مصباح المعرفة';
      default:
        return 'عضو منارة';
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
        return const Color(0xFF2563EB); // Sapphire Blue
      case 'avatar_shield':
        return const Color(0xFF10B981); // Emerald Green
      case 'avatar_light':
        return const Color(0xFFEC4899); // Pink
      default:
        return const Color(0xFF94A3B8); // Slate
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00AFA3)),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle_outlined, size: 85.0, color: Color(0xFF00AFA3))
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 2000.ms),
                const SizedBox(height: 20.0),
                Text(
                  'لم تقم بتسجيل الدخول بعد',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF0F172A),
                    fontSize: 19.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10.0),
                Text(
                  'سجل دخولك الآن لمزامنة نقاطك، ورؤية رتبتك، وتحدي أصدقائك أونلاين والمنافسة في لوحة الشرف.',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF64748B),
                    fontSize: 14.0,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30.0),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    ).then((_) => setState(() {}));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AFA3),
                    padding: const EdgeInsets.symmetric(horizontal: 44.0, vertical: 14.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                    elevation: 0,
                  ),
                  child: Text(
                    'تسجيل الدخول',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
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
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50 background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00AFA3)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'ملفي الشخصي',
          style: GoogleFonts.cairo(
            color: const Color(0xFF0F172A),
            fontSize: 19.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firebaseService.streamUserProfile(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00AFA3)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(
                'حدث خطأ في تحميل ملف المستخدم.',
                style: GoogleFonts.cairo(color: const Color(0xFF00AFA3), fontWeight: FontWeight.bold),
              ),
            );
          }

          final data = snapshot.data!.data()!;
          final String name = data['name'] ?? 'عضو منارة';
          final String email = data['email'] ?? '';
          final String avatarId = data['avatar'] ?? 'avatar_student';
          final int points = data['points'] ?? 0;
          final int wins = data['wins'] ?? 0;
          final int losses = data['losses'] ?? 0;
          final int streak = data['streak'] ?? 0;

          final String avatarLabel = _getAvatarLabel(avatarId);
          final Color avatarColor = _getAvatarColor(avatarId);

          // Get count of unlocked badges
          final badges = _getBadgesList(points, wins, streak);
          final int unlockedCount = badges.where((b) => b.isUnlocked(points, wins, streak)).length;

          // Win Rate
          final double winRate = (wins + losses) > 0 ? wins / (wins + losses) : 0.0;
          final int winRatePercent = (winRate * 100).toInt();

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Top Glassmorphic Profile Card
                  _buildTopProfileCard(
                    userUid: user.uid,
                    name: name,
                    email: email,
                    avatarId: avatarId,
                    avatarLabel: avatarLabel,
                    avatarColor: avatarColor,
                    points: points,
                  ),
                  const SizedBox(height: 20.0),

                  // 2. Analytical Row (Win Rate card)
                  _buildAnalyticalCard(wins, losses, winRate, winRatePercent),
                  const SizedBox(height: 20.0),

                  // 3. Bento Stats Grid
                  _buildBentoGrid(points, wins, losses, streak),
                  const SizedBox(height: 25.0),

                  // 4. Badges Summary & Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00AFA3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(100.0),
                        ),
                        child: Text(
                          '$unlockedCount من 8 مفتوح',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF00AFA3),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'أوسمة الإنجاز والتميز ✦',
                        style: GoogleFonts.cairo(
                          color: const Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  _buildBadgesGrid(points, wins, streak, badges),
                  const SizedBox(height: 25.0),

                  // 5. Account Quick Actions
                  Text(
                    'إعدادات الحساب والإجراءات',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 10.0),
                  _buildQuickActionsList(context),
                  const SizedBox(height: 40.0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Top Glassmorphic Profile Card with Avatar editor
  Widget _buildTopProfileCard({
    required String userUid,
    required String name,
    required String email,
    required String avatarId,
    required String avatarLabel,
    required Color avatarColor,
    required int points,
  }) {
    final rank = ScholarRank.getRank(points);
    final progress = ScholarRank.getProgressToNext(points, rank);
    final progressLabel = ScholarRank.getProgressLabel(points, rank);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.0),
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
        children: [
          // Avatar with Edit Pencil Overlay
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _showAvatarSelectionBottomSheet(userUid, avatarId);
            },
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Avatar Circle
                Container(
                  padding: const EdgeInsets.all(5.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [avatarColor, avatarColor.withOpacity(0.3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18.0),
                      decoration: BoxDecoration(
                        color: avatarColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getAvatarIcon(avatarId),
                        color: avatarColor,
                        size: 42.0,
                      ),
                    ),
                  ),
                ),

                // Edit pencil icon badge
                Positioned(
                  bottom: 2,
                  left: 2,
                  child: Container(
                    padding: const EdgeInsets.all(5.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00AFA3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: Colors.white,
                      size: 11.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          // User Name
          Text(
            name,
            style: GoogleFonts.cairo(
              color: const Color(0xFF0F172A),
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2.0),

          // Email
          Text(
            email,
            style: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontSize: 12.0,
            ),
          ),
          const SizedBox(height: 12.0),

          // Rank Pill & Progress
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
          const SizedBox(height: 14.0),

          // Progress bar
          if (ScholarRank.getNextRank(rank) != null) ...[
            SizedBox(
              width: 220.0,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5.5,
                      backgroundColor: const Color(0xFFF1F5F9),
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
      ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),
    );
  }

  // Bottom sheet to select a new avatar
  void _showAvatarSelectionBottomSheet(String userUid, String currentAvatarId) {
    final avatars = [
      {'id': 'avatar_student', 'name': 'طالب العلم', 'desc': 'السعي الدؤوب لتحصيل المعرفة'},
      {'id': 'avatar_book', 'name': 'القارئ المتدبر', 'desc': 'الغوص في بطون المجلدات والكتب'},
      {'id': 'avatar_beacon', 'name': 'منارة التوجيه', 'desc': 'إرشاد الآخرين ونشر المعالم'},
      {'id': 'avatar_star', 'name': 'النجم اللامع', 'desc': 'بروز التميز والمهارة اللامعة'},
      {'id': 'avatar_shield', 'name': 'حامي العقيدة', 'desc': 'الدفاع عن الدين والسنن'},
      {'id': 'avatar_light', 'name': 'مصباح المعرفة', 'desc': 'نور ينير ظلمات الجهل'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                Text(
                  'اختر صورتك الشخصية الرمزية',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF0F172A),
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: avatars.length,
                    separatorBuilder: (itemCtx, index) => const SizedBox(height: 10.0),
                    itemBuilder: (itemCtx, index) {
                      final av = avatars[index];
                      final id = av['id']!;
                      final name = av['name']!;
                      final desc = av['desc']!;
                      final color = _getAvatarColor(id);
                      final isSelected = id == currentAvatarId;

                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.04) : Colors.white,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(
                            color: isSelected ? color : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            Navigator.pop(sheetContext); // Pop the bottom sheet safely
                            
                            // Show loading indicator
                            showDialog(
                              context: context, // Use outer context
                              barrierDismissible: false,
                              builder: (dialogCtx) => const Center(
                                child: CircularProgressIndicator(color: Color(0xFF00AFA3)),
                              ),
                            );

                            try {
                              await _firestore.collection('users').doc(userUid).update({'avatar': id});
                              if (mounted) {
                                Navigator.pop(context); // Pop dialog loader using outer context
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'تم تغيير الصورة الرمزية إلى $name بنجاح',
                                          style: GoogleFonts.cairo(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 18.0),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF00AFA3),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                Navigator.pop(context); // Pop dialog loader using outer context
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('حدث خطأ أثناء التحديث، يرجى المحاولة لاحقاً.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          leading: isSelected
                              ? Icon(Icons.check_circle_rounded, color: color, size: 20.0)
                              : null,
                          title: Text(
                            name,
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF0F172A),
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          subtitle: Text(
                            desc,
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF64748B),
                              fontSize: 10.5,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getAvatarIcon(id),
                              color: color,
                              size: 20.0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Win Rate Analytics Card widget
  Widget _buildAnalyticalCard(int wins, int losses, double winRate, int winRatePercent) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.015),
            blurRadius: 8.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'أداء المنافسات الثنائية',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF0F172A),
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'لقد خضت ${wins + losses} مواجهات حاسمة بالأسئلة الفورية ضد أقرانك من طلاب العلم.',
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
          
          // Win Rate Circle Gauge
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
    );
  }

  // Bento Stats Grid (2x2)
  Widget _buildBentoGrid(int points, int wins, int losses, int streak) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.0,
      childAspectRatio: 2.1,
      children: [
        _buildProfileBentoItem('مجموع النقاط', '$points ن', Icons.star_rounded, const Color(0xFF2563EB)),
        _buildProfileBentoItem('الانتصارات', '$wins فوز', Icons.flash_on_rounded, const Color(0xFF10B981)),
        _buildProfileBentoItem('الخسارات', '$losses خسارة', Icons.heart_broken_rounded, const Color(0xFFEF4444)),
        _buildProfileBentoItem('التتابع اليومي', '$streak يوم', Icons.local_fire_department_rounded, const Color(0xFFEC4899)),
      ],
    );
  }

  // Bento Item Card
  Widget _buildProfileBentoItem(String title, String value, IconData icon, Color color) {
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

  // Badges Grid
  Widget _buildBadgesGrid(int points, int wins, int streak, List<BadgeModel> badges) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isUnlocked = badge.isUnlocked(points, wins, streak);

        return GestureDetector(
          onTap: () => _showBadgeDetailBottomSheet(badge, points, wins, streak),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isUnlocked ? badge.color.withOpacity(0.12) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isUnlocked ? badge.color : const Color(0xFFE2E8F0),
                        width: isUnlocked ? 1.5 : 1.0,
                      ),
                    ),
                    child: Icon(
                      badge.icon,
                      color: isUnlocked ? badge.color : const Color(0xFF94A3B8),
                      size: 20.0,
                    ),
                  ),
                  if (!isUnlocked)
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
                  color: isUnlocked ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                  fontSize: 9.5,
                  fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  // Badge Details Sheet
  void _showBadgeDetailBottomSheet(BadgeModel badge, int points, int wins, int streak) {
    final isUnlocked = badge.isUnlocked(points, wins, streak);
    final progress = badge.progress(points, wins, streak);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 38.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Large badge icon
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isUnlocked ? badge.color.withOpacity(0.1) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isUnlocked ? badge.color : const Color(0xFFE2E8F0),
                      width: 2.5,
                    ),
                  ),
                  child: Icon(
                    badge.icon,
                    color: isUnlocked ? badge.color : const Color(0xFF64748B),
                    size: 40.0,
                  ),
                ),
                const SizedBox(height: 12.0),

                // Title & status tag
                Text(
                  badge.title,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF0F172A),
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: isUnlocked ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(100.0),
                  ),
                  child: Text(
                    isUnlocked ? 'الوسام مفعّل ومكتمل 🎉' : 'الوسام مقفل ومحجوب 🔒',
                    style: GoogleFonts.cairo(
                      color: isUnlocked ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

                // Description
                Text(
                  badge.description,
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF64748B),
                    fontSize: 13.0,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),

                // Progress Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      badge.progressLabel,
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF00AFA3),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'مؤشر التقدم',
                      style: GoogleFonts.cairo(
                        color: const Color(0xFF64748B),
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8.0,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(badge.color),
                  ),
                ),
                const SizedBox(height: 15.0),
              ],
            ),
          ),
        );
      },
    );
  }

  // Quick settings and actions list
  Widget _buildQuickActionsList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
      ),
      child: Column(
        children: [
          // Share
          _buildActionItem(
            icon: Icons.share_rounded,
            iconColor: const Color(0xFF00AFA3),
            title: 'مشاركة التطبيق',
            subtitle: 'انشر المعرفة الإسلامية بين أصدقائك وعائلتك',
            onTap: () {
              HapticFeedback.lightImpact();
              // Simulating Share
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'تم نسخ رابط تحميل تطبيق منار الهدى للمشاركة!',
                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  backgroundColor: const Color(0xFF00AFA3),
                ),
              );
            },
          ),
          const Divider(height: 1.0, color: Color(0xFFE2E8F0)),

          // Rate
          _buildActionItem(
            icon: Icons.star_rate_rounded,
            iconColor: const Color(0xFFF59E0B),
            title: 'تقييم التطبيق على المتجر',
            subtitle: 'قيمنا بخمس نجوم لندعم المزيد من التحديثات',
            onTap: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'شكراً لتقييمك ودعمك المبارك لتطبيق منار الهدى!',
                    style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                  backgroundColor: const Color(0xFF00AFA3),
                ),
              );
            },
          ),
          const Divider(height: 1.0, color: Color(0xFFE2E8F0)),

          // Logout
          _buildActionItem(
            icon: Icons.logout_rounded,
            iconColor: const Color(0xFFEF4444),
            title: 'تسجيل الخروج',
            subtitle: 'الخروج بأمان من هذا الحساب حالياً',
            titleColor: const Color(0xFFEF4444),
            onTap: () async {
              HapticFeedback.mediumImpact();
              await _firebaseService.logout();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تم تسجيل الخروج بنجاح',
                      style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                    backgroundColor: const Color(0xFF00AFA3),
                  ),
                );
              }
            },
          ),
          const Divider(height: 1.0, color: Color(0xFFE2E8F0)),

          // Delete Account (Required by Apple Guidelines)
          _buildActionItem(
            icon: Icons.delete_forever_rounded,
            iconColor: const Color(0xFFDC2626),
            title: 'حذف الحساب نهائياً',
            subtitle: 'إزالة كامل بياناتك وسجلاتك وفق سياسة حماية البيانات',
            titleColor: const Color(0xFFDC2626),
            onTap: () {
              HapticFeedback.heavyImpact();
              _showDeleteAccountDialog(context);
            },
          ),
        ],
      ),
    );
  }

  // Delete Account Confirmation Dialog (Apple Store Guidelines Compliance)
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'حذف الحساب نهائياً',
                style: GoogleFonts.cairo(
                  color: const Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(width: 8.0),
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24.0),
            ],
          ),
          content: Text(
            'هل أنت متأكد من أنك تريد حذف حسابك نهائياً؟ سيتم مسح كافة سجلاتك ونقاطك وأوسمتك من تطبيق منار الهدى ولا يمكن استرجاع الحساب بعد ذلك.',
            style: GoogleFonts.cairo(
              color: const Color(0xFF475569),
              fontSize: 13.0,
              height: 1.5,
            ),
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(color: Color(0xFFDC2626)),
                  ),
                );

                try {
                  await _firebaseService.deleteAccount();
                  if (context.mounted) {
                    Navigator.pop(context); // Pop loading dialog
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context); // Pop Profile screen if pushed
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم حذف الحساب وجميع البيانات نهائياً',
                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                        backgroundColor: const Color(0xFFDC2626),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context); // Pop loading dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'لأسباب أمنية من أبل وFirebase، يتطلب حذف الحساب إعادة تسجيل الدخول أولاً.',
                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'تأكيد الحذف النهائي',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }


  // Quick Action List Tile Builder
  Widget _buildActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color titleColor = const Color(0xFF0F172A),
  }) {
    return ListTile(
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      leading: const Icon(Icons.arrow_back_ios_new_rounded, size: 14.0, color: Color(0xFF94A3B8)),
      title: Text(
        title,
        style: GoogleFonts.cairo(
          color: titleColor,
          fontSize: 13.0,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.right,
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.cairo(
          color: const Color(0xFF64748B),
          fontSize: 10.5,
        ),
        textAlign: TextAlign.right,
      ),
      trailing: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 18.0),
      ),
    );
  }

  List<BadgeModel> _getBadgesList(int points, int wins, int streak) {
    return [
      BadgeModel(
        id: 'badge_welcome',
        title: 'وسام طلب العلم',
        description: 'بداية الرحلة المباركة في طلب العلم الإسلامي وتثبيت العقيدة.',
        icon: Icons.auto_stories_rounded,
        color: const Color(0xFF14B8A6), // Teal
        isUnlocked: (p, w, s) => true,
        progress: (p, w, s) => 1.0,
        progressLabel: 'مكتمل بنجاح 🎉',
      ),
      BadgeModel(
        id: 'badge_first_win',
        title: 'فارس المواجهة',
        description: 'تحقيق أول انتصار في مبارزة المعرفة الثنائية أونلاين.',
        icon: Icons.flash_on_rounded,
        color: const Color(0xFFD97706), // Amber
        isUnlocked: (p, w, s) => w >= 1,
        progress: (p, w, s) => w >= 1 ? 1.0 : 0.0,
        progressLabel: 'الانتصارات: $wins / 1',
      ),
      BadgeModel(
        id: 'badge_five_wins',
        title: 'المبارز المغوار',
        description: 'إظهار شجاعة علمية والفوز في 5 مبارزات ثنائية أونلاين.',
        icon: Icons.military_tech_rounded,
        color: const Color(0xFFEC4899), // Pink
        isUnlocked: (p, w, s) => w >= 5,
        progress: (p, w, s) => (w / 5.0).clamp(0.0, 1.0),
        progressLabel: 'الانتصارات: $wins / 5',
      ),
      BadgeModel(
        id: 'badge_streak_3',
        title: 'المواظب العنيد',
        description: 'المحافظة على المذاكرة والتعلم لتتابع يومي لمدة 3 أيام متتالية.',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFEF4444), // Red
        isUnlocked: (p, w, s) => s >= 3,
        progress: (p, w, s) => (s / 3.0).clamp(0.0, 1.0),
        progressLabel: 'أيام التتابع: $streak / 3',
      ),
      BadgeModel(
        id: 'badge_streak_7',
        title: 'المنارة الذهبية',
        description: 'المواظبة والاستمرارية في طلب العلم لتتابع يومي لمدة 7 أيام متتالية.',
        icon: Icons.explore_rounded,
        color: const Color(0xFF8B5CF6), // Purple
        isUnlocked: (p, w, s) => s >= 7,
        progress: (p, w, s) => (s / 7.0).clamp(0.0, 1.0),
        progressLabel: 'أيام التتابع: $streak / 7',
      ),
      BadgeModel(
        id: 'badge_points_200',
        title: 'قارئ النور',
        description: 'جمع ما يزيد على 200 نقطة إجمالية من خلال حل اختبارات التطبيق.',
        icon: Icons.star_rounded,
        color: const Color(0xFF2563EB), // Blue
        isUnlocked: (p, w, s) => p >= 200,
        progress: (p, w, s) => (p / 200.0).clamp(0.0, 1.0),
        progressLabel: 'النقاط: $points / 200',
      ),
      BadgeModel(
        id: 'badge_points_500',
        title: 'حامي العقيدة',
        description: 'جمع ما يزيد على 500 نقطة إجمالية وتثبيت المعرفة الدينية.',
        icon: Icons.shield_rounded,
        color: const Color(0xFF10B981), // Emerald
        isUnlocked: (p, w, s) => p >= 500,
        progress: (p, w, s) => (p / 500.0).clamp(0.0, 1.0),
        progressLabel: 'النقاط: $points / 500',
      ),
      BadgeModel(
        id: 'badge_points_1000',
        title: 'المفكر الأكبر',
        description: 'بلوغ قمة الصدارة وجمع 1000 نقطة إجمالية في منارة الهدى.',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFF59E0B), // Golden Trophy
        isUnlocked: (p, w, s) => p >= 1000,
        progress: (p, w, s) => (p / 1000.0).clamp(0.0, 1.0),
        progressLabel: 'النقاط: $points / 1000',
      ),
    ];
  }
}

class BadgeModel {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool Function(int points, int wins, int streak) isUnlocked;
  final double Function(int points, int wins, int streak) progress;
  final String progressLabel;

  BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.progress,
    required this.progressLabel,
  });
}
