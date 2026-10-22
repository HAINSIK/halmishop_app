import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  // 이메일 컨트롤러를 삭제하고 3개만 남깁니다.
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // [수정된 부분] 생성자에서 email을 제외하고 딱 3개의 필드만 넘겨줍니다.
    final request = RegisterRequest(
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );

    // 이제 모델 구조와 일치하므로 여기서 에러가 나지 않습니다.
    final success = await _authService.register(request);

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('젊은할미반찬가게 회원이 되신 것을 환영합니다! 🎉')),
      );
      // 회원가입 성공 후 자동으로 로그인 화면으로 돌아가기
      Navigator.pop(context); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('회원가입에 실패했습니다. 입력 정보를 확인해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('젊은할미반찬가게 회원가입'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // 전화번호, 이름, 비밀번호 입력 필드만 깔끔하게 유지
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: '전화번호 (아이디)'),
                      validator: (v) => v!.isEmpty ? '전화번호를 입력하세요.' : null,
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '이름'),
                      validator: (v) => v!.isEmpty ? '이름을 입력하세요.' : null,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: '비밀번호'),
                      validator: (v) => v!.isEmpty ? '비밀번호를 입력하세요.' : null,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('가입하기', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
