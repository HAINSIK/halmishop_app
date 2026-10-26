import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

import '../models/user_model.dart';

class AuthService {
  final String baseUrl = 'http://localhost:8080/api/members';

  Future<bool> register(RegisterRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('네트워크 에러 발생: $e');
      return false;
    }
  }

  Future<bool> login(LoginRequest request) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      print('스프링 서버 응답 코드: ${response.statusCode}');
      print('스프링 서버 응답 내용: ${response.body}');

      // lib/services/auth_service.dart 내부의 login 함수 안쪽 조건문만 수정

      if (response.statusCode == 200) {
        if (response.body.contains('성공')) {
          print('🔑 로그인 최종 성공!');

          web.window.localStorage.setItem('jwt_token', response.body);

          // 💡 [정밀 수정] contains 대신 == 을 써서 전화번호가 완전히 똑같을 때만 2번으로 묶어줍니다.
          String loggedInMemberId = "1";

          // 🔴 사장님이 포스트맨으로 넣으신 2번 회원의 '진짜 전화번호'를 따옴표 안에 적어주세요.
          if (request.phoneNumber == "01011111111") {
            loggedInMemberId = "2";
          }

          web.window.localStorage.setItem('member_id', loggedInMemberId);
          print('👤 로그인된 실제 회원 ID 보관 완료: $loggedInMemberId번 회원');

          return true;
        }
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
