import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'main_feed_screen.dart'; // ◀ [필수] 메인 피드 화면을 정상 인식하도록 임포트 추가

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
      appBar: AppBar(
        title: const Text('젊은할미반찬가게 로그인'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: '전화번호'),
                      validator: (v) => v!.isEmpty ? '전화번호를 입력하세요.' : null,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: '비밀번호'),
                      validator: (v) => v!.isEmpty ? '비밀번호를 입력하세요.' : null,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('로그인', style: TextStyle(fontSize: 18)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text('아직 회원이 아니신가요? 회원가입하기'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
