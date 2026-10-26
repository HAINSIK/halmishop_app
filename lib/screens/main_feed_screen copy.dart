// lib/screens/main_feed_screen.dart 전체 교체
import 'package:flutter/material.dart';
import 'package:halmishop_app/screens/banchan_detail_screen.dart';
import '../models/banchan_model.dart';
import '../services/banchan_service.dart';
import 'order_list_screen.dart';
import 'cart_screen.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  State<MainFeedScreen> createState() => _MainFeedScreenState();
}

class _MainFeedScreenState extends State<MainFeedScreen> {
  // 💡 메인 하단 네비게이션 인덱스
  int _currentNavigationIndex = 0;

  // 카테고리 종류 정의
  final List<String> categories = ['전체', '국·탕', '찌개·조림', '김치', '밑반찬'];
  final BanchanService _banchanService = BanchanService();
  late Future<List<Banchan>> _banchanFuture;

  // 지금 방송중인 상품만 보기 필터 스위치 상태
  bool _showOnlyLive = false;

  @override
  void initState() {
    super.initState();
    _banchanFuture = _banchanService.fetchBanchanList();
  }

  @override
  Widget build(BuildContext context) {
    // 💡 1. 하단 메뉴 선택에 따라 다른 화면을 보여줍니다.
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 젊은할미반찬 👵❤️', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orangeAccent,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const OrderListScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      
      // 💡 현재 선택된 하단 메뉴가 '장터(0번)'일 때만 카테고리 탭 화면을 보여주고, 나머지는 임시 화면 전환
      body: IndexedStack(
        index: _currentNavigationIndex,
        children: [
          _buildMarketHomeScreen(), // 0: 장터 홈 (카테고리 탭 포함)
          const CartScreen(),
          const Center(child: Text('📋 주문 내역 화면 (준비중)', style: TextStyle(fontSize: 18))), // 2: 주문내역
        ],
      ),

      // 💡 2. [진짜 하단 바] 여기에 장바구니와 다른 메뉴 버튼들이 들어갑니다!
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentNavigationIndex,
        onTap: (index) {
          setState(() {
            _currentNavigationIndex = index;
          });
        },
        selectedItemColor: Colors.orange.shade800,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: '장터홈'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: '장바구니'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: '주문내역'),
        ],
      ),
    );
  }

  // 💡 3. 장터 홈 화면 구조 (스위치 + 카테고리 탭 바 + 상품 그리드 목록)
  Widget _buildMarketHomeScreen() {
    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          // 라이브 상품만 보기 스위치 바
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            color: Colors.orange.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.live_tv, color: Colors.redAccent, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      _showOnlyLive ? '🔴 지금 방송중인 주인공 반찬만 보는 중' : '모든 맛있는 반찬 다 보는 중',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Switch(
                  value: _showOnlyLive,
                  activeColor: Colors.redAccent,
                  onChanged: (bool value) {
                    setState(() {
                      _showOnlyLive = value;
                    });
                  },
                ),
              ],
            ),
          ),

          // 💡 카테고리 탭 바를 본문 상단에 배치 (너비에 맞게 딱 균등 분할 정렬)
          Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: false, // 💥 화면 너비에 맞게 균등 분할하여 치우침 해결!
              indicatorColor: Colors.orangeAccent,
              indicatorWeight: 3,
              labelColor: Colors.orangeAccent,
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              tabs: categories.map((String name) => Tab(text: name)).toList(),
            ),
          ),

          // 카테고리별 그리드 목록 영역
          Expanded(
            child: TabBarView(
              children: categories.map((String category) {
                return _buildFoodList(category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 카테고리별 반찬 목록을 그려주는 FutureBuilder + GridView 함수
  Widget _buildFoodList(String category) {
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
          filteredList = filteredList.where((item) => item.category == category).toList();
        }

        // 2차 필터링: 라이브
        if (_showOnlyLive) {
          filteredList = filteredList.where((item) => item.isLiveProduct == true).toList();
        }

        if (filteredList.isEmpty) {
          return Center(
            child: Text(
              _showOnlyLive 
                  ? '현재 이 카테고리에 방송 중인 반찬이 없습니더. 👵' 
                  : '[$category] 카테고리에 준비된 반찬이 없구만유.',
              style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          );
        }

        return GridView.builder(
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
                  MaterialPageRoute(builder: (context) => BanchanDetailScreen(banchan: banchan)),
                );
              },
              child: Card(
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Image.network(
                            banchan.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(Icons.fastfood, color: Colors.orange, size: 40),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  banchan.category,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                banchan.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
}
