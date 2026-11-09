import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _authService = AuthService();

  bool _isSendingCode = false;
  String? _verificationRequestedPhone;
  bool _isVerifyingCode = false;
  bool _isPhoneVerified = false;
  bool _isResettingPassword = false;
  String? _verificationToken;
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _sendVerificationCode() async {
    final phone = _phoneController.text.trim();

    if (!RegExp(r'^01[016789]\d{7,8}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('휴대폰 번호를 숫자 10~11자리로 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _isSendingCode = true;
      _verificationRequestedPhone = null;
    });

    final success = await _authService.requestPhoneVerification(
      phone,
      purpose: 'RESET_PASSWORD',
    );

    if (!mounted) return;

    setState(() {
      _isSendingCode = false;
      _verificationRequestedPhone = success ? phone : null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '인증번호를 문자로 발송했습니다.' : '인증번호 발송에 실패했습니다.'),
      ),
    );
  }

  Future<void> _confirmVerificationCode() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();

    if (_verificationRequestedPhone == null ||
        _verificationRequestedPhone != phone) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('인증번호를 먼저 발송해주세요.')));
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('인증번호 6자리를 입력해주세요.')));
      return;
    }

    setState(() => _isVerifyingCode = true);

    final token = await _authService.confirmPhoneVerification(
      phone,
      code,
      purpose: 'RESET_PASSWORD',
    );

    if (!mounted) return;

    setState(() {
      _isVerifyingCode = false;
      _verificationToken = token;
      _isPhoneVerified = token != null && token.isNotEmpty;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isPhoneVerified ? '휴대폰 인증이 완료되었습니다.' : '인증번호가 올바르지 않거나 만료되었습니다.',
        ),
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!_isPhoneVerified ||
        _verificationToken == null ||
        _verificationRequestedPhone != phone) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('휴대폰 인증을 먼저 완료해주세요.')));
      return;
    }

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('새 비밀번호를 입력해주세요.')));
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('새 비밀번호가 서로 일치하지 않습니다.')));
      return;
    }

    setState(() => _isResettingPassword = true);

    final success = await _authService.resetPassword(
      phoneNumber: phone,
      newPassword: password,
      verificationToken: _verificationToken!,
    );

    if (!mounted) return;

    setState(() => _isResettingPassword = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 변경되었습니다. 다시 로그인해주세요.')),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호 변경에 실패했습니다. 인증 상태를 확인해주세요.')),
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('비밀번호 찾기'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              '휴대폰 인증으로 비밀번호 재설정',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              '가입하신 휴대폰 번호로 인증한 후\n'
              '새로운 비밀번호를 설정할 수 있습니다.',
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !_isSendingCode && !_isVerifyingCode,
              onChanged: (value) {
                if (_verificationRequestedPhone != value.trim()) {
                  setState(() {
                    _isPhoneVerified = false;
                    _verificationToken = null;
                    _verificationRequestedPhone = null;
                    _codeController.clear();
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: '휴대폰 번호',
                hintText: '01012345678',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: _isSendingCode ? null : _sendVerificationCode,
              child: Text(_isSendingCode ? '발송 중...' : '인증번호 발송'),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'SMS 인증번호',
                border: OutlineInputBorder(),
              ),
            ),

            ElevatedButton(
              onPressed:
                  (_isSendingCode || _isVerifyingCode || _isPhoneVerified)
                  ? null
                  : _confirmVerificationCode,
              child: Text(_isVerifyingCode ? '확인 중...' : '인증번호 확인'),
            ),

            if (_isPhoneVerified)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('휴대폰 인증 완료', style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '새 비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '새 비밀번호 확인',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: (_isPhoneVerified && !_isResettingPassword)
                  ? _handleResetPassword
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(
                _isResettingPassword ? '비밀번호 변경 중...' : '비밀번호 변경하기',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
