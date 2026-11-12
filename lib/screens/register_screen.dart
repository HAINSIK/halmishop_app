import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _obscurePassword = true;
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
      resizeToAvoidBottomInset: false,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8F4E9),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),

        title: const Text(
          '회원가입',
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
        top: true,
        bottom: true,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 회원가입 전용 고정 배경
              Positioned.fill(
                child: Image.asset(
                  'assets/images/register/register_background.png',
                  fit: BoxFit.fill,
                  alignment: Alignment.center,
                ),
              ),

              // 기존 회원가입 화면
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.manual,

                      padding: EdgeInsets.fromLTRB(
                        16,
                        MediaQuery.of(context).padding.top +
                            kToolbarHeight +
                            16,
                        16,
                        40 + MediaQuery.of(context).viewInsets.bottom,
                      ),

                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const SizedBox(height: 8),

                            // 젊은할미 캐릭터 + 브랜드 로고
                            Center(
                              child: Image.asset(
                                'assets/images/characters/halmi_login_brand_fixed.png',
                                width: 190,
                                height: 200,
                                fit: BoxFit.contain,
                              ),
                            ),

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

                                      prefixIcon: Icon(
                                        Icons.phone_android_outlined,
                                        color: Color(0xFF777777),
                                      ),

                                      filled: true,
                                      fillColor: Colors.white,

                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 18,
                                      ),

                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(16),
                                        ),
                                      ),

                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(16),
                                        ),
                                        borderSide: BorderSide(
                                          color: Color(0xFFE2DED6),
                                        ),
                                      ),

                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(16),
                                        ),
                                        borderSide: BorderSide(
                                          color: Color(0xFF244C3A),
                                          width: 1.7,
                                        ),
                                      ),
                                    ),
                                    onChanged: (_) {
                                      setState(() {
                                        _isPhoneVerified = false;
                                        _verificationToken = null;
                                        _verificationRequestedPhone = null;
                                        _codeController.clear();
                                      });
                                    },
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? '전화번호를 입력하세요.'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _isSendingCode
                                      ? null
                                      : _sendVerificationCode,

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF47B08),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: const Color(
                                      0xFFF5C18C,
                                    ),
                                    disabledForegroundColor: Colors.white,

                                    elevation: 0,

                                    minimumSize: const Size(110, 56),

                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),

                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),

                                  child: Text(
                                    _isSendingCode ? '발송 중...' : '인증번호 발송',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: [
                                SizedBox(
                                  width: 165,
                                  child: TextFormField(
                                    controller: _codeController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    decoration: InputDecoration(
                                      labelText: 'SMS 인증번호',
                                      hintText: '6자리 입력',
                                      counterText: '',

                                      // 인증 완료 표시
                                      suffixIcon: _isPhoneVerified
                                          ? const Icon(
                                              Icons.check_circle,
                                              color: Color(0xFF244C3A),
                                            )
                                          : null,

                                      // 흰색 배경
                                      filled: true,
                                      fillColor: Colors.white,

                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 18,
                                          ),

                                      // 기본 테두리
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),

                                      // 평상시 테두리
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2DED6),
                                        ),
                                      ),

                                      // 입력 중 테두리
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF244C3A),
                                          width: 1.7,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed:
                                      _isPhoneVerified ||
                                          _isSendingCode ||
                                          _isLoading
                                      ? null
                                      : _confirmVerificationCode,

                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF47B08),
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: const Color(
                                      0xFFF5C18C,
                                    ),
                                    disabledForegroundColor: Colors.white,

                                    elevation: 0,

                                    minimumSize: const Size(100, 56),

                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),

                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),

                                  child: const Text(
                                    '인증 확인',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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

                            const SizedBox(height: 24),

                            TextFormField(
                              controller: _nameController,

                              decoration: InputDecoration(
                                labelText: '이름',
                                hintText: '이름을 입력해주세요',

                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,

                                labelStyle: const TextStyle(
                                  color: Color(0xFF244C3A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),

                                prefixIcon: const Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF777777),
                                ),

                                filled: true,
                                fillColor: Colors.white,

                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),

                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),

                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2DED6),
                                  ),
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF244C3A),
                                    width: 1.7,
                                  ),
                                ),
                              ),

                              validator: (v) =>
                                  v!.isEmpty ? '이름을 입력하세요.' : null,
                            ),

                            const SizedBox(height: 20),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,

                              decoration: InputDecoration(
                                labelText: '비밀번호',
                                hintText: '비밀번호를 입력해주세요',

                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,

                                labelStyle: const TextStyle(
                                  color: Color(0xFF244C3A),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),

                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: Color(0xFF777777),
                                ),

                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF777777),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),

                                filled: true,
                                fillColor: Colors.white,

                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 18,
                                ),

                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),

                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2DED6),
                                  ),
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF244C3A),
                                    width: 1.7,
                                  ),
                                ),
                              ),

                              validator: (v) =>
                                  v!.isEmpty ? '비밀번호를 입력하세요.' : null,
                            ),

                            const SizedBox(height: 40),

                            ElevatedButton(
                              onPressed:
                                  (_isLoading ||
                                      _isSendingCode ||
                                      !_isPhoneVerified)
                                  ? null
                                  : _handleRegister,

                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF47B08),
                                foregroundColor: Colors.white,

                                disabledBackgroundColor: const Color(
                                  0xFFF5C18C,
                                ),
                                disabledForegroundColor: Colors.white,

                                minimumSize: const Size(double.infinity, 56),
                                elevation: 0,

                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),

                              child: const Text(
                                '가입하기',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
