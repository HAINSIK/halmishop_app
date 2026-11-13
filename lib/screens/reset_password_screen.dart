import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _authService = AuthService();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSendingCode = false;
  bool _isVerifyingCode = false;
  bool _isPhoneVerified = false;
  bool _isResettingPassword = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _verificationRequestedPhone;
  String? _verificationToken;

  bool get _isBusy =>
      _isSendingCode || _isVerifyingCode || _isResettingPassword;

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearVerification() {
    _isPhoneVerified = false;
    _verificationToken = null;
    _verificationRequestedPhone = null;
    _codeController.clear();
  }

  Future<void> _sendVerificationCode() async {
    if (_isBusy) return;
    final phone = _phoneController.text.trim();
    if (!RegExp(r'^01[016789]\d{7,8}$').hasMatch(phone)) {
      _message('휴대폰 번호를 숫자 10~11자리로 입력해주세요.');
      return;
    }

    setState(() {
      _clearVerification();
      _isSendingCode = true;
    });

    bool success;
    try {
      success = await _authService.requestPhoneVerification(
        phone,
        purpose: 'RESET_PASSWORD',
      );
    } catch (_) {
      success = false;
    }
    if (!mounted) return;

    setState(() {
      _isSendingCode = false;
      _verificationRequestedPhone =
          success && _phoneController.text.trim() == phone ? phone : null;
    });
    _message(success ? '인증번호를 문자로 발송했습니다.' : '인증번호 발송에 실패했습니다.');
  }

  Future<void> _confirmVerificationCode() async {
    if (_isBusy || _isPhoneVerified) return;
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    if (_verificationRequestedPhone != phone ||
        _verificationRequestedPhone == null) {
      _message('인증번호를 먼저 발송해주세요.');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _message('인증번호 6자리를 입력해주세요.');
      return;
    }

    setState(() => _isVerifyingCode = true);
    String? token;
    try {
      token = await _authService.confirmPhoneVerification(
        phone,
        code,
        purpose: 'RESET_PASSWORD',
      );
    } catch (_) {
      token = null;
    }
    if (!mounted) return;

    setState(() {
      _isVerifyingCode = false;
      if (_phoneController.text.trim() == phone &&
          _verificationRequestedPhone == phone) {
        _verificationToken = token;
        _isPhoneVerified = token != null && token.isNotEmpty;
      } else {
        _clearVerification();
      }
    });
    _message(_isPhoneVerified ? '휴대폰 인증이 완료되었습니다.' : '인증번호가 올바르지 않거나 만료되었습니다.');
  }

  Future<void> _handleResetPassword() async {
    if (_isBusy) return;
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (!_isPhoneVerified ||
        _verificationToken == null ||
        _verificationRequestedPhone != phone) {
      _message('휴대폰 인증을 먼저 완료해주세요.');
      return;
    }
    if (password.isEmpty || confirmPassword.isEmpty) {
      _message('새 비밀번호를 입력해주세요.');
      return;
    }
    if (password != confirmPassword) {
      _message('새 비밀번호가 서로 일치하지 않습니다.');
      return;
    }

    setState(() => _isResettingPassword = true);
    bool success;
    try {
      success = await _authService.resetPassword(
        phoneNumber: phone,
        newPassword: password,
        verificationToken: _verificationToken!,
      );
    } catch (_) {
      success = false;
    }
    if (!mounted) return;
    setState(() => _isResettingPassword = false);

    if (success) {
      _message('비밀번호가 변경되었습니다. 다시 로그인해주세요.');
      Navigator.pop(context);
    } else {
      _message('비밀번호 변경에 실패했습니다. 인증 상태를 확인해주세요.');
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        color: Color(0xFF244C3A),
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
      prefixIcon: Icon(icon, color: const Color(0xFF777777)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2DED6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF244C3A), width: 1.7),
      ),
    );
  }

  Widget _smallButton({
    required String text,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF47B08),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFF5C18C),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
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
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F4E9),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        title: const Text(
          '비밀번호 재설정',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF244C3A),
          ),
        ),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF244C3A),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/register/register_background.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.manual,
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                  16,
                  40 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/images/characters/halmi_login_brand_fixed.png',
                        width: 190,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '휴대폰 인증으로 비밀번호 재설정',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF244C3A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '가입하신 휴대폰 번호로 인증한 후\n새 비밀번호를 설정할 수 있습니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF777777)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            enabled: !_isBusy && !_isPhoneVerified,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (value) {
                              if (_verificationRequestedPhone != value.trim()) {
                                setState(_clearVerification);
                              }
                            },
                            decoration: _fieldDecoration(
                              label: '전화번호 (아이디)',
                              hint: '01012345678',
                              icon: Icons.phone_android_outlined,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _smallButton(
                          text: _isSendingCode ? '발송 중...' : '인증번호 발송',
                          onPressed: _isBusy ? null : _sendVerificationCode,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            enabled: !_isBusy && !_isPhoneVerified,
                            decoration: _fieldDecoration(
                              label: 'SMS 인증번호',
                              hint: '6자리 입력',
                              icon: Icons.sms_outlined,
                              suffixIcon: _isPhoneVerified
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF244C3A),
                                    )
                                  : null,
                            ).copyWith(counterText: ''),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _smallButton(
                          text: _isVerifyingCode ? '확인 중...' : '인증 확인',
                          onPressed:
                              _isBusy ||
                                  _isPhoneVerified ||
                                  _verificationRequestedPhone == null
                              ? null
                              : _confirmVerificationCode,
                        ),
                      ],
                    ),
                    if (_isPhoneVerified)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: Color(0xFF244C3A),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '휴대폰 인증이 완료되었습니다.',
                              style: TextStyle(color: Color(0xFF244C3A)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      enabled: !_isResettingPassword,
                      decoration: _fieldDecoration(
                        label: '새 비밀번호',
                        hint: '새 비밀번호를 입력해주세요',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      enabled: !_isResettingPassword,
                      decoration: _fieldDecoration(
                        label: '새 비밀번호 확인',
                        hint: '새 비밀번호를 다시 입력해주세요',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                          icon: Icon(
                            _showConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isPhoneVerified && !_isBusy
                            ? _handleResetPassword
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF47B08),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFF5C18C),
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _isResettingPassword ? '비밀번호 변경 중...' : '비밀번호 변경하기',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
