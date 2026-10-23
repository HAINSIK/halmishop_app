// lib/screens/banchan_detail_screen.dart 생성
import 'package:flutter/material.dart';

import '../models/banchan_model.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class BanchanDetailScreen extends StatefulWidget {
  final Banchan banchan;

  const BanchanDetailScreen({super.key, required this.banchan});

  @override
  State<BanchanDetailScreen> createState() => _BanchanDetailScreenState();
}

class _BanchanDetailScreenState extends State<BanchanDetailScreen> {
  final OrderService _orderService = OrderService();
  int _quantity = 1; // 기본 수량 1개
  bool _isOrdering = false;

   // lib/screens/banchan_detail_screen.dart 내부의 _handleOrder 함수만 교체
  void _handleOrder() async {
    print('🛒 바로 주문하기 버튼 클릭됨!');

    print('🚨 [플러터 원본 검증] 현재 반찬의 고유 ID: ${widget.banchan.id}'); 
    print('🚨 [플러터 원본 검증] 현재 반찬의 이름: ${widget.banchan.name}'); 

    setState(() => _isOrdering = true);

    // 💡 .toInt()를 명시하여 확실하게 int 타입으로 고정시킵니다.
    final int calculatedTotalPrice = (widget.banchan.price * _quantity).toInt();

    try {
      // 이제 모델의 int totalPrice와 완벽하게 타입이 일치하므로 에러가 나지 않습니다.
      final request = OrderRequest(
        productName: widget.banchan.name,
        totalPrice: calculatedTotalPrice, // ◀ 타입 일치 완료
        memberId: 1, 
        deliveryAddress: "부산시 강서구 명지동 젊은할미반찬가게", 
        depositorName: "하인식", 
        
      );

      print('📦 주문 요청 데이터(totalPrice 포함): ${request.toJson()}');

      final success = await _orderService.createOrder(request);
      print('🔔 주문 API 결과: $success');

      setState(() => _isOrdering = false);

      if (success) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('주문 완료 🎉'),
            content: Text('👵 할미가 맛있게 준비해서 보내줄게!\n(총 결제금액: $calculatedTotalPrice원)'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); 
                  Navigator.pop(context); 
                },
                child: const Text('확인'),
              )
            ],
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('서버 응답 오류로 주문에 실패했습니다. 😢')),
        );
      }
    } catch (e) {
      print('❌ 주문 처리 중 에러 발생: $e');
      setState(() => _isOrdering = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.banchan.price * _quantity;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.banchan.name),
        backgroundColor: Colors.orangeAccent,
      ),
      body: _isOrdering
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    widget.banchan.imageUrl,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '[${widget.banchan.category}]',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.banchan.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.banchan.price}원',
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 30),
                        const Text(
                          '수량 선택',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                            ),
                            Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => setState(() => _quantity++),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '총 결제 금액',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$totalPrice원',
                              style: const TextStyle(
                                fontSize: 22,
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _handleOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            '바로 주문하기',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
