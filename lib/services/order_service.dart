import 'dart:html' as html;
import 'dart:convert';

import 'package:web/web.dart' as web;
import 'package:http/http.dart' as http;

import '../models/order_model.dart';
// 웹 로컬스토리지 토큰 확인용

import 'package:http/http.dart' as http;

import '../models/order_model.dart';

class OrderService {
  final String baseUrl = 'http://localhost:8080/api/orders'; // ◀ 스프링 주문 API 주소

  Future<bool> createOrder(OrderRequest request) async {
    try {
      // 로그인 시 저장했던 인증 정보 꺼내기
      final token = html.window.localStorage['jwt_token'] ?? '';

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // JWT 토큰을 사용하는 경우 추가 (선택)
        },
        body: jsonEncode(request.toJson()),
      );

      print('주문 서버 응답 코드: ${response.statusCode}');
      print('주문 서버 응답 내용: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true; // 주문 성공
      } else {
        return false; // 주문 실패
      }
    } catch (e) {
      print('주문 요청 중 에러 발생: $e');
      return false;
    }
  }
}
