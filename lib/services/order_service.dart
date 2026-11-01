import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import 'api_config.dart';

class OrderService {
  String get baseUrl => '${ApiConfig.baseUrl}/api/orders';

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
    try {
      final response = await http
          .post(Uri.parse(baseUrl), headers: await _headers(), body: jsonEncode(request.toJson()))
          .timeout(const Duration(seconds: 20));
      print('주문 응답 ${response.statusCode}: ${utf8.decode(response.bodyBytes)}');
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('주문 요청 오류: $e');
      return false;
    }
  }
}
