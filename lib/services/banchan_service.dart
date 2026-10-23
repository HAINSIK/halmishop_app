import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/banchan_model.dart';

class BanchanService {
  final String baseUrl =
      'http://localhost:8080/api/products'; // ◀ 본인의 스프링 반찬 API 주소로 수정

  Future<List<Banchan>> fetchBanchanList() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        // UTF-8 한글 깨짐 방지 처리 후 디코드
        final List<dynamic> decodedData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        // JSON 리스트를 Banchan 객체 리스트로 변환
        return decodedData.map((json) => Banchan.fromJson(json)).toList();
      } else {
        print('반찬 목록 로드 실패 코드: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('반찬 목록 조회 중 에러 발생: $e');
      return [];
    }
  }
}
