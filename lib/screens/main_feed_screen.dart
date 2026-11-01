// // lib/screens/main_feed_screen.dart 전체 교체
// import 'package:flutter/material.dart';

// import '../models/banchan_model.dart';
// import '../services/banchan_service.dart';
// import 'banchan_detail_screen.dart';
// import 'order_list_screen.dart';

// class MainFeedScreen extends StatefulWidget {
//   const MainFeedScreen({super.key});

//   @override
//   State<MainFeedScreen> createState() => _MainFeedScreenState();
// }

// class _MainFeedScreenState extends State<MainFeedScreen> {
  
//   //카테고리 정의
//   final List<String> categories = ['전체', '국·탕', '찌개·조림', '김치', '밑반찬'];
//   final BanchanService _banchanService = BanchanService();
//   late Future<List<Banchan>> _banchanFuture;

//   // 💡 지금 방송중인 상품만 보기 필터 스위치 상태 변수
//   bool _showOnlyLive = false;

//   @override
//   void initState() {
//     super.initState();
//     _banchanFuture = _banchanService.fetchBanchanList();
//   }
  

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('오늘의 젊은할미반찬 👵❤️'),
//         backgroundColor: Colors.orangeAccent,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.assignment, color: Colors.white, size: 28),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => const OrderListScreen(),
//                 ),
//               );
//             },
//           ),
//           const SizedBox(width: 8),
//         ],
//       ),
//       body: Column(
//         children: [
//           // 💡 라이브 상품만 쏙 걸러서 볼 수 있는 정갈한 주황색 스위치 바 배치
//           Container(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 16.0,
//               vertical: 10.0,
//             ),
//             color: Colors.orange.shade50,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Row(
//                   children: [
//                     const Icon(
//                       Icons.live_tv,
//                       color: Colors.redAccent,
//                       size: 22,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       _showOnlyLive
//                           ? '🔴 지금 방송중인 주인공 반찬만 보는 중'
//                           : '모든 맛있는 반찬 다 보는 중',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//                 // 토글 스위치 단추
//                 Switch(
//                   value: _showOnlyLive,
//                   activeColor: Colors.redAccent,
//                   onChanged: (bool value) {
//                     setState(() {
//                       _showOnlyLive = value;
//                     });
//                   },
//                 ),
//               ],
//             ),
//           ),

//           // 아래쪽 영역을 그리드뷰로 가득 채우기
//           Expanded(
//             child: FutureBuilder<List<Banchan>>(
//               future: _banchanFuture, // 💡 이제 괄호나 하단 오타가 잡혀서 에러가 나지 않습니다.
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (snapshot.hasError) {
//                   return Center(child: Text('오류 발생:\n${snapshot.error}'));
//                 }
//                 if (snapshot.data == null || snapshot.data!.isEmpty) {
//                   return const Center(child: Text('맛있는 반찬을 준비 중입니다.'));
//                 }

//                 // 💡 스위치가 켜져 있으면 라이브 상품만 필터링, 꺼져 있으면 전체 로드
//                 final banchanList = _showOnlyLive
//                     ? snapshot.data!
//                           .where((item) => item.isLiveProduct == true)
//                           .toList()
//                     : snapshot.data!;

//                 if (banchanList.isEmpty) {
//                   return const Center(
//                     child: Text(
//                       '현재 방송 중인 반찬이 없습니더. 👵',
//                       style: TextStyle(fontSize: 16, color: Colors.grey),
//                     ),
//                   );
//                 }

//                 return GridView.builder(
//                   padding: const EdgeInsets.all(12.0),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     childAspectRatio: 0.75,
//                     crossAxisSpacing: 12,
//                     mainAxisSpacing: 12,
//                   ),
//                   itemCount: banchanList.length,
//                   itemBuilder: (context, index) {
//                     final banchan = banchanList[index];
//                     return GestureDetector(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) =>
//                                 BanchanDetailScreen(banchan: banchan),
//                           ),
//                         );
//                       },
//                       child: Card(
//                         clipBehavior: Clip.antiAlias,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         elevation: 3,
//                         child: Stack(
//                           children: [
//                             Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Expanded(
//                                   child: Image.network(
//                                     banchan.imageUrl,
//                                     width: double.infinity,
//                                     fit: BoxFit.cover,
//                                     errorBuilder:
//                                         (context, error, stackTrace) =>
//                                             Container(
//                                               color: Colors.grey,
//                                               child: const Center(
//                                                 child: Icon(
//                                                   Icons.fastfood,
//                                                   color: Colors.orange,
//                                                   size: 40,
//                                                 ),
//                                               ),
//                                             ),
//                                   ),
//                                 ),
//                                 Padding(
//                                   padding: const EdgeInsets.all(8.0),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 6,
//                                           vertical: 2,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: Colors.orange,
//                                           borderRadius: BorderRadius.circular(
//                                             4,
//                                           ),
//                                         ),
//                                         child: Text(
//                                           banchan.category,
//                                           style: const TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 10,
//                                             fontWeight: FontWeight.bold,
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Text(
//                                         banchan.name,
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 15,
//                                         ),
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                       const SizedBox(height: 6),
//                                       // 💡 에러의 원인이 되던 문자열 안의 역슬래시(\)를 완전히 수정했습니다.
//                                       Text(
//                                         '${banchan.price}원',
//                                         style: const TextStyle(
//                                           color: Colors.deepOrange,
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 14,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             if (banchan.isLiveProduct)
//                               Positioned(
//                                 top: 8,
//                                 left: 8,
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(
//                                     horizontal: 8,
//                                     vertical: 4,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: Colors.redAccent,
//                                     borderRadius: BorderRadius.circular(20),
//                                   ),
//                                   child: const Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       Icon(
//                                         Icons.fiber_manual_record,
//                                         color: Colors.white,
//                                         size: 10,
//                                       ),
//                                       SizedBox(width: 4),
//                                       Text(
//                                         '방송중 상품',
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontSize: 10,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
