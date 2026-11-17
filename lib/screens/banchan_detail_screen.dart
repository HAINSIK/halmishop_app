// lib/screens/banchan_detail_screen.dart 전체 교체
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/banchan_model.dart';
import '../cart_provider.dart';
import 'order_list_screen.dart'; // 👈 주문 완료 후 주문내역 이동을 위해 추가
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/api_config.dart';

class BanchanDetailScreen extends StatefulWidget {
  final Banchan banchan;

  const BanchanDetailScreen({super.key, required this.banchan});

  @override
  State<BanchanDetailScreen> createState() => _BanchanDetailScreenState();
}

class _BanchanDetailScreenState extends State<BanchanDetailScreen> {
  // 148-5-8-4단계: 상세사진 조회 결과 보관
  late Future<List<String>> _detailImagesFuture;

  @override
  void initState() {
    super.initState();
    _detailImagesFuture = _fetchDetailImages();
  }

  // 148-5-8-2단계: 상품 상세사진 목록 조회
  Future<List<String>> _fetchDetailImages() async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/api/products/${widget.banchan.id}/images',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return [];
      }

      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

      return data
          .map((item) => item['imageUrl']?.toString() ?? '')
          .where((imageUrl) => imageUrl.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('상세사진 조회 오류: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.banchan.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orangeAccent,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 반찬 대형 이미지

            // 148-3-17-31단계: 상품 상세 대표사진 경로 처리
            Builder(
              builder: (context) {
                final imagePath = widget.banchan.imageUrl.trim();
                final uri = Uri.tryParse(imagePath);

                // images/products 폴더의 사진만 표시
                final isProductImage =
                    uri != null && uri.path.startsWith('/images/products/');

                if (!isProductImage) {
                  return Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.fastfood,
                        color: Colors.orange,
                        size: 80,
                      ),
                    ),
                  );
                }

                // 전체 URL은 그대로 사용, 상대경로는 서버 주소 추가
                final imageUrl = uri.hasScheme
                    ? imagePath
                    : '${ApiConfig.baseUrl}$imagePath';

                return Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(
                        Icons.fastfood,
                        color: Colors.orange,
                        size: 80,
                      ),
                    ),
                  ),
                );
              },
            ),

            // 반찬 텍스트 정보들
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.banchan.category,
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1),
                  const SizedBox(height: 16),

                  // 148-4-4단계: 상품별 상세 설명 표시

                  // 148-4-5단계: 젊은할미 상품 설명 디자인
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF2E5CF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '상품 설명',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F4D3A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.banchan.description.trim().isNotEmpty
                              ? widget.banchan.description
                              : '등록된 상품 설명이 없습니다.',
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color: Colors.black87,
                          ),
                        ),
                        // 148-5-8-3단계: 상품 상세사진 세로 표시
                        FutureBuilder<List<String>>(
                          future: _detailImagesFuture,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            final images = snapshot.data!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24),
                                const Text(
                                  '상품 상세사진',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F4D3A),
                                  ),
                                ),
                                const SizedBox(height: 14),

                                ...images.map((imagePath) {
                                  final uri = Uri.tryParse(imagePath);

                                  if (uri == null ||
                                      !uri.path.startsWith(
                                        '/images/products/',
                                      )) {
                                    return const SizedBox.shrink();
                                  }

                                  final imageUrl = uri.hasScheme
                                      ? imagePath
                                      : '${ApiConfig.baseUrl}$imagePath';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      fit: BoxFit.fitWidth,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const SizedBox.shrink();
                                          },
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 💡 하단 고정 버튼 영역

      // 148-5-10-1단계: 갤럭시 하단 시스템 바 가림 방지
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 12.0,
            bottom: 12.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // (1) 장바구니 담기 버튼
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: Colors.orangeAccent, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: Colors.orange.shade50.withOpacity(0.5),
                ),
                onPressed: () {
                  context.read<CartProvider>().addBanchan(widget.banchan);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '👵 ${widget.banchan.name}이(가) 장바구니에 담겼구만유!',
                      ),
                      backgroundColor: Colors.orange,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(
                  '🛒 장바구니 담기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // (2) 바로 주문하기 버튼 (진하고 쨍한 입체 주황 스타일)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  minimumSize: const Size(double.infinity, 52),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  // 💡 1. 주소 및 입금자를 입력받을 전용 컨트롤러 선언
                  final TextEditingController addressController =
                      TextEditingController();
                  final TextEditingController depositorController =
                      TextEditingController();
                  final TextEditingController recipientNameController =
                      TextEditingController();

                  final TextEditingController recipientPhoneController =
                      TextEditingController();

                  // 💡 2. 정보 입력용 다이얼로그 팝업 열기
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (dialogContext) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        '👵 바로 주문 정보 입력',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      content: SingleChildScrollView(
                        child: Column(
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
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextField(
                              controller: recipientNameController,
                              decoration: const InputDecoration(
                                labelText: '받으시는 분 이름',
                                hintText: '예: 홍길동',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            TextField(
                              controller: recipientPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: '받으시는 분 연락처',
                                hintText: '예: 01012345678',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(
                                  Icons.phone,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: addressController,
                              decoration: const InputDecoration(
                                labelText: '받으실 배송지 주소',
                                hintText: '상세주소까지 적어주셔유',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(
                                  Icons.home,
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text(
                            '취소',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () async {
                            if (depositorController.text.trim().isEmpty ||
                                recipientNameController.text.trim().isEmpty ||
                                recipientPhoneController.text.trim().isEmpty ||
                                addressController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '⚠️ 입금자명, 받으시는 분, 연락처, 배송 주소를 모두 입력해주세요.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final recipientPhone = recipientPhoneController.text
                                .replaceAll(RegExp(r'[^0-9]'), '');

                            if (!RegExp(r'^01[016789]\d{7,8}$')
                                .hasMatch(recipientPhone)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '⚠️ 받으시는 분의 휴대폰 번호를 정확히 입력해주세요.',
                                  ),
                                ),
                              );
                              return;
                            }

                            // 현재 상세 화면에서 선택한 상품만 주문합니다.
                            // 기존 장바구니에 담긴 상품은 변경하지 않습니다.
                            final request = OrderRequest(
                              deliveryAddress: addressController.text.trim(),
                              depositorName: depositorController.text.trim(),
                              recipientName: recipientNameController.text
                                  .trim(),
                              recipientPhone: recipientPhone,
                              items: [
                                OrderItemRequest(
                                  id: widget.banchan.id,
                                  quantity: 1,
                                ),
                              ],
                            );

                            final orderService = OrderService();
                            final bool isSuccess = await orderService
                                .createOrder(request);

                            if (isSuccess) {
                              Navigator.pop(dialogContext); // 입력 팝업 닫기
                              Navigator.pop(context); // 상세 페이지 닫기 (메인으로 이동)

                              // 최종 주문 완료 팝업 선물하기
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text(
                                    '🎉 바로 주문 접수 완료!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: Text(
                                    '${widget.banchan.name} 주문이 정상 접수되었구만유!\n맛나게 버무려 보낼 테니 주문 내역을 확인해 보셔유.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context); // 팝업 닫기
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const OrderListScreen(),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        '확인 완료',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
      ),
    );
  }
}
