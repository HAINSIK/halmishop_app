import 'package:flutter/material.dart';

import '../notification_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';
import 'main_feed_screen.dart'; // ◀ [필수] 메인 피드 화면을 정상 인식하도록 임포트 추가

import 'package:provider/provider.dart';

import '../cart_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = LoginRequest(
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
    );

    final success = await _authService.login(request);

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;

      // 이전 회원의 장바구니가 화면에 남지 않도록 초기화
      final cartProvider = context.read<CartProvider>();
      cartProvider.clearCartForAccountChange();

      // 현재 로그인한 회원의 장바구니 복원
      await cartProvider.restoreCart();
      await AuthService().checkSavedTokenStatus();

      if (!mounted) return;

      // 로그인 성공 후 FCM 토큰을 서버에 등록
      NotificationService.registerToken();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('젊은할미반찬가게에 오신 것을 환영합니다! ❤️')),
      );

      // 로그인 성공 시 메인 피드 화면으로 깔끔하게 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainFeedScreen()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인에 실패했습니다. 정보를 다시 확인해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4E9),
      resizeToAvoidBottomInset: false,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: true,
              bottom: true,
              child: Stack(
                children: [
                  // 백그라운드 장식 이미지
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Image.asset(
                        'assets/images/login/login_background.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),

                  // 기존 로그인 화면
                  SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.manual,
                          padding: EdgeInsets.fromLTRB(
                            24,
                            24,
                            24,
                            24 + MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight > 48
                                  ? constraints.maxHeight - 48
                                  : 0,
                            ),
                            child: Align(
                              alignment: const Alignment(0, -0.35),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Transform.scale(
                                      scaleX: 1.25,
                                      child: Image.asset(
                                        'assets/images/characters/halmi_login_brand_fixed.png',
                                        height: 260,
                                        fit: BoxFit.contain,
                                      ),
                                    ),

                                    // const SizedBox(height: 1),

                                    // const Text(
                                    //   '젊은할미 반찬가게',
                                    //   style: TextStyle(
                                    //     fontSize: 28,
                                    //     fontWeight: FontWeight.w700,
                                    //     color: Color(0xFF244C3A),
                                    //   ),
                                    // ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      '정성 가득한 집밥, 오늘도 맛있게 준비했어요.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF777777),
                                      ),
                                    ),

                                    const SizedBox(height: 7),

                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,

                                      decoration: InputDecoration(
                                        hintText: '휴대폰 번호를 입력하세요',

                                        hintStyle: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF999999),
                                        ),

                                        prefixIcon: const Icon(
                                          Icons.phone_outlined,
                                          color: Color(0xFF6B625B),
                                          size: 21,
                                        ),

                                        filled: true,
                                        fillColor: Colors.white,

                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 18,
                                              horizontal: 16,
                                            ),

                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE5DED3),
                                            width: 1,
                                          ),
                                        ),

                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF244C3A),
                                            width: 1.5,
                                          ),
                                        ),

                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                          ),
                                        ),

                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),

                                      validator: (v) => v == null || v.isEmpty
                                          ? '전화번호를 입력하세요.'
                                          : null,
                                    ),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: !_isPasswordVisible,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) =>
                                          _isLoading ? null : _handleLogin(),

                                      decoration: InputDecoration(
                                        hintText: '비밀번호를 입력하세요',
                                        hintStyle: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF999999),
                                        ),

                                        prefixIcon: const Icon(
                                          Icons.lock_outline,
                                          color: Color(0xFF6B625B),
                                          size: 21,
                                        ),

                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: const Color(0xFF888888),
                                            size: 21,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible =
                                                  !_isPasswordVisible;
                                            });
                                          },
                                        ),

                                        filled: true,
                                        fillColor: Colors.white,

                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 18,
                                              horizontal: 16,
                                            ),

                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE5DED3),
                                          ),
                                        ),

                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF244C3A),
                                            width: 1.5,
                                          ),
                                        ),

                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                          ),
                                        ),

                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),

                                      validator: (v) => v == null || v.isEmpty
                                          ? '비밀번호를 입력하세요.'
                                          : null,
                                    ),
                                    const SizedBox(height: 15),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFF47B08,
                                          ),
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: const Color(
                                            0xFFFFB875,
                                          ),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          '로그인',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const RegisterScreen(),
                                            ),
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(
                                            0xFF56341E,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF56341E),
                                            width: 1.3,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          '회원가입',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 5),

                                    Center(
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const ResetPasswordScreen(),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF77695F,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                        child: const Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '비밀번호를 잊으셨나요?  ',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w400,
                                                  color: Color(0xFF77695F),
                                                ),
                                              ),
                                              TextSpan(
                                                text: '비밀번호 재설정',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF56341E),
                                                  decoration:
                                                      TextDecoration.underline,
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
  }
}
