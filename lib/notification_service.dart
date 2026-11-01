import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_config.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // 알림 권한 요청 및 FCM 토큰 확인
  static Future<void> initialize() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('알림 권한 상태: ${settings.authorizationStatus}');

      String? token = await _messaging.getToken();

      if (token != null) {
        print('FCM 기기 토큰: $token');
      } else {
        print('FCM 토큰을 가져오지 못했습니다.');
      }
    } catch (e) {
      print('알림 초기화 오류: $e');
    }
  }

  // 로그인한 회원의 FCM 토큰을 서버에 등록
  static Future<void> registerToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final jwtToken = prefs.getString('jwt_token');

      if (jwtToken == null || jwtToken.isEmpty) {
        print('FCM 등록 실패: 로그인 토큰이 없습니다.');
        return;
      }

      final fcmToken = await _messaging.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        print('FCM 등록 실패: 기기 토큰이 없습니다.');
        return;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/members/fcm-token'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $jwtToken',
            },
            body: jsonEncode({'fcmToken': fcmToken}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('FCM 토큰 서버 등록 성공');
      } else {
        print(
          'FCM 토큰 등록 실패 '
          '(${response.statusCode}): ${utf8.decode(response.bodyBytes)}',
        );
      }
    } catch (e) {
      print('FCM 토큰 서버 등록 오류: $e');
    }
  }
}
