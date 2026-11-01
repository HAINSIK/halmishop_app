// lib/screens/banchan_detail_screen.dart 전체 교체
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/banchan_model.dart';
import '../cart_provider.dart';
import 'order_list_screen.dart'; // 👈 주문 완료 후 주문내역 이동을 위해 추가

class BanchanDetailScreen extends StatefulWidget {
  final Banchan banchan;

  const BanchanDetailScreen({super.key, required this.banchan});

  @override
  State<BanchanDetailScreen> createState() => _BanchanDetailScreenState();
}

class _BanchanDetailScreenState extends State<BanchanDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.banchan.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orangeAccent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 반찬 대형 이미지
            Image.network(
              widget.banchan.imageUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 300,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.fastfood, color: Colors.orange, size: 80),
                ),
              ),
            ),
            
            // 반찬 텍스트 정보들
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.banchan.category,
                      style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.banchan.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.banchan.price}원',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),
                  const Text(
                    '👵 할미의 정성이 듬뿍 들어간 손맛 반찬이구만유!\n매일 새벽 시장에서 엄선해 온 싱싱한 재료로 정성껏 버무렸으니 믿고 맛나게 잡숴보셔유. 조미료는 일절 쓰지 않아 건강에도 아주 좋당깨!',
                    style: TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 💡 하단 고정 버튼 영역
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // (1) 장바구니 담기 버튼
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: Colors.orangeAccent, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: Colors.orange.shade50.withOpacity(0.5),
              ),
              onPressed: () {
                context.read<CartProvider>().addBanchan(widget.banchan);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('👵 ${widget.banchan.name}이(가) 장바구니에 담겼구만유!'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('🛒 장바구니 담기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
            ),
            
            const SizedBox(height: 12),
            
            // (2) 바로 주문하기 버튼 (진하고 쨍한 입체 주황 스타일)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                minimumSize: const Size(double.infinity, 52),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                // 💡 1. 주소 및 입금자를 입력받을 전용 컨트롤러 선언
                final TextEditingController addressController = TextEditingController();
                final TextEditingController depositorController = TextEditingController();

                // 💡 2. 정보 입력용 다이얼로그 팝업 열기
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (dialogContext) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('👵 바로 주문 정보 입력', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('"${widget.banchan.name}"을(를)\n어디로 보내드릴까유?'),
                        const SizedBox(height: 16),
                        TextField(
                          controller: depositorController,
                          decoration: const InputDecoration(
                            labelText: '입금자명',
                            hintText: '예: 홍길동',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person, color: Colors.orangeAccent),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: '받으실 배송지 주소',
                            hintText: '상세주소까지 적어주셔유',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.home, color: Colors.orangeAccent),
                          ),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('취소', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        onPressed: () async {
                          if (depositorController.text.trim().isEmpty || addressController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('⚠️ 입금자명과 배송지를 모두 적어주셔야 합니더!')),
                            );
                            return;
                          }

                          // 임시로 장바구니에 이 상품만 단독으로 들어있는 상태처럼 전송하기 위해 
                          // 먼저 장바구니에 해당 상품을 세팅하고 함수를 호출하는 방식으로 조립합니다.
                          final cartProvider = context.read<CartProvider>();
                          cartProvider.addBanchan(widget.banchan);

                          // 💥 [버그 해결] 주소와 입금자를 정확하게 아규먼트로 전달하여 호출합니다!
                          bool isSuccess = await cartProvider.placeOrderFromCartWithDetails(
                            address: addressController.text.trim(),
                            depositor: depositorController.text.trim(),
                          );

                          if (isSuccess) {
                            Navigator.pop(dialogContext); // 입력 팝업 닫기
                            Navigator.pop(context);       // 상세 페이지 닫기 (메인으로 이동)
                            
                            // 최종 주문 완료 팝업 선물하기
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Text('🎉 바로 주문 접수 완료!', style: TextStyle(fontWeight: FontWeight.bold)),
                                content: Text('${widget.banchan.name} 주문이 정상 접수되었구만유!\n맛나게 버무려 보낼 테니 주문 내역을 확인해 보셔유.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context); // 팝업 닫기
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const OrderListScreen()),
                                      );
                                    },
                                    child: const Text('확인 완료', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('❌ 서버 저장 실패! 스프링 로그를 확인해 주셔유.'),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          '👵 주문하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: const Text(
                '👵 바로 주문하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
