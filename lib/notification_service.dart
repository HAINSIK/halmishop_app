import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import 'services/api_config.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // 150-9-10-12: 푸시 알림 클릭으로 주문내역 이동 요청 여부
  static bool pendingOpenOrderTab = false;

  // 151-22단계: 공지사항 알림 클릭 시 이동할 공지사항 ID
  static int? pendingNoticeId;

  // 151-22단계: 공지사항 알림 클릭 시 실행할 콜백
  static void Function(int noticeId)? onNoticeTap;

  // 150-9-10-20: 로컬 알림 클릭 시 메인 화면에 전달할 콜백
  static VoidCallback? onNotificationTap;

  // 150-9-5-11: 젊은할미 전용 Android 알림 채널
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _highImportanceChannel =
      AndroidNotificationChannel(
        'halmishop_high_importance',
        '젊은할미 주문·배송 알림',
        description: '주문, 입금확인, 배송 및 관리자 알림',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

  // 151-23단계: FCM 알림 종류에 따라 이동 대상 저장
  static void handleNotificationData(Map<String, dynamic> data) {
    final type = data['type']?.toString().toUpperCase();
    final noticeId = int.tryParse(data['targetId']?.toString() ?? '');

    if (type == 'NOTICE' && noticeId != null && noticeId > 0) {
      // 공지사항 알림
      pendingOpenOrderTab = false;
      pendingNoticeId = noticeId;

      debugPrint('📢 공지사항 알림 이동 요청: $noticeId');
    } else {
      // 기존 주문·배송 알림 및 기타 알림
      pendingNoticeId = null;
      pendingOpenOrderTab = true;

      debugPrint('📦 주문내역 알림 이동 요청');
    }
  }

  // 알림 권한 요청 및 FCM 토큰 확인
  static Future<void> initialize() async {
    // 153-8-11-22-2단계: 웹에서는 FCM 초기화 생략
    if (kIsWeb) {
      debugPrint('웹 환경: FCM 알림 초기화 생략');
      return;
    }

    try {
      // 150-9-7-2: 포그라운드 로컬 알림 초기화
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        const AndroidInitializationSettings androidSettings =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const InitializationSettings initializationSettings =
            InitializationSettings(android: androidSettings);

        await _localNotifications.initialize(
          initializationSettings,
          // 151-33-2단계: 로컬 알림 클릭 시 주문/공지사항 구분
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            debugPrint('🔔 포그라운드 로컬 알림 클릭 감지');

            Map<String, dynamic> data = {};

            try {
              final payload = response.payload;

              if (payload != null && payload.isNotEmpty) {
                data = Map<String, dynamic>.from(jsonDecode(payload));
              }
            } catch (e) {
              debugPrint('❌ 로컬 알림 데이터 해석 오류: $e');
            }

            // 알림 종류 및 이동 대상 저장
            handleNotificationData(data);

            final noticeId = pendingNoticeId;

            if (noticeId != null) {
              // 공지사항 알림
              if (onNoticeTap != null) {
                onNoticeTap!(noticeId);
              }
            } else {
              // 기존 주문·배송 알림
              if (onNotificationTap != null) {
                onNotificationTap!();
              }
            }
          },
        );

        debugPrint('젊은할미 로컬 알림 초기화 완료');
      }

      // 150-9-5-12: Android HIGH 중요도 알림 채널 생성
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(_highImportanceChannel);

        debugPrint('젊은할미 HIGH 알림 채널 생성 완료');
      }

      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('알림 권한 상태: ${settings.authorizationStatus}');

      // 150-9-10-14: 앱 종료 상태에서 FCM 알림을 눌러 실행한 경우
      final RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();

      debugPrint('🔍 150-9-10-27 초기 FCM 메시지 존재 여부: ${initialMessage != null}');

      // 151-24단계: 앱 종료 상태에서 알림 종류에 따라 이동 대상 저장
      if (initialMessage != null) {
        debugPrint('FCM 알림 클릭 감지 (앱 종료 상태)');
        debugPrint('FCM 알림 데이터: ${initialMessage.data}');

        handleNotificationData(initialMessage.data);
      }

      // 150-9-7-3: 앱 실행 중 FCM 메시지 수신
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          debugPrint('포그라운드 FCM 수신: ${message.notification?.title}');

          final notification = message.notification;

          if (notification == null) {
            return;
          }

          try {
            await _localNotifications.show(
              message.messageId?.hashCode ??
                  DateTime.now().millisecondsSinceEpoch ~/ 1000,
              notification.title,
              notification.body,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'halmishop_high_importance',
                  '젊은할미 주문·배송 알림',
                  channelDescription: '주문, 입금확인, 배송 및 관리자 알림',
                  importance: Importance.high,
                  priority: Priority.high,
                  playSound: true,
                  enableVibration: true,
                ),
              ),
              // 151-33-1단계: 알림 클릭 시 종류를 구분하기 위한 FCM 데이터
              payload: jsonEncode(message.data),
            );

            debugPrint('젊은할미 포그라운드 알림 표시 완료');
          } catch (e) {
            debugPrint('포그라운드 알림 표시 오류: $e');
          }
        });
      }

      // // 150-9-9-6: Firebase 토큰 자동 갱신 시 서버 재등록
      // _messaging.onRegistered.listen((String newToken) async {
      //   debugPrint('FCM 토큰 갱신 감지');

      //   final prefs = await SharedPreferences.getInstance();
      //   final jwtToken = prefs.getString('jwt_token');

      //   if (jwtToken == null || jwtToken.isEmpty) {
      //     debugPrint('FCM 토큰 갱신: 로그인 상태가 아니므로 등록 생략');
      //     return;
      //   }

      //   await registerToken();
      // });

      String? token = await _messaging.getToken();

      if (token != null) {
        debugPrint('FCM 기기 토큰: $token');
      } else {
        debugPrint('FCM 토큰을 가져오지 못했습니다.');
      }
    } catch (e) {
      debugPrint('알림 초기화 오류: $e');
    }
  }

  // 로그인한 회원의 FCM 토큰을 서버에 등록
  static Future<void> registerToken() async {
    // 153-8-11-22-3단계: 웹에서는 FCM 토큰 등록 생략
    if (kIsWeb) {
      debugPrint('웹 환경: FCM 토큰 등록 생략');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final jwtToken = prefs.getString('jwt_token');

      if (jwtToken == null || jwtToken.isEmpty) {
        debugPrint('FCM 등록 실패: 로그인 토큰이 없습니다.');
        return;
      }

      // TODO: 서버의 FID 등록 및 푸시 발송 방식 전환 후 제거
      // ignore: deprecated_member_use
      final fcmToken = await _messaging.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('FCM 등록 실패: 기기 토큰이 없습니다.');
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
        debugPrint('FCM 토큰 서버 등록 성공');
      } else {
        debugPrint(
          'FCM 토큰 등록 실패 '
          '(${response.statusCode}): ${utf8.decode(response.bodyBytes)}',
        );
      }
    } catch (e) {
      debugPrint('FCM 토큰 서버 등록 오류: $e');
    }
  }

  // 150-9-8-5: 로그아웃 시 서버의 FCM 토큰 연결 해제
  static Future<bool> unregisterToken() async {
    // 153-8-11-22-4단계: 웹에서는 FCM 토큰 연결 해제 생략
    if (kIsWeb) {
      debugPrint('웹 환경: FCM 토큰 연결 해제 생략');
      return true;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwt_token');

      if (jwtToken == null || jwtToken.isEmpty) {
        debugPrint('FCM 토큰 해제 건너뜀: 로그인 정보 없음');
        return false;
      }

      final fcmToken = await _messaging.getToken();

      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('FCM 토큰 해제 건너뜀: 기기 토큰 없음');
        return false;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/members/fcm-token/unregister'),
            headers: {
              'Content-Type': 'application/json; charset=UTF-8',
              'Authorization': 'Bearer $jwtToken',
            },
            body: jsonEncode({'fcmToken': fcmToken}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('FCM 토큰 서버 연결 해제 성공');
        return true;
      }

      debugPrint('FCM 토큰 해제 실패: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('FCM 토큰 해제 오류: $e');
      return false;
    }
  }

  // 150-9-9-3: 로그아웃 시 기기 FCM 토큰 삭제
  static Future<void> deleteDeviceToken() async {
    // 153-8-11-22-5단계: 웹에서는 FCM 기기 토큰 삭제 생략
    if (kIsWeb) {
      debugPrint('웹 환경: FCM 기기 토큰 삭제 생략');
      return;
    }

    try {
      await _messaging.deleteToken();

      debugPrint('FCM 기기 토큰 삭제 성공');
    } catch (e) {
      debugPrint('FCM 기기 토큰 삭제 실패: $e');
    }
  }
}
