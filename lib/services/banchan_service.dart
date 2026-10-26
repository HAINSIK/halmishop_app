// lib/services/banchan_service.dart 전체 교체
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/banchan_model.dart';

class BanchanService {
  // 💡 기존 제품 API 주소
  final String baseUrl = 'http://localhost:8080/api/products';

  // 💡 스프링 부트 주문 저장 API 주소 (컨트롤러 RequestMapping 주소에 맞게 적어주셔유)
  final String orderUrl = 'http://localhost:8080/api/orders';

  // 1. 기존 반찬 목록 가져오기 함수
  Future<List<Banchan>> fetchBanchanList() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );
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

  // 💡 2. [새로 추가] 스프링 부트 + MySQL 서버로 진짜 주문 데이터 전송하기
  Future<bool> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response = await http.post(
        Uri.parse(orderUrl),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8', // JSON 통신 선언
        },
        body: jsonEncode(orderData), // 맵 데이터를 텍스트 JSON으로 압축 변환
      );

      // 스프링 부트에서 성공 코드(200 OK 또는 201 Created)를 내어주었는지 확인
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('👵 할미 백엔드 MySQL 디비에 주문 저장 성공해부렀다!');
        return true;
      } else {
        print('❌ 서버 주문 저장 실패 코드: ${response.statusCode}');
        print('❌ 서버 응답 내용: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ 스프링 주문 API 통신 중 탈이 났구만유: $e');
      return false;
    }
  }
}

