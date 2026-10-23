import 'package:flutter/material.dart';

import '../models/banchan_model.dart';
import '../services/banchan_service.dart';
import 'banchan_detail_screen.dart';

class MainFeedScreen extends StatefulWidget {
  const MainFeedScreen({super.key});

  @override
  State<MainFeedScreen> createState() => _MainFeedScreenState();
}

class _MainFeedScreenState extends State<MainFeedScreen> {
  final BanchanService _banchanService = BanchanService();
  late Future<List<Banchan>> _banchanFuture;

  @override
  void initState() {
    super.initState();
    _banchanFuture = _banchanService.fetchBanchanList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 젊은할미반찬 👵❤️'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: FutureBuilder<List<Banchan>>(
        future: _banchanFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('❌ 화면 렌더링 중 에러 발생: ${snapshot.error}');
            return Center(child: Text('데이터 처리 중 오류 발생:\n${snapshot.error}'));
          }

          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('맛있는 반찬을 준비 중입니다. 잠시만 기다려주세요!'));
          }

          // 💡 필터링을 지우고 모든 반찬 데이터를 다 가져옵니다!
          final banchanList = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: banchanList.length,
            itemBuilder: (context, index) {
              final banchan = banchanList[index];

              // 💡 여기에서 GestureDetector로 Card를 감싸서 클릭 이벤트를 만듭니다.
              return GestureDetector(
                onTap: () {
                  // 카드를 누르면 상세 화면으로 이동하면서 클릭한 반찬(banchan) 데이터를 넘겨줍니다.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          BanchanDetailScreen(banchan: banchan),
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
                            child: Image.network(
                              banchan.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.grey,
                                    child: const Center(
                                      child: Icon(
                                        Icons.fastfood,
                                        color: Colors.orange,
                                        size: 40,
                                      ),
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
                                const SizedBox(height: 4),
                                Text(
                                  banchan.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${banchan.price}원',
                                  style: const TextStyle(
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (banchan.isLiveProduct)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.fiber_manual_record,
                                  color: Colors.white,
                                  size: 10,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '방송중 상품',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ); // GestureDetector 닫기
            },
          );
        },
      ),
    );
  }
}
