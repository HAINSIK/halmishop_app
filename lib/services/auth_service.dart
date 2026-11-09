import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import 'api_config.dart';

class AuthService {
  String get baseUrl => '${ApiConfig.baseUrl}/api/members';

  // 휴대폰 인증번호 발송
  Future<bool> requestPhoneVerification(
    String phoneNumber, {
    String purpose = 'JOIN',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/phone-verification/request'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'phoneNumber': phoneNumber.trim(),
              'purpose': purpose,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('휴대폰 인증번호 발송 성공');
        return true;
      }

      print(
        '인증번호 발송 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );
      return false;
    } catch (e) {
      print('휴대폰 인증번호 발송 통신 오류: $e');
      return false;
    }
  }

  // 휴대폰 인증번호 확인 및 일회용 토큰 발급
  Future<String?> confirmPhoneVerification(
    String phoneNumber,
    String code, {
    String purpose = 'JOIN',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/phone-verification/confirm'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'phoneNumber': phoneNumber.trim(),
              'purpose': purpose,
              'code': code.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        final token = data['verificationToken']?.toString();

        if (data['verified'] == true && token != null && token.isNotEmpty) {
          print('휴대폰 인증 성공');
          return token;
        }
      }

      print(
        '휴대폰 인증 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );

      return null;
    } catch (e) {
      print('휴대폰 인증 확인 통신 오류: $e');
      return null;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/join'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('회원가입 통신 오류: $e');
      return false;
    }
  }

  Future<bool> login(LoginRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/login'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        print(
          '로그인 실패 (${response.statusCode}): ${utf8.decode(response.bodyBytes)}',
        );
        return false;
      }

      final Map<String, dynamic> data = jsonDecode(
        utf8.decode(response.bodyBytes),
      );
      final token = data['token']?.toString() ?? '';
      final memberId = data['memberId']?.toString() ?? '';
      final role = data['role']?.toString() ?? 'CUSTOMER';
      if (token.isEmpty || memberId.isEmpty) {
        print('로그인 응답에 token/memberId가 없습니다. 서버 응답 형식을 확인하세요.');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      await prefs.setString('member_id', memberId);
      await prefs.setString('member_role', role);
      await prefs.setString('member_name', data['name']?.toString() ?? '');
      return true;
    } catch (e) {
      print('로그인 통신 오류: $e');
      return false;
    }
  }

  // SMS 인증 후 비밀번호 재설정
  Future<bool> resetPassword({
    required String phoneNumber,
    required String newPassword,
    required String verificationToken,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/reset-password'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'phoneNumber': phoneNumber.trim(),
              'newPassword': newPassword,
              'verificationToken': verificationToken,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('비밀번호 재설정 성공');
        return true;
      }

      print(
        '비밀번호 재설정 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );

      return false;
    } catch (e) {
      print('비밀번호 재설정 통신 오류: $e');
      return false;
    }
  }

  Future<bool> hasSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('jwt_token');
    final memberId = prefs.getString('member_id');

    if (token == null || token.isEmpty) {
      return false;
    }

    if (memberId == null || memberId.isEmpty) {
      return false;
    }

    return true;
  }

  Future<int?> checkSavedTokenStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      print('저장된 JWT 토큰이 없습니다.');
      return null;
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth-check'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      print('JWT 인증 확인 HTTP 상태: ${response.statusCode}');

      return response.statusCode;
    } catch (e) {
      print('JWT 인증 확인 통신 오류: $e');
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('member_id');
    await prefs.remove('member_role');
    await prefs.remove('member_name');
  }
}
