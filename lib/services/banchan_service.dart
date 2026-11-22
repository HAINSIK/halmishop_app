import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/banchan_model.dart';
import 'api_config.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:image_picker/image_picker.dart';

import 'package:http_parser/http_parser.dart';

class BanchanService {
  String get baseUrl => '${ApiConfig.baseUrl}/api/products';

  // 148-3-14-1단계: 관리자 상품등록 API
  Future<int?> registerProduct({
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
        debugPrint('상품등록 실패: 로그인 정보 없음');
        return null;
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final productId = (data['productId'] as num?)?.toInt();

        debugPrint('상품등록 성공! 상품 ID: $productId');
        return productId;
      }

      debugPrint(
        '상품등록 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );
      return null;
    } catch (e) {
      debugPrint('상품등록 통신 오류: $e');
      return null;
    }
  }

  Future<String?> uploadProductImage(
    XFile imageFile, {
    required int productId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        debugPrint('이미지 업로드 실패: 로그인 정보 없음');
        return null;
      }

      // 152-5-3단계: 상품 ID별 대표사진 업로드
      final uri = Uri.parse('$baseUrl/$productId/upload-image');

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
        debugPrint('지원하지 않는 이미지 형식: $extension');
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

        debugPrint('이미지 업로드 성공: $imageUrl');
        return imageUrl;
      }

      debugPrint(
        '이미지 업로드 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );
      return null;
    } catch (e) {
      debugPrint('이미지 업로드 통신 오류: $e');
      return null;
    }
  }

  // 149-3-26단계: 관리자 상품 기본 정보 수정 API
  Future<bool> updateProduct({
    required int productId,
    required String name,
    required int price,
    required String category,
    required String description,
    required String imageUrl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        debugPrint('상품 수정 실패: 로그인 정보 없음');
        return false;
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/$productId'),
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

      if (response.statusCode == 200) {
        debugPrint('상품 수정 성공: $productId');
        return true;
      }

      debugPrint(
        '상품 수정 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );
      return false;
    } catch (e) {
      debugPrint('상품 수정 통신 오류: $e');
      return false;
    }
  }

  // 148-5-9-3-5단계: 상품 상세사진 업로드
  Future<bool> uploadProductDetailImage({
    required int productId,
    required XFile imageFile,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        debugPrint('상세사진 업로드 실패: 로그인 정보 없음');
        return false;
      }

      final uri = Uri.parse('$baseUrl/$productId/images');

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
        debugPrint('지원하지 않는 상세사진 형식: $extension');
        return false;
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

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('상세사진 업로드 성공: 상품 ID $productId');
        return true;
      }

      debugPrint(
        '상세사진 업로드 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );

      return false;
    } catch (e) {
      debugPrint('상세사진 업로드 통신 오류: $e');
      return false;
    }
  }

  // 149-4-2단계: 상품별 상세사진 목록 조회
  Future<List<Map<String, dynamic>>> fetchProductDetailImages(
    int productId,
  ) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/$productId/images'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      debugPrint(
        '상세사진 조회 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );

      return [];
    } catch (e) {
      debugPrint('상세사진 조회 통신 오류: $e');
      return [];
    }
  }

  // 149-4-9-6단계: 상품 상세사진 개별 삭제
  Future<bool> deleteProductDetailImage({
    required int productId,
    required int imageId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        debugPrint('상세사진 삭제 실패: 로그인 정보 없음');
        return false;
      }

      final response = await http
          .delete(
            Uri.parse('$baseUrl/$productId/images/$imageId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      }

      debugPrint(
        '상세사진 삭제 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );

      return false;
    } catch (e) {
      debugPrint('상세사진 삭제 통신 오류: $e');
      return false;
    }
  }

  // 149-4-10-5단계: 상품 상세사진 표시 순서 변경
  Future<bool> reorderProductDetailImages({
    required int productId,
    required List<int> imageIds,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        debugPrint('상세사진 순서 변경 실패: 로그인 정보 없음');
        return false;
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/$productId/images/reorder'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(imageIds),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      }

      debugPrint(
        '상세사진 순서 변경 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );

      return false;
    } catch (e) {
      debugPrint('상세사진 순서 변경 통신 오류: $e');
      return false;
    }
  }

  // 149-5-9단계: 상품 판매 중지 및 판매 재개
  Future<bool> updateProductSaleStatus({
    required int productId,
    required bool saleEnabled,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        debugPrint('판매 상태 변경 실패: 로그인 정보 없음');
        return false;
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/$productId/sale-status'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'saleEnabled': saleEnabled}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      }

      debugPrint(
        '판매 상태 변경 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );

      return false;
    } catch (e) {
      debugPrint('판매 상태 변경 통신 오류: $e');
      return false;
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
      debugPrint('반찬 목록 로드 실패 코드: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('반찬 목록 조회 중 오류: $e');
      return [];
    }
  }

  Future<bool> saveLiveProducts(List<int> productIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        debugPrint('라이브 상품 저장 실패: 로그인 정보 없음');
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
        debugPrint('라이브 상품 저장 성공!');
        return true;
      }

      debugPrint(
        '라이브 상품 저장 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );
      return false;
    } catch (e) {
      debugPrint('라이브 상품 저장 통신 오류: $e');
      return false;
    }
  }

  // 143-11-13: 관리자 추천 반찬 저장
  Future<bool> saveRecommendedProducts(List<int> productIds) async {
    try {
      // 추천 반찬은 최대 4개까지만 선택
      if (productIds.length > 10) {
        debugPrint('추천 반찬은 최대 10개까지만 선택할 수 있습니다.');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        debugPrint('추천 반찬 저장 실패: 로그인 정보 없음');
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
        debugPrint('추천 반찬 저장 성공!');
        return true;
      }

      debugPrint(
        '추천 반찬 저장 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );
      return false;
    } catch (e) {
      debugPrint('추천 반찬 저장 통신 오류: $e');
      return false;
    }
  }

  // 146-2-8-5-7-1단계: 오늘 준비한 반찬 저장
  Future<bool> saveTodayPreparedProducts(List<int> productIds) async {
    try {
      if (productIds.length > 20) {
        debugPrint('지금 준비된 반찬은 최대 4개까지 선택할 수 있습니다.');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        debugPrint('지금 준비된 반찬 저장 실패: 로그인 정보 없음');
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
        debugPrint('지금 준비된 반찬 저장 성공!');
        return true;
      }

      debugPrint(
        '오늘 준비한 반찬 저장 실패 (${response.statusCode}): '
        '${utf8.decode(response.bodyBytes)}',
      );
      return false;
    } catch (e) {
      debugPrint('지금 준비된 반찬 저장 통신 오류: $e');
      return false;
    }
  }
}
