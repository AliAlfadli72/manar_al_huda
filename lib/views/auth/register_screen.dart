import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/firebase_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Selected avatar
  String _selectedAvatar = 'avatar_student';

  // List of avatars with icons and colors
  static const List<Map<String, dynamic>> _avatarList = [
    {
      'id': 'avatar_student',
      'icon': Icons.school_rounded,
      'color': Color(0xFF2DD4BF), // Teal
      'label': 'طالب العلم',
    },
    {
      'id': 'avatar_book',
      'icon': Icons.menu_book_rounded,
      'color': Color(0xFFF59E0B), // Gold
      'label': 'المتدبر',
    },
    {
      'id': 'avatar_beacon',
      'icon': Icons.wb_sunny_rounded,
      'color': Color(0xFFEC4899), // Pink/Rose
      'label': 'المنارة',
    },
    {
      'id': 'avatar_star',
      'icon': Icons.star_rounded,
      'color': Color(0xFF3B82F6), // Blue
      'label': 'النجم',
    },
    {
      'id': 'avatar_shield',
      'icon': Icons.verified_user_rounded,
      'color': Color(0xFF10B981), // Emerald Green
      'label': 'الفارس',
    },
    {
      'id': 'avatar_light',
      'icon': Icons.tips_and_updates_rounded,
      'color': Color(0xFF8B5CF6), // Purple
      'label': 'المصباح',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _firebaseService.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        name: _nameController.text,
        avatar: _selectedAvatar,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'أهلاً بك يا ${_nameController.text}! تم إنشاء حسابك بنجاح',
              style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold),
              textAlign: TextAlign.right,
            ),
            backgroundColor: const Color(0xFF00AFA3), // Soft Electric Teal
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء التسجيل. قد يكون البريد الإلكتروني مستخدماً بالفعل.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Heading
                  Text(
                    'إنشاء حساب جديد',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF0F172A), // Rich Navy Title
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'احفظ إنجازاتك وتنافس مع الآخرين أونلاين',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF64748B),
                      fontSize: 14.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20.0),

                  // Avatar Selection
                  Text(
                    'اختر شخصيتك الرمزية (الـ Avatar)',
                    style: GoogleFonts.cairo(
                      color: const Color(0xFF00AFA3), // Soft Electric Teal
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 10.0),
                  
                  // Avatar Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                    ),
                    itemCount: _avatarList.length,
                    itemBuilder: (context, index) {
                      final item = _avatarList[index];
                      final isSelected = _selectedAvatar == item['id'];

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedAvatar = item['id'] as String;
                          });
                        },
                        child: AnimatedContainer(
                          duration: 200.ms,
                          decoration: BoxDecoration(
                            color: isSelected ? (item['color'] as Color).withOpacity(0.15) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? (item['color'] as Color) : const Color(0xFFE2E8F0),
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.02),
                                blurRadius: 6.0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            color: isSelected ? (item['color'] as Color) : const Color(0xFF94A3B8),
                            size: 24.0,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24.0),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: const Color(0xFFEF4444), width: 1.0),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.cairo(color: const Color(0xFF7F1D1D), fontSize: 13.0, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],

                  // Display Name Field
                  TextFormField(
                    controller: _nameController,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(color: const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'الاسم الكريم',
                      hintStyle: GoogleFonts.cairo(color: const Color(0xFF64748B)),
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF00AFA3)),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(color: Color(0xFF00AFA3), width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      ),
                      errorStyle: GoogleFonts.cairo(color: const Color(0xFFEF4444)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال اسمك الكريم';
                      }
                      if (value.length < 3) {
                        return 'الاسم يجب ألا يقل عن 3 أحرف';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(color: const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'البريد الإلكتروني',
                      hintStyle: GoogleFonts.cairo(color: const Color(0xFF64748B)),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF00AFA3)),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(color: Color(0xFF00AFA3), width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      ),
                      errorStyle: GoogleFonts.cairo(color: const Color(0xFFEF4444)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'يرجى إدخال البريد الإلكتروني';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'يرجى إدخال بريد إلكتروني صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(color: const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'كلمة المرور',
                      hintStyle: GoogleFonts.cairo(color: const Color(0xFF64748B)),
                      prefixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF00AFA3),
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(color: Color(0xFF00AFA3), width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      ),
                      errorStyle: GoogleFonts.cairo(color: const Color(0xFFEF4444)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال كلمة المرور';
                      }
                      if (value.length < 6) {
                        return 'كلمة المرور يجب ألا تقل عن 6 أحرف';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30.0),

                  // Register Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00AFA3),
                      disabledBackgroundColor: const Color(0xFF00AFA3).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20.0,
                            width: 20.0,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
                          )
                        : Text(
                            'إنشاء حساب',
                            style: GoogleFonts.cairo(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20.0),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        child: Text(
                          'سجل دخولك',
                          style: GoogleFonts.cairo(
                            color: const Color(0xFF00AFA3),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'لديك حساب بالفعل؟',
                        style: GoogleFonts.cairo(color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
