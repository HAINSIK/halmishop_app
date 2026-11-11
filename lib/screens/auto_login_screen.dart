import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_feed_screen copy.dart';
import 'package:provider/provider.dart';

import '../cart_provider.dart';

class AutoLoginScreen extends StatefulWidget {
  const AutoLoginScreen({super.key});

  @override
  State<AutoLoginScreen> createState() => _AutoLoginScreenState();
}

class _AutoLoginScreenState extends State<AutoLoginScreen>
    with TickerProviderStateMixin {

  bool _connectionFailed = false;

  late final AnimationController _loadingController;
  late final AnimationController _circleController;

  @override
  void initState() {
    super.initState();

    // 가로 진행 막대: 3초 동안 한 번만 진행
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();

    // 원형 서클: 3초마다 계속 회전
    _circleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _checkSavedLogin();
  }

  @override
void dispose() {
  _loadingController.dispose();
  _circleController.dispose();
  super.dispose();
}

Future<void> _checkSavedLogin() async {
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    final authService = AuthService();
    final hasLogin = await authService.hasSavedLogin();

    if (!mounted) return;

    debugPrint('자동 로그인 저장 정보 확인: $hasLogin');

    if (!hasLogin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    final statusCode = await authService.checkSavedTokenStatus();

    if (!mounted) return;

    debugPrint('자동 로그인 서버 인증 결과: $statusCode');

    if (statusCode == null || statusCode >= 500) {
      setState(() {
        _connectionFailed = true;
      });
      return;
    }

    if (statusCode == 200) {
      final cartProvider = context.read<CartProvider>();

      cartProvider.clearCartForAccountChange();

      final restored = await cartProvider.restoreCart();

      if (!mounted) return;

      if (!restored) {
        debugPrint('자동 로그인 장바구니 복원 실패 또는 보류');

        setState(() {
          _connectionFailed = true;
        });

        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainFeedScreen()),
      );
      return;
    }

    if (statusCode == 401) {
      debugPrint('자동 로그인 실패: JWT 인증 만료 또는 무효');

      await authService.logout();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    debugPrint('자동 로그인 중 예상하지 못한 HTTP 응답: $statusCode');

    setState(() {
      _connectionFailed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
      backgroundColor: const Color(0xFFFFF8EC),
      body: Center(
        child: _connectionFailed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('서버에 연결할 수 없습니다.', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _connectionFailed = false;
                      });
                      _checkSavedLogin();
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              )
           : Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/splash/splash_full.png',
                    fit: BoxFit.cover,
                  ),

                Align(
                    alignment: const Alignment(0, 0.70),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: RotationTransition(
                            turns: _circleController,
                            child: const CircularProgressIndicator(
                              value: 0.75,
                              color: Color(0xFF578D28),
                              strokeWidth: 4,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        Text(
                          '맛있는 반찬을 준비하고 있어요...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4A2819),
                          ),
                        ),

                        SizedBox(height: 20),

                     
                        SizedBox(
                          width: 220,
                          child: AnimatedBuilder(
                            animation: _loadingController,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: _loadingController.value,
                                color: const Color(0xFF578D28),
                                backgroundColor: const Color(0xFFD9D2C8),
                                minHeight: 7,
                                borderRadius: BorderRadius.circular(10),
                              );
                            },
                          ),
                        ),

                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
