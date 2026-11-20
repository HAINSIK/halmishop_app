import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order_model.dart';
import 'api_config.dart';

class OrderService {
  String get baseUrl => '${ApiConfig.baseUrl}/api/orders';
  // 149-7-41-10단계: 마지막 주문 실패 메시지
  String? lastOrderError;

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token == null || token.isEmpty) {
      throw StateError('로그인이 필요합니다. 다시 로그인해 주세요.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  Future<bool> createOrder(OrderRequest request) async {
    // 이전 주문의 오류 메시지 초기화
    lastOrderError = null;

    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: await _headers(),
            body: jsonEncode(request.toJson()),
          )
          .timeout(const Duration(seconds: 20));

      final responseBody = utf8.decode(response.bodyBytes);

      debugPrint('주문 응답 ${response.statusCode}: $responseBody');

      // 정상 주문 접수
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }

      // 서버에서 전달한 오류 메시지 확인
      try {
        final data = jsonDecode(responseBody);

        if (data is Map && data['message'] != null) {
          lastOrderError = data['message'].toString();
        }
      } catch (_) {
        // JSON 형식이 아닌 응답은 기본 안내 메시지 사용
      }

      lastOrderError ??= '주문 처리 중 문제가 발생했습니다.';
      return false;
    } catch (e) {
      debugPrint('주문 요청 오류: $e');
      lastOrderError = '서버 연결에 실패했습니다. 잠시 후 다시 시도해 주세요.';
      return false;
    }
  }
}
