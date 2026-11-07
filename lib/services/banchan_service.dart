import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/banchan_model.dart';
import 'api_config.dart';

import 'package:shared_preferences/shared_preferences.dart';

class BanchanService {
  String get baseUrl => '${ApiConfig.baseUrl}/api/products';

  Future<List<Banchan>> fetchBanchanList() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        return data.map((json) => Banchan.fromJson(json)).toList();
      }
      print('반찬 목록 로드 실패 코드: ${response.statusCode}');
      return [];
    } catch (e) {
      print('반찬 목록 조회 중 오류: $e');
      return [];
    }
  }

  Future<bool> saveLiveProducts(List<int> productIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        print('라이브 상품 저장 실패: 로그인 정보 없음');
        return false;
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/live-setup'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(productIds),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('라이브 상품 저장 성공!');
        return true;
      }

      print(
        '라이브 상품 저장 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );
      return false;
    } catch (e) {
      print('라이브 상품 저장 통신 오류: $e');
      return false;
    }
  }
}
