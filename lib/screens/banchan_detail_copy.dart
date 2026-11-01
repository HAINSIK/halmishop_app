// import 'package:flutter/material.dart';
// import 'package:halmishop_app/models/banchan_model.dart';
// import 'package:halmishop_app/screens/cart_screen.dart';
// import 'package:provider/provider.dart';
// import 'package:web/web.dart' as web;

// import '../models/order_model.dart';
// import '../services/order_service.dart';
// import 'order_list_screen.dart';

// import 'package:halmishop_app/cart_provider.dart';

// class BanchanDetailScreen extends StatefulWidget {
//   final Banchan banchan;

//   const BanchanDetailScreen({super.key, required this.banchan});

//   @override
//   State createState() => _BanchanDetailScreenState();
// }

// class _BanchanDetailScreenState extends State<BanchanDetailScreen> {
//   final OrderService _orderService = OrderService();
//   final _formKey = GlobalKey<FormState>(); // 💡 FormState 제네릭 명시 완료

//   final _addressController = TextEditingController();
//   final _depositorController = TextEditingController();

//   int _quantity = 1;
//   bool _isOrdering = false;

//   @override
//   void dispose() {
//     _addressController.dispose();
//     _depositorController.dispose();
//     super.dispose();
//   }

//   void _handleOrder() async {
//     if (!_formKey.currentState!.validate()) return; // 💡 괄호 오타 수정 완료

//     setState(() => _isOrdering = true);

//     // 💡 widget.banchan 구조로 명확하게 연산하도록 고정했습니다.
//     final int calculatedTotalPrice = (widget.banchan.price * _quantity).toInt();

//     try {
//       final savedMemberIdStr =
//           web.window.localStorage.getItem('member_id') ?? '1';
//       final int realMemberId = int.tryParse(savedMemberIdStr) ?? 1;

//       final request = OrderRequest(
//         memberId: realMemberId,
//         productName: widget.banchan.name, // 💡 widget. 추가 완료
//         totalPrice: calculatedTotalPrice,
//         deliveryAddress: _addressController.text.trim(),
//         depositorName: _depositorController.text.trim(),
//       );

//       print('📦 주문 요청 데이터(실시간 회원 ID 반영): ${request.toJson()}');

//       final success = await _orderService.createOrder(request);
//       print('🔔 주문 API 결과: $success');

//       setState(() => _isOrdering = false);

//       if (success) {
//         if (!mounted) return;
//         showDialog(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('주문 완료 🎉'),
//             content: Text(
//               '👵 할미가 맛있게 준비해서 보내줄게!\n(총 결제금액: $calculatedTotalPrice원)',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(
//                       builder: (context) => const OrderListScreen(),
//                     ),
//                   );
//                 },
//                 child: const Text('주문 장부 확인하기'),
//               ),
//             ],
//           ),
//         );
//       } else {
//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('서버 응답 오류로 주문에 실패했습니다. 😢')),
//         );
//       }
//     } catch (e) {
//       print('❌ 주문 처리 중 에러 발생: $e');
//       setState(() => _isOrdering = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final totalPrice = widget.banchan.price * _quantity; // 💡 widget. 추가 완료

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.banchan.name), // 💡 widget. 추가 완료
//         backgroundColor: Colors.orangeAccent,
//       ),
//       body: _isOrdering
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Image.network(
//                       widget
//                           .banchan
//                           .imageUrl, // 💡 소문자 imageurl 규격 및 widget. 고정
//                       width: double.infinity,
//                       height: 300,
//                       fit: BoxFit.cover,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       '[${widget.banchan.category}]', // 💡 widget. 추가 완료
//                       style: const TextStyle(
//                         color: Colors.orange,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '[${widget.banchan.name}]', // 💡 widget. 추가 완료
//                       style: const TextStyle(
//                         fontSize: 26,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '${widget.banchan.price}원', // 💡 widget. 추가 완료
//                       style: const TextStyle(
//                         fontSize: 22,
//                         color: Colors.deepOrange,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const Divider(height: 40),
//                     const Text(
//                       '수량 선택',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         IconButton(
//                           icon: const Icon(
//                             Icons.remove_circle_outline,
//                             size: 28,
//                           ),
//                           onPressed: _quantity > 1
//                               ? () => setState(() => _quantity--)
//                               : null,
//                         ),
//                         Text(
//                           '$_quantity',
//                           style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.add_circle_outline, size: 28),
//                           onPressed: () => setState(() => _quantity++),
//                         ),
//                       ],
//                     ),
//                     const Divider(height: 40),

//                     const Text(
//                       '🚚 반찬 받으실 배송지 주소',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextFormField(
//                       controller: _addressController,
//                       decoration: const InputDecoration(
//                         hintText: '예시) 부산시 강서구 명지동 할미아파트 101동',
//                         border: OutlineInputBorder(),
//                         prefixIcon: Icon(
//                           Icons.location_on,
//                           color: Colors.orange,
//                         ),
//                       ),
//                       validator: (v) =>
//                           v!.trim().isEmpty ? '배송지 주소를 꼭 적어주세요!' : null,
//                     ),
//                     const SizedBox(height: 24),

//                     const Text(
//                       '💰 무통장 입금자명',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     TextFormField(
//                       controller: _depositorController,
//                       decoration: const InputDecoration(
//                         hintText: '실제 송금하시는 분의 성함을 적어주세요.',
//                         border: OutlineInputBorder(),
//                         prefixIcon: Icon(Icons.person, color: Colors.orange),
//                       ),
//                       validator: (v) =>
//                           v!.trim().isEmpty ? '입금자명을 꼭 적어주세요!' : null,
//                     ),

//                     const Divider(height: 40),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text(
//                           '총 결제 금액',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         Text(
//                           '$totalPrice원',
//                           style: const TextStyle(
//                             fontSize: 24,
//                             color: Colors.redAccent,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ), // 💡 변수 가공 출력부 에러 완전 수정
//                       ],
//                     ),
//                     const SizedBox(height: 30),
//                     ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orangeAccent,
//                         minimumSize: const Size(double.infinity, 50),
//                       ),
//                       onPressed: () {
//                         // 👵 할미샵 장바구니 창고에 이 반찬을 쏙 집어넣기!
//                         context.read<CartProvider>().addBanchan(widget.banchan);

//                         // 담겼다고 알림 스낵바 띄워주기
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               '👵 ${widget.banchan.name}이(가) 장바구니에 담겼구만유!',
//                             ),
//                             duration: const Duration(seconds: 2),
//                             backgroundColor: Colors.orange,
//                             action: SnackBarAction(
//                               label: '보러가기',
//                               textColor: Colors.white,
//                               onPressed: () {
//                                 // 필요하다면 여기서 장바구니 탭으로 바로 이동하게 할 수도 있어유
//                               },
//                             ),
//                           ),
//                         );
//                       },
//                       child: const Text(
//                         '장바구니 담기',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                     ElevatedButton(
//                       onPressed: _handleOrder,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                         minimumSize: const Size(double.infinity, 55),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                       ),
//                       child: const Text(
//                         '바로 주문하기',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }
