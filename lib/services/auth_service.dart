// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:html' as html; // 웹 로컬 스토리지용
import 'package:http/http.dart' as http;
import '../models/user_model.dart'; // ◀ 모델 임포트 확인

class AuthService {
  final String baseUrl = 'http://localhost:8080'; 

  // 1. 회원가입 API 연동
  Future<bool> register(RegisterRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/members/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true; 
      } else {
        print('회원가입 실패 코드: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('네트워크 에러 발생: $e');
      return false;
    }
  }

  // 2. 로그인 API 연동
  Future<bool> login(LoginRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/members/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final loginResponse = LoginResponse.fromJson(responseData);

        html.window.localStorage['jwt_token'] = loginResponse.token;
        print('🔑 로그인 성공! 토큰 저장 완료');
        return true;
      } else {
        print('로그인 실패 코드: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('네트워크 에러 발생: $e');
      return false;
    }
  }
}