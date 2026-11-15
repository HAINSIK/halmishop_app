import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/banchan_model.dart';
import 'api_config.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class BanchanService {
  String get baseUrl => '${ApiConfig.baseUrl}/api/products';

  // 148-3-14-1단계: 관리자 상품등록 API
  Future<bool> registerProduct({
    required String name,
    required int price,
    required String category,
    String? description,
    String? imageUrl, // 148-3-17-14: 상품 대표사진 주소
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        print('상품등록 실패: 로그인 정보 없음');
        return false;
      }

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': name,
              'price': price,
              'category': category,
              'description': description,
              'imageUrl': imageUrl,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('상품등록 성공!');
        return true;
      }

      print(
        '상품등록 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );
      return false;
    } catch (e) {
      print('상품등록 통신 오류: $e');
      return false;
    }
  }

  Future<String?> uploadProductImage(XFile imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        print('이미지 업로드 실패: 로그인 정보 없음');
        return null;
      }

      final uri = Uri.parse('$baseUrl/upload-image');

      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';

      final Uint8List imageBytes = await imageFile.readAsBytes();

      final extension = imageFile.name.split('.').last.toLowerCase();

      final String mimeSubtype;
      if (extension == 'jpg' || extension == 'jpeg') {
        mimeSubtype = 'jpeg';
      } else if (extension == 'png') {
        mimeSubtype = 'png';
      } else if (extension == 'webp') {
        mimeSubtype = 'webp';
      } else {
        print('지원하지 않는 이미지 형식: $extension');
        return null;
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: imageFile.name,
          contentType: MediaType('image', mimeSubtype),
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final imageUrl = data['imageUrl'] as String?;

        print('이미지 업로드 성공: $imageUrl');
        return imageUrl;
      }

      print(
        '이미지 업로드 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );
      return null;
    } catch (e) {
      print('이미지 업로드 통신 오류: $e');
      return null;
    }
  }

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

  // 143-11-13: 관리자 추천 반찬 저장
  Future<bool> saveRecommendedProducts(List<int> productIds) async {
    try {
      // 추천 반찬은 최대 4개까지만 선택
      if (productIds.length > 10) {
        print('추천 반찬은 최대 10개까지만 선택할 수 있습니다.');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        print('추천 반찬 저장 실패: 로그인 정보 없음');
        return false;
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/recommended-setup'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(productIds),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('추천 반찬 저장 성공!');
        return true;
      }

      print(
        '추천 반찬 저장 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );
      return false;
    } catch (e) {
      print('추천 반찬 저장 통신 오류: $e');
      return false;
    }
  }

  // 146-2-8-5-7-1단계: 오늘 준비한 반찬 저장
  Future<bool> saveTodayPreparedProducts(List<int> productIds) async {
    try {
      if (productIds.length > 20) {
        print('지금 준비된 반찬은 최대 4개까지 선택할 수 있습니다.');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        print('지금 준비된 반찬 저장 실패: 로그인 정보 없음');
        return false;
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/today-prepared-setup'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(productIds),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('지금 준비된 반찬 저장 성공!');
        return true;
      }

      print(
        '오늘 준비한 반찬 저장 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );
      return false;
    } catch (e) {
      print('지금 준비된 반찬 저장 통신 오류: $e');
      return false;
    }
  }
}
