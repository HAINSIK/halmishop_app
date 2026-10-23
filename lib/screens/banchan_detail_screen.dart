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

  void _handleOrder() async {
    setState(() => _isOrdering = true);

    final request = OrderRequest(
      productName: widget.banchan.id,
      totalPrice: _quantity,
    );

    final success = await _orderService.createOrder(request);

    setState(() => _isOrdering = false);

    if (success) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('주문 완료 🎉'),
          content: Text(
            '👵 할미가 맛있게 준비해서 보내줄게!\n(${widget.banchan.name} $_quantity개)',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 팝업 닫기
                Navigator.pop(context); // 메인 피드로 돌아가기
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주문에 실패했습니다. 서버 로그를 확인해주세요.')),
      );
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
