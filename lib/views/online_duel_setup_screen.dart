import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'auth/login_screen.dart';
import 'online_duel_play_screen.dart';

class OnlineDuelSetupScreen extends StatefulWidget {
  const OnlineDuelSetupScreen({super.key});

  @override
  State<OnlineDuelSetupScreen> createState() => _OnlineDuelSetupScreenState();
}

class _OnlineDuelSetupScreenState extends State<OnlineDuelSetupScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _codeController = TextEditingController();
  final _joinFormKey = GlobalKey<FormState>();

  bool _isCreatingRoom = false;
  bool _isJoiningRoom = false;
  String? _createdRoomCode;
  String? _selectedCategory;

  // Categories list matching standard ones
  final List<Map<String, dynamic>> _categories = [
    {'id': 'quran', 'name': 'علوم القرآن', 'icon': Icons.book, 'color': const Color(0xFF00AFA3)}, // Soft Electric Teal
    {'id': 'aqeedah', 'name': 'العقيدة الإسلامية', 'icon': Icons.shield, 'color': const Color(0xFF2563EB)}, // Sapphire
    {'id': 'fiqh', 'name': 'الفقه الميسر', 'icon': Icons.gavel, 'color': const Color(0xFF10B981)}, // Green
    {'id': 'hadith', 'name': 'الحديث النبوي', 'icon': Icons.message_rounded, 'color': const Color(0xFFEC4899)}, // Pink
    {'id': 'seerah', 'name': 'السيرة والتاريخ', 'icon': Icons.explore_rounded, 'color': const Color(0xFF8B5CF6)}, // Purple
  ];

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateRoom(String categoryId) async {
    setState(() {
      _isCreatingRoom = true;
      _selectedCategory = categoryId;
    });

    try {
      final String code = await _firebaseService.createDuelRoom(categoryId);
      if (!mounted) return;
      setState(() {
        _createdRoomCode = code;
        _isCreatingRoom = false;
      });

      // Listen to the created room stream. When a joiner joins, transition.
      _listenToRoomState(code);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreatingRoom = false;
        _selectedCategory = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception:', '').trim(),
            style: GoogleFonts.cairo(color: Colors.white),
            textAlign: TextAlign.right,
          ),
          backgroundColor: Colors.red.shade900,
        ),
      );
    }
  }

  void _listenToRoomState(String code) {
    _firebaseService.streamDuelRoom(code).listen((doc) {
      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data()!;
        if (data['joinerUid'] != null && data['status'] == 'playing') {
          // A second player has joined! Navigate to play screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OnlineDuelPlayScreen(
                roomId: code,
                isCreator: true,
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> _handleJoinRoom() async {
    if (!_joinFormKey.currentState!.validate()) return;

    setState(() {
      _isJoiningRoom = true;
    });

    final String roomCode = _codeController.text.trim();

    try {
      await _firebaseService.joinDuelRoom(roomCode);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OnlineDuelPlayScreen(
              roomId: roomCode,
              isCreator: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isJoiningRoom = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception:', '').trim(),
            style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
          backgroundColor: Colors.red.shade900,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _firebaseService.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFFFF), // Clean Neutral White
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00AFA3)), // Chevron Back
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 80.0, color: Color(0xFF00AFA3)),
                const SizedBox(height: 20.0),
                Text(
                  'يتطلب تسجيل الدخول للتحدي أونلاين',
                  style: GoogleFonts.cairo(color: const Color(0xFF00AFA3), fontSize: 20.0, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10.0),
                Text(
                  'يرجى إنشاء حساب أو تسجيل الدخول لحفظ تقدمك ومبارزة أصدقائك عبر الإنترنت.',
                  style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 14.5, height: 1.5),
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
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 14.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                    elevation: 0,
                  ),
                  child: Text(
                    'تسجيل الدخول',
                    style: GoogleFonts.cairo(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If waiting for challenger in a created room
    if (_createdRoomCode != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFFFF), // Clean Neutral White
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00AFA3)), // Chevron Back
            onPressed: () {
              // Delete the room if the creator backs out
              FirebaseFirestore.instance.collection('duels').doc(_createdRoomCode).delete();
              setState(() {
                _createdRoomCode = null;
                _selectedCategory = null;
              });
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF00AFA3)),
                const SizedBox(height: 30.0),
                Text(
                  'تم إنشاء غرفة التحدي بنجاح!',
                  style: GoogleFonts.cairo(color: const Color(0xFF00AFA3), fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'شارك هذا الرمز مع صديقك للانضمام:',
                  style: GoogleFonts.cairo(color: const Color(0xFF64748B), fontSize: 14.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20.0),

                // Room Code Display Card
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _createdRoomCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'تم نسخ رمز الغرفة إلى الحافظة',
                          style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                        backgroundColor: const Color(0xFF00AFA3),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: const Color(0xFF00AFA3), width: 1.5), // Soft Electric Teal
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00AFA3).withOpacity(0.02),
                          blurRadius: 12.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded, color: Color(0xFF00AFA3), size: 24.0),
                        const SizedBox(width: 14.0),
                        Text(
                          _createdRoomCode!,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF00AFA3),
                            fontSize: 34.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40.0),
                Text(
                  'بانتظار انضمام منافسك للبدء...',
                  style: GoogleFonts.cairo(
                    color: const Color(0xFF00AFA3),
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1500.ms, color: const Color(0xFF00AFA3)),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF), // Clean Neutral White
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF00AFA3)), // Chevron Back
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'مبارزة المعرفة أونلاين',
            style: GoogleFonts.cairo(color: const Color(0xFF0F172A), fontSize: 20.0, fontWeight: FontWeight.bold), // Navy Title
          ),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: const Color(0xFF00AFA3),
            labelColor: const Color(0xFF00AFA3),
            unselectedLabelColor: const Color(0xFF64748B),
            labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14.0),
            tabs: const [
              Tab(text: 'إنشاء تحدٍ'),
              Tab(text: 'انضمام لتحدٍ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Create Duel Room
            _buildCreateTab(),
            // Tab 2: Join Duel Room
            _buildJoinTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'اختر تصنيف الأسئلة للتحدي:',
            style: GoogleFonts.cairo(
              color: const Color(0xFF00AFA3), // Soft Electric Teal
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 16.0),

          // Categories Grid
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12.0),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isCreatingThis = _isCreatingRoom && _selectedCategory == cat['id'];

              return GestureDetector(
                onTap: _isCreatingRoom ? null : () => _handleCreateRoom(cat['id'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.02),
                        blurRadius: 8.0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (isCreatingThis)
                        const SizedBox(
                          height: 20.0,
                          width: 20.0,
                          child: CircularProgressIndicator(color: Color(0xFF00AFA3), strokeWidth: 2.0),
                        )
                      else
                        const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF64748B), size: 16.0),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            cat['name'] as String,
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF0F172A),
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '5 أسئلة للمنافسة المباشرة',
                            style: GoogleFonts.cairo(
                              color: const Color(0xFF64748B),
                              fontSize: 11.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16.0),
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: (cat['color'] as Color).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cat['icon'] as IconData,
                          color: cat['color'] as Color,
                          size: 24.0,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildJoinTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _joinFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'أدخل رمز الغرفة المكون من 6 أرقام للبدء:',
              style: GoogleFonts.cairo(
                color: const Color(0xFF00AFA3), // Soft Electric Teal
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),

            // Code Entry Field
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontSize: 26.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 8.0,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: GoogleFonts.outfit(color: const Color(0xFFCBD5E1), letterSpacing: 8.0),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Color(0xFF00AFA3), width: 1.5), // Soft Electric Teal
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                ),
                errorStyle: GoogleFonts.cairo(color: const Color(0xFFEF4444)),
              ),
              validator: (value) {
                if (value == null || value.trim().length != 6) {
                  return 'يرجى إدخال الرمز المكون من 6 أرقام';
                }
                return null;
              },
            ),
            const SizedBox(height: 30.0),

            // Join Button
            ElevatedButton(
              onPressed: _isJoiningRoom ? null : _handleJoinRoom,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AFA3), // Soft Electric Teal
                disabledBackgroundColor: const Color(0xFF00AFA3).withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                elevation: 0,
              ),
              child: _isJoiningRoom
                  ? const SizedBox(
                      height: 20.0,
                      width: 20.0,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                    )
                  : Text(
                      'دخول التحدي',
                      style: GoogleFonts.cairo(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
