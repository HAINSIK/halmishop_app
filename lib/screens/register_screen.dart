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
  final _codeController = TextEditingController();

  bool _isLoading = false;
  bool _isSendingCode = false;
  bool _isPhoneVerified = false;
  String? _verificationToken;
  String? _verificationRequestedPhone;

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
      _isPhoneVerified = false;
      _verificationToken = null;
      _verificationRequestedPhone = null;
    });

    final success = await _authService.requestPhoneVerification(phone);

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

    // 인증번호를 발송한 전화번호와 현재 번호가 같은지 확인
    if (_verificationRequestedPhone == null ||
        _verificationRequestedPhone != phone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('휴대폰 번호가 변경되었습니다. 인증번호를 다시 발송해주세요.')),
      );
      return;
    }

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('인증번호 6자리를 입력해주세요.')));
      return;
    }

    setState(() => _isLoading = true);

    final token = await _authService.confirmPhoneVerification(phone, code);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    // 휴대폰 인증 완료 여부 확인
    if (!_isPhoneVerified ||
        _verificationToken == null ||
        _verificationToken!.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('휴대폰 인증을 먼저 완료해주세요.')));
      return;
    }

    setState(() => _isLoading = true);

    final request = RegisterRequest(
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      verificationToken: _verificationToken!,
    );

    final success = await _authService.register(request);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('젊은할미반찬가게 회원이 되신 것을 환영합니다! 🎉')),
      );

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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            enabled: !_isSendingCode && !_isLoading,
                            decoration: const InputDecoration(
                              labelText: '전화번호 (아이디)',
                              hintText: '01012345678',
                            ),
                            onChanged: (_) {
                              setState(() {
                                _isPhoneVerified = false;
                                _verificationToken = null;
                                _verificationRequestedPhone = null;
                                _codeController.clear();
                              });
                            },
                            validator: (v) => v == null || v.trim().isEmpty
                                ? '전화번호를 입력하세요.'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSendingCode
                              ? null
                              : _sendVerificationCode,
                          child: Text(_isSendingCode ? '발송 중...' : '인증번호 발송'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: InputDecoration(
                              labelText: 'SMS 인증번호',
                              hintText: '인증번호 6자리',
                              counterText: '',
                              suffixIcon: _isPhoneVerified
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed:
                              _isPhoneVerified || _isSendingCode || _isLoading
                              ? null
                              : _confirmVerificationCode,
                          child: const Text('인증 확인'),
                        ),
                      ],
                    ),

                    if (_isPhoneVerified)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          '휴대폰 인증이 완료되었습니다.',
                          style: TextStyle(color: Colors.green),
                        ),
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
                      onPressed:
                          (_isLoading || _isSendingCode || !_isPhoneVerified)
                          ? null
                          : _handleRegister,
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
