import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/banchan_model.dart';
import 'api_config.dart';

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
}
