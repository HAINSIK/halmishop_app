// lib/screens/main_feed_screen.dart 전체 교체
import 'package:flutter/material.dart';
// 149-6-5단계: 네트워크 이미지 디스크 캐싱
import 'package:cached_network_image/cached_network_image.dart';

// 144-27-6단계: 공지사항 API 통신
import 'dart:convert';
// 145-35-1단계: 배너 자동 슬라이드 타이머
import 'dart:async';

import 'package:http/http.dart' as http;

import '../services/api_config.dart';

import 'package:halmishop_app/screens/banchan_detail_screen.dart';

import '../models/banchan_model.dart';
import '../services/banchan_service.dart';
import '../services/auth_service.dart';
import '../cart_provider.dart';
import 'order_list_screen.dart';
import 'cart_screen.dart';
import 'login_screen.dart';
import 'notice_list_screen.dart';
import 'admin_notice_screen.dart';
import 'admin_banner_screen.dart';
import 'product_register_screen.dart';
// 149-2-2-4단계: 관리자센터 화면 연결
import 'admin_dashboard_screen.dart';

import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'live_product_admin_screen.dart';
import 'recommended_product_admin_screen.dart';
import 'today_prepared_admin_screen.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  State<MainFeedScreen> createState() => _MainFeedScreenState();
}

class _MainFeedScreenState extends State<MainFeedScreen> {
  bool _isAdmin = false;

  Future<void> _checkAdminRole() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = prefs.getString('member_role') == 'ADMIN';

    if (!mounted) return;

    setState(() {
      _isAdmin = isAdmin;
    });
  }

  // 144-27-7단계: 서버에서 공개 공지사항 조회
  Future<void> _fetchNotices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _notices = [];
        });
        return;
      }

      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/notices'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        setState(() {
          _notices = data;
        });

        debugPrint('📢 공지사항 ${data.length}개 조회 완료');
      } else {
        debugPrint('❌ 공지사항 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 공지사항 조회 오류: $e');
    }
  }

  // 146-3-12-2단계: 장터홈 대표 공지 조회
  Future<void> _fetchHomeFeaturedNotice() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/notices/home-featured'))
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (data is Map<String, dynamic>) {
          setState(() {
            _homeFeaturedNotice = data;
          });

          debugPrint('✅ 장터홈 대표 공지 조회 성공');
        }
      } else if (response.statusCode == 204) {
        setState(() {
          _homeFeaturedNotice = null;
        });

        debugPrint('📢 지정된 장터홈 대표 공지가 없습니다.');
      } else {
        debugPrint('❌ 대표 공지 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 장터홈 대표 공지 조회 오류: $e');
    }
  }

  // 145-34-3단계: 고객 장터홈 공개 배너 조회

  Future<void> _fetchBanners() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/banners'))
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        final updatedBanners = data
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        final bool bannerCountChanged =
            _banners.length != updatedBanners.length;

        // 배너 개수가 바뀌면 자동 슬라이드 타이머 일시 종료
        if (bannerCountChanged) {
          _bannerTimer?.cancel();
        }

        setState(() {
          if (bannerCountChanged) {
            _currentBannerIndex = 0;
          }

          _banners = updatedBanners;
        });

        // 145-35-7단계: 실제 PageView 위치도 첫 페이지로 초기화
        if (bannerCountChanged && _bannerPageController.hasClients) {
          _bannerPageController.jumpToPage(0);
        }

        // 배너 조회 완료 후 자동 슬라이드 시작
        _startBannerAutoSlide();

        debugPrint('✅ 공개 배너 ${_banners.length}개 조회 완료');
      } else {
        debugPrint('❌ 배너 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 배너 조회 오류: $e');
    }
  }

  // 💡 메인 하단 네비게이션 인덱스
  // 146-2-1단계: 쇼핑몰 하단 메뉴 인덱스 정의
  static const int _homeTabIndex = 0;
  static const int _categoryTabIndex = 1;
  static const int _orderTabIndex = 3;

  // 마이페이지는 추후 추가 예정

  // 현재 선택된 하단 메뉴
  int _currentNavigationIndex = _homeTabIndex;

  // 카테고리 종류 정의
  // 148-3-7-4단계: 기타 카테고리 추가
  final List<String> categories = ['전체', '국·탕', '찌개·조림', '김치', '밑반찬', '기타'];
  final BanchanService _banchanService = BanchanService();
  late Future<List<Banchan>> _banchanFuture;
  final GlobalKey<OrderListScreenState> _orderListKey =
      GlobalKey<OrderListScreenState>();

  // 지금 방송중인 상품만 보기 필터 스위치 상태
  bool _showOnlyLive = false;

  // 143-7단계: 홈 화면 카테고리 선택 상태
  String _selectedCategory = '전체';

  // 143-10-4단계: 공지사항 표시 여부
  // 추후 관리자 설정 및 서버 데이터와 연결 예정
  final bool _showNotice = true;

  // 144-27-3단계: 서버에서 조회한 공개 공지사항 목록
  List<dynamic> _notices = [];

  // 146-3-12-1단계: 관리자가 지정한 장터홈 대표 공지
  Map<String, dynamic>? _homeFeaturedNotice;

  // 145-34-2단계: 고객 장터홈 공개 배너 목록
  List<Map<String, dynamic>> _banners = [];

  // 145-34-8단계: 현재 표시 중인 배너 번호
  int _currentBannerIndex = 0;

  // 147-3-4-2단계: 전체 목록 화면의 추천 반찬 여부
  bool _showRecommendedSelection = false;

  // 145-35-2단계: 배너 슬라이드 제어
  final PageController _bannerPageController = PageController();

  // 145-35-2단계: 자동 슬라이드 타이머
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();

    _banchanFuture = _banchanService.fetchBanchanList();
    _checkAdminRole();

    // 144-27-8단계: 메인 홈 진입 시 공지사항 조회
    _fetchNotices();

    // 146-3-12-4단계: 메인 홈 진입 시 대표 공지 조회
    _fetchHomeFeaturedNotice();

    // 145-34-4단계: 메인 홈 진입 시 공개 배너 조회
    _fetchBanners();
  }

  // 145-35-4단계: 배너 자동 슬라이드 자원 정리
  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerPageController.dispose();

    super.dispose();
  }

  // 145-35-5단계: 5초 간격 배너 자동 슬라이드
  void _startBannerAutoSlide() {
    // 기존 타이머가 있다면 먼저 종료
    _bannerTimer?.cancel();

    // 배너가 1개 이하라면 자동 슬라이드 불필요
    if (_banners.length <= 1) return;

    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      // 화면이 종료되었거나 컨트롤러가 연결되지 않았다면 이동하지 않음
      if (!mounted || !_bannerPageController.hasClients) return;

      // 장터홈 화면에서만 자동 슬라이드
      if (_currentNavigationIndex != 0) return;

      // 다음 배너 번호 계산
      final nextIndex = (_currentBannerIndex + 1) % _banners.length;

      // 다음 배너로 부드럽게 이동
      _bannerPageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  // 145-36-3단계: LIVE 배너 클릭 시 방송 상품 보기
  void _onLiveBannerTap() {
    setState(() {
      // 모든 카테고리에서 라이브 상품 검색
      _selectedCategory = '전체';

      // 라이브 방송 상품만 표시
      _showOnlyLive = true;

      // 뒤로가기 시 장터홈으로 복귀
      _categoryReturnIndex = _homeTabIndex;

      // 상품 목록 전용 화면으로 이동
      _currentNavigationIndex = 4;
    });

    debugPrint('🔴 LIVE 배너 클릭 → 라이브 상품 목록 화면 이동');
  }

  Future<void> _refreshBanchanList() async {
    debugPrint('🔄 할미샵 새로고침 실행됨!');
    final future = _banchanService.fetchBanchanList();

    setState(() {
      _banchanFuture = future;
    });

    await future;
  }

  @override
  Widget build(BuildContext context) {
    // 💡 1. 하단 메뉴 선택에 따라 다른 화면을 보여줍니다.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 148단계: 카테고리별 상품 목록 뒤로가기
        if (_currentNavigationIndex == 4) {
          setState(() {
            _currentNavigationIndex = _categoryReturnIndex;
          });
          return;
        }

        // 146-2-6-8단계: 상품 목록에서는 진입했던 화면으로 복귀
        // 147-2-4-8단계: 선택 반찬 전체 목록에서 장터홈으로 복귀
        if (_currentNavigationIndex == 5) {
          setState(() {
            _currentNavigationIndex = _homeTabIndex;
          });
          return;
        }

        // 카테고리, 장바구니, 주문내역에서는 장터홈으로 이동
        if (_currentNavigationIndex != _homeTabIndex) {
          setState(() {
            _currentNavigationIndex = _homeTabIndex;
          });
          return;
        }

        // 장터홈에서는 종료 확인 창 표시
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('할미샵 종료'),
              content: const Text('할미샵을 종료하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('종료'),
                ),
              ],
            );
          },
        );

        if (!mounted) return;

        if (shouldExit == true) {
          debugPrint('🚪 할미샵 종료 선택됨');
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          // 146-4-1단계: 젊은할미 브랜드 로고 + 앱바 문구
          titleSpacing: 12,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 146-4-1단계: 젊은할미 캐릭터 + 크림색 원형 배경
              // 146-4-1-3단계: 배경 없이 젊은할미 캐릭터 표시
              // 146-4-1-4단계: 캐릭터 로고 위치 미세 조정
              Transform.translate(
                offset: const Offset(0, 4),
                child: SizedBox(
                  width: 55,
                  height: 55,
                  child: Image.asset(
                    'assets/images/splash/halmi_character.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              const Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '젊은할미',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '정성을 담은 집밥 이야기',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: Color(0xFFF5D5A9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF244C3A),
          foregroundColor: Colors.white,
          centerTitle: false,
          elevation: 0,
          actions: [
            // 149-2-2-5단계: 관리자센터 화면 이동
            if (_isAdmin)
              IconButton(
                tooltip: '젊은할미 관리자센터',
                icon: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );

                  if (!mounted) return;

                  // 관리자센터에서 돌아오면 기존 데이터 새로고침
                  await _refreshBanchanList();
                  if (!mounted) return;

                  await _fetchNotices();
                  if (!mounted) return;

                  await _fetchBanners();
                },
              ),
            // 143-11-13: 관리자 상품 관리 통합 메뉴
            // if (_isAdmin)
            //   PopupMenuButton<String>(
            //     tooltip: '상품 관리자 메뉴',
            //     icon: const Icon(
            //       Icons.admin_panel_settings,
            //       color: Colors.white,
            //       size: 28,
            //     ),
            //     onSelected: (value) async {
            //       // 148-3-4단계: 관리자 상품등록 화면 이동
            //       if (value == 'productRegister') {
            //         await Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //             builder: (context) => const ProductRegisterScreen(),
            //           ),
            //         );
            //       } else if (value == 'live') {
            //         await Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //             builder: (context) => const LiveProductAdminScreen(),
            //           ),
            //         );
            //       } else if (value == 'recommended') {
            //         await Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //             builder: (context) =>
            //                 const RecommendedProductAdminScreen(),
            //           ),
            //         );
            //       } else if (value == 'todayPrepared') {
            //         await Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //             builder: (context) => const TodayPreparedAdminScreen(),
            //           ),
            //         );
            //       } else if (value == 'notice') {
            //         await Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //             builder: (context) => const AdminNoticeScreen(),
            //           ),
            //         );
            //       } else if (value == 'banner') {
            //         await Navigator.push(
            //           context,
            //           MaterialPageRoute(
            //             builder: (context) => const AdminBannerScreen(),
            //           ),
            //         );
            //       }

            //       if (!mounted) return;

            //       // 관리 화면에서 돌아오면 상품 목록 새로고침
            //       await _refreshBanchanList();

            //       // 공지사항도 최신 데이터로 새로고침
            //       await _fetchNotices();

            //       // 145-34-12단계: 공개 배너도 최신 데이터로 새로고침
            //       await _fetchBanners();
            //     },
            //     itemBuilder: (context) => const [
            //       // 148-3-1단계: 관리자 상품등록 메뉴
            //       PopupMenuItem<String>(
            //         value: 'productRegister',
            //         child: Row(
            //           children: [
            //             Icon(Icons.add_box_outlined, color: Color(0xFFF47B08)),
            //             SizedBox(width: 12),
            //             Text('상품등록'),
            //           ],
            //         ),
            //       ),

            //       PopupMenuItem<String>(
            //         value: 'notice',
            //         child: Row(
            //           children: [
            //             Icon(Icons.campaign_outlined, color: Color(0xFFF47B08)),
            //             SizedBox(width: 12),
            //             Text('공지사항 관리'),
            //           ],
            //         ),
            //       ),

            //       PopupMenuItem<String>(
            //         value: 'banner',
            //         child: Row(
            //           children: [
            //             Icon(
            //               Icons.view_carousel_outlined,
            //               color: Color(0xFFF47B08),
            //             ),
            //             SizedBox(width: 12),
            //             Text('배너 관리'),
            //           ],
            //         ),
            //       ),

            //       PopupMenuItem<String>(
            //         value: 'live',
            //         child: Row(
            //           children: [
            //             Icon(Icons.live_tv, color: Color(0xFFF47B08)),
            //             SizedBox(width: 12),
            //             Text('라이브 상품 관리'),
            //           ],
            //         ),
            //       ),

            //       PopupMenuItem<String>(
            //         value: 'recommended',
            //         child: Row(
            //           children: [
            //             Icon(Icons.star, color: Color(0xFFF47B08)),
            //             SizedBox(width: 12),
            //             Text('추천 반찬 관리'),
            //           ],
            //         ),
            //       ),

            //       // 146-2-8-5-7-3-2단계: 오늘 준비한 반찬 관리
            //       PopupMenuItem<String>(
            //         value: 'todayPrepared',
            //         child: Row(
            //           children: [
            //             Icon(Icons.restaurant_menu, color: Color(0xFFF47B08)),
            //             SizedBox(width: 12),
            //             Text('지금 준비된 반찬 관리'),
            //           ],
            //         ),
            //       ),
            //     ],
            //   ),
            IconButton(
              icon: const Icon(Icons.assignment, color: Colors.white, size: 28),
              onPressed: () {
                setState(() {
                  _currentNavigationIndex = _orderTabIndex;
                });
                _orderListKey.currentState?.refreshOrders();

                // Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderListScreen()));
              },
            ),
            IconButton(
              tooltip: '로그아웃',
              icon: const Icon(Icons.logout, color: Colors.white, size: 28),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('로그아웃'),
                      content: const Text('정말 로그아웃하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                          },
                          child: const Text('취소'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            // 비동기 작업 전에 장바구니 Provider 확보
                            final cartProvider = context.read<CartProvider>();

                            // 로그아웃 확인창 닫기
                            Navigator.pop(dialogContext);

                            try {
                              await cartProvider.waitForCartSave();
                            } catch (e) {
                              if (!context.mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '장바구니 저장에 실패했습니다. 잠시 후 다시 시도해주세요.',
                                  ),
                                ),
                              );
                              return;
                            }

                            if (!mounted) return;

                            // 로그인 정보 삭제
                            await AuthService().logout();

                            if (!context.mounted) return;

                            // 화면에 남아 있는 장바구니 초기화
                            cartProvider.clearCartForAccountChange();

                            // 로그인 화면으로 이동
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          child: const Text('로그아웃'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),

        // 💡 현재 선택된 하단 메뉴가 '장터(0번)'일 때만 카테고리 탭 화면을 보여주고, 나머지는 임시 화면 전환
        body: IndexedStack(
          index: _currentNavigationIndex,
          children: [
            _buildMarketHomeScreen(), // 0: 홈
            _buildCategoryScreen(), // 1: 카테고리
            const CartScreen(), // 2: 장바구니
            OrderListScreen(key: _orderListKey), // 3: 주문내역
            // 146-2-6-3단계: 카테고리별 상품 목록
            _buildCategoryProductScreen(),
            // 147-2-4-4단계: 관리자 선택 반찬 전체 목록 (5번 화면)
            _buildSelectedBanchanScreen(),
          ],
        ),

        // 💡 2. [진짜 하단 바] 여기에 장바구니와 다른 메뉴 버튼들이 들어갑니다!
        bottomNavigationBar: BottomNavigationBar(
          // 상품 목록 화면에서는 진입했던 메뉴를 선택 상태로 표시
          currentIndex: _currentNavigationIndex == 4
              ? (_categoryReturnIndex >= 0 && _categoryReturnIndex < 4
                    ? _categoryReturnIndex
                    : 0)
              : (_currentNavigationIndex >= 0 && _currentNavigationIndex < 4
                    ? _currentNavigationIndex
                    : 0),
          type: BottomNavigationBarType.fixed,

          onTap: (index) {
            setState(() {
              _currentNavigationIndex = index;
            });

            // 주문내역 메뉴 선택 시 최신 주문 조회
            if (index == _orderTabIndex) {
              _orderListKey.currentState?.refreshOrders();
            }
          },

          selectedItemColor: const Color(0xFFF47B08),
          unselectedItemColor: Colors.grey,

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: '카테고리',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: '장바구니',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: '주문내역',
            ),
          ],
        ),
      ),
    );
  }

  // 146-2-4-2단계: 음식 이미지형 카테고리 목록 카드
  Widget _buildCategoryListTile(
    String title,
    String subtitle,
    String imagePath,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black12,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            //실제 상품 목록 화면 연결
            _openCategoryProducts(title);
          },
          child: Container(
            height: 82,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE5D8)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    imagePath,
                    width: 66,
                    height: 66,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF244C3A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF244C3A)),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 146-2-2단계: 새로운 카테고리 화면 기본 구조
  Widget _buildCategoryScreen() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 화면 제목
            const Text(
              '반찬 카테고리',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF244C3A),
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              '원하시는 반찬을 종류별로 찾아보세요.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            // 일반 카테고리 영역
            const Text(
              '전체 카테고리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF244C3A),
              ),
            ),

            const SizedBox(height: 12),

            // 146-2-4-2단계: 이미지형 세로 카테고리 목록
            Column(
              children: [
                _buildCategoryListTile(
                  '전체 상품',
                  '모든 반찬 한눈에 보기',
                  'assets/images/categories/category_all.png',
                ),
                _buildCategoryListTile(
                  '탕/국',
                  '든든한 집밥 국물요리',
                  'assets/images/categories/category_soup.png',
                ),
                _buildCategoryListTile(
                  '찌개/조림',
                  '얼큰하고 깊은 맛',
                  'assets/images/categories/category_stew.png',
                ),
                _buildCategoryListTile(
                  '밑반찬',
                  '매일 먹어도 좋은 반찬',
                  'assets/images/categories/category_side.png',
                ),
                _buildCategoryListTile(
                  '김치',
                  '우리 집 밥상의 기본',
                  'assets/images/categories/category_kimchi.png',
                ),
                // 148-3-7-7단계: 기타 카테고리
                _buildCategoryListTile(
                  '기타',
                  '다양한 별미와 특별한 먹거리',
                  'assets/images/categories/category_all.png',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 특별 판매 카테고리 영역
            const Text(
              '특별 판매',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF244C3A),
              ),
            ),

            const SizedBox(height: 12),

            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Text(
                  '할인 반찬 · 오늘만 주문 · 라이브 방송 상품',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 146-2-5-2단계: 장터홈 음식 사진 카테고리 바로가기
  Widget _buildHomeCategoryShortcuts() {
    final homeCategories = [
      {'title': '전체', 'image': 'assets/images/categories/category_all.png'},
      {'title': '탕/국', 'image': 'assets/images/categories/category_soup.png'},
      {'title': '찌개/조림', 'image': 'assets/images/categories/category_stew.png'},
      {'title': '밑반찬', 'image': 'assets/images/categories/category_side.png'},
      {'title': '김치', 'image': 'assets/images/categories/category_kimchi.png'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              '반찬 카테고리',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF244C3A),
              ),
            ),
          ),

          Row(
            children: homeCategories.map((category) {
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _openCategoryProducts(category['title']!);
                  },
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ClipOval(
                            child: Image.asset(
                              category['image']!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 7),

                      Text(
                        category['title']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF244C3A),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 💡 3. 장터 홈 화면 구조 (스위치 + 카테고리 탭 바 + 상품 그리드 목록)
  Widget _buildMarketHomeScreen() {
    return RefreshIndicator(
      onRefresh: () async {
        await _refreshBanchanList();
        if (!mounted) return;

        await _fetchNotices();
        if (!mounted) return;

        // 146-3-12-3단계: 대표 공지도 함께 갱신
        await _fetchHomeFeaturedNotice();
        if (!mounted) return;

        // 145-34-13단계: 장터홈 새로고침 시 배너도 갱신
        await _fetchBanners();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // 143-10-1단계: 젊은할미 공지사항 안내
            // 143-10-5단계: 공지사항 표시 여부 적용
            // 146-3-12-5단계: 지정된 대표 공지가 있을 때만 홈 공지 표시
            if (_showNotice && _homeFeaturedNotice != null)
              InkWell(
                borderRadius: BorderRadius.circular(12),

                // 146-3-12-6단계: 대표 공지 클릭 시 상세 내용 표시
                onTap: () {
                  final notice = _homeFeaturedNotice;
                  if (notice == null) return;

                  showDialog(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      backgroundColor: const Color(0xFFF8F4E9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      title: Text(
                        notice['title']?.toString() ?? '공지사항',
                        style: const TextStyle(
                          color: Color(0xFF244C3A),
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      content: SingleChildScrollView(
                        child: Text(
                          notice['content']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                      // 146-3-15단계: 대표 공지 상세보기 + 전체 공지 목록
                      actions: [
                        OutlinedButton(
                          onPressed: () {
                            // 대표 공지 팝업 닫기
                            Navigator.pop(dialogContext);

                            // 기존 전체 공지사항 목록 화면 열기
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NoticeListScreen(notices: _notices),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF244C3A),
                            side: const BorderSide(color: Color(0xFF244C3A)),
                          ),
                          child: const Text('전체 공지 목록'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text(
                            '닫기',
                            style: TextStyle(
                              color: Color(0xFF244C3A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },

                // 146-3-16단계: 장터홈 대표 공지 디자인 개선
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8DFD0)),
                  ),
                  child: Row(
                    children: [
                      // 공지 아이콘
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF244C3A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.campaign_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 공지 제목 및 내용
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  '젊은할미 공지사항',
                                  style: TextStyle(
                                    color: Color(0xFF244C3A),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFE7D1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: const Text(
                                    '중요',
                                    style: TextStyle(
                                      color: Color(0xFFF47B08),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _homeFeaturedNotice?['title']?.toString() ??
                                  '공지사항',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF244C3A),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF244C3A),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

            // 145-34-5단계: 서버에 등록된 공개 배너 표시

            // 145-34-9단계: 공개 배너 좌우 슬라이드
            if (_banners.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: SizedBox(
                  height: 170,
                  child: PageView.builder(
                    // 145-35-3단계: 자동 슬라이드 컨트롤러 연결
                    controller: _bannerPageController,
                    // 145-35-7단계: 배너 개수 변경 시 컨트롤러 위치 초기화
                    key: ValueKey('banner_count_${_banners.length}'),
                    itemCount: _banners.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentBannerIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final banner = _banners[index];

                      final imagePath = banner['imageUrl']?.toString() ?? '';

                      final imageUrl = imagePath.startsWith('http')
                          ? imagePath
                          : '${ApiConfig.baseUrl}${imagePath.startsWith('/') ? '' : '/'}$imagePath';

                      return GestureDetector(
                        // 145-36-6단계: LIVE 배너 클릭 동작
                        onTap: () {
                          final category = banner['category']?.toString() ?? '';

                          if (category == 'LIVE') {
                            _onLiveBannerTap();
                          } else {
                            debugPrint('📢 일반 배너 클릭: ${banner['title']}');
                          }
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),

                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,

                            // 149-6-5단계: 이미지 다운로드 중 표시
                            placeholder: (context, url) {
                              return Container(
                                width: double.infinity,
                                height: 180,
                                color: const Color(0xFFF1EEE6),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF244C3A),
                                  ),
                                ),
                              );
                            },

                            // 이미지 다운로드 실패 시 표시
                            errorWidget: (context, url, error) {
                              return Container(
                                width: double.infinity,
                                height: 180,
                                color: const Color(0xFFF1EEE6),
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // 145-34-10단계: 배너 페이지 위치 표시
            if (_banners.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_banners.length, (index) {
                  final bool isSelected = index == _currentBannerIndex;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isSelected ? 18 : 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF47B08)
                          : const Color(0xFFD5D5D5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),

            // 146-2-5-1단계: 장터홈 음식 사진 카테고리 바로가기
            const SizedBox(height: 16),

            _buildHomeCategoryShortcuts(),

            const SizedBox(height: 8),

            // 143-8단계: 오늘의 추천 반찬 제목

            // 147-1-3단계: 준비된 반찬과 추천 반찬 독립 표시

            // 1. 지금 준비된 반찬들
            _buildTodayPreparedBanchan(),

            // 2. 처음이라면, 이 반찬부터!
            FutureBuilder<List<Banchan>>(
              future: _banchanFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData ||
                    !snapshot.data!.any((banchan) => banchan.isRecommended)) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF47B08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '처음이라면, 이 반찬부터!',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF244C3A),
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  '젊은할미가 자신 있게 추천하는 반찬이에요.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.restaurant_menu,
                            color: Color(0xFFF47B08),
                            size: 26,
                          ),
                        ],
                      ),
                    ),

                    // 관리자가 선택한 추천 반찬 목록
                    _buildRecommendedBanchan(),
                  ],
                );
              },
            ),

            // 3. 전체 상품 보러가기
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    _openCategoryProducts('전체');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF244C3A),
                    side: const BorderSide(
                      color: Color(0xFF244C3A),
                      width: 1.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '전체 상품 보러가기',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ),
            ),

            // 라이브 상품만 보기 스위치 바
            // 2026-11-14 메인화면에 보이는 스위치바 삭제
            // Container(
            //   padding: const EdgeInsets.symmetric(
            //     horizontal: 16.0,
            //     vertical: 10.0,
            //   ),
            //   color: Colors.orange.shade50,
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Row(
            //         children: [
            //           const Icon(
            //             Icons.live_tv,
            //             color: Colors.redAccent,
            //             size: 22,
            //           ),
            //           const SizedBox(width: 8),
            //           Text(
            //             _showOnlyLive
            //                 ? '🔴 지금 방송중인 주인공 반찬만 보는 중'
            //                 : '모든 맛있는 반찬 다 보는 중',
            //             style: const TextStyle(
            //               fontWeight: FontWeight.bold,
            //               fontSize: 14,
            //             ),
            //           ),
            //         ],
            //       ),
            //       Switch(
            //         value: _showOnlyLive,
            //         activeColor: Colors.redAccent,
            //         onChanged: (bool value) {
            //           setState(() {
            //             _showOnlyLive = value;
            //           });
            //         },
            //       ),
            //     ],
            //   ),
            // ),

            // 💡 카테고리 탭 바를 본문 상단에 배치 (너비에 맞게 딱 균등 분할 정렬)
            // 143-7-2단계: 젊은할미 카테고리 선택 버튼

            // 2026-11-14 메인피드 하단에 반찬목록이 나오던것을 주석처리함
            // Container(
            //   width: double.infinity,
            //   color: const Color(0xFFF8F4E9),
            //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            //   child: SingleChildScrollView(
            //     scrollDirection: Axis.horizontal,
            //     child: Row(
            //       children: categories.map((category) {
            //         final isSelected = _selectedCategory == category;

            //         return Padding(
            //           padding: const EdgeInsets.only(right: 8),
            //           child: ChoiceChip(
            //             label: Text(category),
            //             selected: isSelected,
            //             showCheckmark: false,
            //             onSelected: (_) {
            //               setState(() {
            //                 _selectedCategory = category;
            //               });
            //             },
            //             selectedColor: const Color(0xFF244C3A),
            //             backgroundColor: Colors.white,
            //             labelStyle: TextStyle(
            //               color: isSelected
            //                   ? Colors.white
            //                   : const Color(0xFF56341E),
            //               fontSize: 13,
            //               fontWeight: FontWeight.w600,
            //             ),
            //             side: BorderSide(
            //               color: isSelected
            //                   ? const Color(0xFF244C3A)
            //                   : const Color(0xFFE5DED3),
            //             ),
            //             shape: RoundedRectangleBorder(
            //               borderRadius: BorderRadius.circular(12),
            //             ),
            //           ),
            //         );
            //       }).toList(),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  // 143-9단계: 오늘의 추천 반찬
  Widget _buildRecommendedBanchan() {
    return FutureBuilder<List<Banchan>>(
      future: _banchanFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        // 우선 등록된 상품 중 앞의 4개를 추천 상품으로 표시
        // 147-3-4-1단계: 추천 반찬 전체 목록과 홈 표시 목록 분리
        final allRecommended = snapshot.data!
            .where((banchan) => banchan.isRecommended)
            .toList();

        final recommended = allRecommended.take(4).toList();

        final hasMore = allRecommended.length > 4;

        // 143-11-18: 추천 반찬이 없으면 영역 숨김
        if (recommended.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 205,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recommended.length + (hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              // 147-3-4-1단계: 추천 반찬 더보기 카드
              if (hasMore && index == recommended.length) {
                return GestureDetector(
                  // 147-3-4-3단계: 추천 반찬 전체 목록으로 이동
                  onTap: () {
                    setState(() {
                      _showRecommendedSelection = true;
                      _currentNavigationIndex = 5;
                    });
                  },
                  child: Container(
                    width: 145,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 145,
                          height: 135,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F4E9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE7E0D1)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF244C3A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                '할미 추천 반찬\n더 보기',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF244C3A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '총 ${allRecommended.length}개 반찬',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final banchan = recommended[index];

              return Container(
                width: 145,
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            BanchanDetailScreen(banchan: banchan),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),

                        child: CachedNetworkImage(
                          imageUrl: banchan.imageUrl,
                          width: 145,
                          height: 135,
                          fit: BoxFit.cover,

                          // 149-6-8단계: 추천 반찬 이미지 디스크 캐싱
                          placeholder: (context, url) {
                            return Container(
                              width: 145,
                              height: 135,
                              color: const Color(0xFFF8F4E9),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF244C3A),
                                ),
                              ),
                            );
                          },

                          errorWidget: (context, url, error) {
                            return Container(
                              width: 145,
                              height: 135,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.restaurant,
                                color: Color(0xFFF47B08),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        banchan.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF244C3A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${banchan.price}원',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF47B08),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 146-2-6-4단계: 카테고리별 상품 목록 이동
  int _categoryReturnIndex = 0;

  void _openCategoryProducts(String category) {
    // 현재 화면이 장터홈인지 카테고리 화면인지 기억
    final returnIndex = _currentNavigationIndex == _categoryTabIndex
        ? _categoryTabIndex
        : _homeTabIndex;

    // 화면 표시 이름을 실제 DB 카테고리 이름으로 변환
    String selectedCategory;

    switch (category) {
      case '전체':
      case '전체 상품':
        selectedCategory = '전체';
        break;

      case '탕/국':
        selectedCategory = '국·탕';
        break;

      case '찌개/조림':
        selectedCategory = '찌개·조림';
        break;

      case '밑반찬':
        selectedCategory = '밑반찬';
        break;

      case '김치':
        selectedCategory = '김치';
        break;

      // 148-3-7-10단계: 기타 카테고리 연결
      case '기타':
        selectedCategory = '기타';
        break;

      default:
        selectedCategory = '전체';
    }

    setState(() {
      _categoryReturnIndex = returnIndex;
      _selectedCategory = selectedCategory;

      // 일반 카테고리에서는 LIVE 상품만 보기 필터 해제
      _showOnlyLive = false;

      // 4번 인덱스: 카테고리별 상품 목록 화면
      _currentNavigationIndex = 4;
    });
  }

  // 146-2-6-2단계: 카테고리별 상품 목록 화면
  Widget _buildCategoryProductScreen() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 선택한 카테고리 제목
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Color(0xFF244C3A),
                  ),
                  onPressed: () {
                    setState(() {
                      _currentNavigationIndex = _categoryReturnIndex;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  _showOnlyLive
                      ? '🔴 라이브 방송 상품'
                      : (_selectedCategory == '전체'
                            ? '전체 상품'
                            : _selectedCategory),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF244C3A),
                  ),
                ),
              ],
            ),
          ),

          // 기존 상품 목록 재활용
          _buildFoodList(_selectedCategory),
        ],
      ),
    );
  }

  // 146-2-8-5-8단계: 지금 준비한 반찬 표시
  Widget _buildTodayPreparedBanchan() {
    return FutureBuilder<List<Banchan>>(
      future: _banchanFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        // 관리자가 오늘 준비한 반찬으로 선택한 상품만 표시
        // 147-2-4-6단계: 전체 선택 상품과 홈 표시 상품 분리
        final allTodayPrepared = snapshot.data!
            .where((banchan) => banchan.isTodayPrepared)
            .toList();

        final todayPrepared = allTodayPrepared.take(4).toList();

        // 5개 이상이면 더보기 카드 표시
        final hasMore = allTodayPrepared.length > 4;

        if (todayPrepared.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 147-1-1단계: 지금 준비된 반찬들 제목 디자인
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🍱 지금 준비된 반찬들',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF244C3A),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '젊은할미가 정성껏 준비한 반찬을 만나보세요.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF777777)),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 205,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: todayPrepared.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  // 147-2-4-6단계: 마지막 더보기 카드
                  if (hasMore && index == todayPrepared.length) {
                    return GestureDetector(
                      // 147-3-4-3단계: 지금 준비된 반찬 전체 목록으로 이동
                      onTap: () {
                        setState(() {
                          _showRecommendedSelection = false;
                          _currentNavigationIndex = 5;
                        });
                      },
                      child: Container(
                        width: 145,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 145,
                              height: 135,
                              // 전체반찬보기 버튼 배경(크림색)
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F4E9),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE7E0D1),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF244C3A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    '준비된 반찬\n더 보기',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF244C3A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '총 ${allTodayPrepared.length}개 반찬',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF777777),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final banchan = todayPrepared[index];

                  // 149-7-8단계: 홈 이미지 URL 확인
                  debugPrint('🖼️ 지금 준비된 반찬 이미지 URL: ${banchan.imageUrl}');

                  return Container(
                    width: 145,
                    margin: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BanchanDetailScreen(banchan: banchan),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),

                            child: CachedNetworkImage(
                              // 149-7-10단계: 상대경로 이미지 URL 처리
                              imageUrl: banchan.imageUrl.startsWith('http')
                                  ? banchan.imageUrl
                                  : 'http://192.168.45.150:8080${banchan.imageUrl}',
                              width: 145,
                              height: 135,
                              fit: BoxFit.cover,

                              // 149-6-7단계: 지금 준비된 반찬 이미지 캐싱
                              placeholder: (context, url) {
                                return Container(
                                  width: 145,
                                  height: 135,
                                  color: const Color(0xFFF8F4E9),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF244C3A),
                                    ),
                                  ),
                                );
                              },

                              errorWidget: (context, url, error) {
                                return Container(
                                  width: 145,
                                  height: 135,
                                  color: Colors.grey.shade200,
                                  child: const Icon(
                                    Icons.restaurant,
                                    color: Color(0xFFF47B08),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            banchan.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF244C3A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${banchan.price}원',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF47B08),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // 카테고리별 반찬 목록을 그려주는 FutureBuilder + GridView 함수
  Widget _buildFoodList(
    String category, {
    bool onlyTodayPrepared = false,
    bool onlyRecommended = false,
  }) {
    return FutureBuilder<List<Banchan>>(
      future: _banchanFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('오류 발생:\n${snapshot.error}'));
        }
        if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(child: Text('맛있는 반찬을 준비 중입니다.'));
        }

        // 1차 필터링: 카테고리
        List<Banchan> filteredList = snapshot.data!;
        if (category != '전체') {
          filteredList = filteredList
              .where((item) => item.category == category)
              .toList();
        }

        // 2차 필터링: 라이브
        // 147-3-5단계: 선택 반찬 전체 목록에서는 라이브 필터 제외
        if (_showOnlyLive && !onlyTodayPrepared && !onlyRecommended) {
          filteredList = filteredList
              .where((item) => item.isLiveProduct == true)
              .toList();
        }

        // 147-2-4-2단계: 관리자가 선택한 반찬 필터
        if (onlyTodayPrepared) {
          filteredList = filteredList
              .where((item) => item.isTodayPrepared)
              .toList();
        }

        if (onlyRecommended) {
          filteredList = filteredList
              .where((item) => item.isRecommended)
              .toList();
        }

        if (filteredList.isEmpty) {
          return Center(
            child: Text(
              _showOnlyLive
                  ? '현재 이 카테고리에 방송 중인 반찬이 없습니더. 👵'
                  : '[$category] 카테고리에 준비된 반찬이 없구만유.',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return GridView.builder(
          // 143-7-4: 부모 스크롤 화면에서 스크롤을 관리하도록 준비
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(12.0),

          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final banchan = filteredList[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BanchanDetailScreen(banchan: banchan),
                  ),
                );
              },
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final imagePath = banchan.imageUrl.trim();
                              final uri = Uri.tryParse(imagePath);

                              // 상품 대표사진은 /images/products/ 경로만 허용
                              final isProductImage =
                                  uri != null &&
                                  uri.path.startsWith('/images/products/');

                              if (!isProductImage) {
                                return Container(
                                  width: double.infinity,
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(
                                      Icons.fastfood,
                                      color: Colors.orange,
                                      size: 40,
                                    ),
                                  ),
                                );
                              }

                              final imageUrl = uri.hasScheme
                                  ? imagePath
                                  : '${ApiConfig.baseUrl}$imagePath';

                              return CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,

                                // 149-6-9단계: 전체 상품 이미지 디스크 캐싱
                                placeholder: (context, url) {
                                  return Container(
                                    color: const Color(0xFFF8F4E9),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF244C3A),
                                      ),
                                    ),
                                  );
                                },

                                errorWidget: (context, url, error) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(
                                        Icons.fastfood,
                                        color: Colors.orange,
                                        size: 40,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  banchan.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                banchan.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${banchan.price}원',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (banchan.isLiveProduct == true)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '방송중',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 147-2-4-5단계: 지금 준비된 반찬 전체 목록 화면
  // 147-3-4-4단계: 준비된 반찬 / 추천 반찬 전체 목록 공용 화면
  Widget _buildSelectedBanchanScreen() {
    final bool isRecommended = _showRecommendedSelection;

    final String title = isRecommended ? '처음이라면, 이 반찬부터!' : '지금 준비된 반찬들';

    final String subtitle = isRecommended
        ? '젊은할미가 자신 있게 추천하는 반찬이에요.'
        : '젊은할미가 정성껏 준비한 반찬을 만나보세요.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF244C3A)),
                onPressed: () {
                  setState(() {
                    _currentNavigationIndex = _homeTabIndex;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF244C3A),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: _buildFoodList(
              '전체',
              onlyTodayPrepared: !isRecommended,
              onlyRecommended: isRecommended,
            ),
          ),
        ),
      ],
    );
  }
}
