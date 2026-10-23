// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:html' as html; // 웹 로컬 스토리지용

import 'package:web/web.dart' as web;

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
  // lib/services/auth_service.dart 의 login 함수 교체
  Future<bool> login(LoginRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/members/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      print('스프링 서버 응답 코드: ${response.statusCode}');
      print('스프링 서버 응답 내용: ${response.body}'); // ◀ 콘솔에서 실제로 뭐가 오는지 직접 확인용

      if (response.statusCode == 200) {
        String token = '';

        try {
          // 1. 만약 응답이 JSON 구조라면 예쁘게 파싱 시도
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          token = responseData['token'] ?? responseData['accessToken'] ?? '';
        } catch (jsonError) {
          // 2. 만약 JSON이 아니라 단순 문자열(String) 토큰이 온 경우, 통째로 토큰으로 인식
          token = response.body.trim();
        }

        if (token.isNotEmpty) {
          // 웹 로컬 스토리지에 토큰 안전하게 저장
          html.window.localStorage['jwt_token'] = token;
          print('🔑 로그인 최종 성공! 토큰 보관 완료');
          return true;
        } else {
          print('토큰이 비어있습니다.');
          return false;
        }
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
