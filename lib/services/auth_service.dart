import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_config.dart';

class AuthService {
  String get baseUrl => '${ApiConfig.baseUrl}/api/members';

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
        print('로그인 실패 (${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
        return false;
      }

      final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
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

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('member_id');
    await prefs.remove('member_role');
    await prefs.remove('member_name');
  }
}
