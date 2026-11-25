// lib/screens/banchan_detail_screen.dart 전체 교체
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'cart_screen.dart';
import '../models/banchan_model.dart';
import '../cart_provider.dart';
import 'order_list_screen.dart'; // 👈 주문 완료 후 주문내역 이동을 위해 추가
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/api_config.dart';

import 'package:halmishop_app/utils/image_url_helper.dart';

class BanchanDetailScreen extends StatefulWidget {
  final Banchan banchan;

  // 153-5-2-4단계: 메인 화면 탭 이동 요청
  final ValueChanged<int>? onNavigateToTab;

  const BanchanDetailScreen({
    super.key,
    required this.banchan,
    this.onNavigateToTab,
  });

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
      // 149-7-44-8-1단계: 상품 상세화면 상단 디자인
      appBar: AppBar(
        title: Text(
          widget.banchan.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF244C3A),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
                // 149-7-39단계: 공통 이미지 URL 처리
                final imageUrl = getImageUrl(imagePath);
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
                      color: const Color(0xFFE8F0E7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.banchan.category,
                      style: TextStyle(
                        color: const Color(0xFF244C3A),
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
                      color: const Color(0xFF244C3A),
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

                        // 153-6-3단계: 표시정보가 있는 경우에만 제목 표시
                        if ([
                          widget.banchan.foodType,
                          widget.banchan.netWeight,
                          widget.banchan.originInfo,
                          widget.banchan.ingredients,
                          widget.banchan.shelfLife,
                          widget.banchan.storageMethod,
                          widget.banchan.allergenInfo,
                          widget.banchan.manufacturer,
                        ].any((value) => value.trim().isNotEmpty)) ...[
                          const SizedBox(height: 24),
                          const Text(
                            '상품정보 제공고시',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F4D3A),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // 153-5-3-4단계: 상품 표시정보 데이터 연결
                        ...{
                              '식품유형': widget.banchan.foodType,
                              '내용량': widget.banchan.netWeight,
                              '원산지': widget.banchan.originInfo,
                              '원재료명': widget.banchan.ingredients,
                              '소비기한': widget.banchan.shelfLife,
                              '보관방법': widget.banchan.storageMethod,
                              '알레르기 정보': widget.banchan.allergenInfo,
                              '제조원': widget.banchan.manufacturer,
                            }.entries
                            .where((entry) => entry.value.trim().isNotEmpty)
                            .map(
                              (entry) => Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xFFE2E8DF),
                                    ),
                                  ),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        width: 105,
                                        padding: const EdgeInsets.all(12),
                                        color: const Color(0xFFF8F4E9),
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF244C3A),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            entry.value,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              height: 1.5,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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
          // 153-5-2-8단계: 주문 버튼 + 하단 내비게이션 세로 배치
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 장바구니 담기 / 바로 주문하기 버튼 가로 배치
              Row(
                children: [
                  // (1) 장바구니 담기 버튼
                  Expanded(
                    child: OutlinedButton(
                      // 149-7-44-2단계: 장바구니 담기 버튼 디자인
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        foregroundColor: const Color(0xFF244C3A),
                        backgroundColor: const Color(0xFFFFFBF5),
                        side: const BorderSide(
                          color: Color(0xFF244C3A),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        // 149-7-41단계: 판매중지 상품 장바구니 담기 차단
                        if (!widget.banchan.isSaleEnabled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('현재 판매가 중지된 상품입니다.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
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
                      // 153-10-1-1단계: 장바구니 버튼 가로 오버플로우 방지
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 21),
                            SizedBox(width: 9),
                            Text(
                              '장바구니 담기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 153-5-1-3단계: 바로 주문하기 버튼 가로 너비 설정
                  Expanded(
                    child: ElevatedButton(
                      // 149-7-44-3단계: 바로 주문하기 버튼 디자인
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF244C3A),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        if (!widget.banchan.isSaleEnabled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('현재 판매가 중지된 상품으로 주문할 수 없습니다.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // 149-7-44-4-3단계: 마지막 주문 배송정보 불러오기
                        final lastDeliveryInfo = await loadLastDeliveryInfo();

                        if (!mounted) return;
                        // 149-7-44-4-4단계: 바로 주문하기 배송정보 자동 입력
                        final TextEditingController addressController =
                            TextEditingController(
                              text: lastDeliveryInfo['address'] ?? '',
                            );

                        final TextEditingController depositorController =
                            TextEditingController(
                              text: lastDeliveryInfo['depositor'] ?? '',
                            );

                        final TextEditingController recipientNameController =
                            TextEditingController(
                              text: lastDeliveryInfo['recipientName'] ?? '',
                            );

                        final TextEditingController recipientPhoneController =
                            TextEditingController(
                              text: lastDeliveryInfo['recipientPhone'] ?? '',
                            );

                        // 149-7-44-9-2단계: 주문 요청사항 입력 컨트롤러
                        final TextEditingController orderRequestController =
                            TextEditingController();

                        // 💡 2. 정보 입력용 다이얼로그 팝업 열기
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (dialogContext) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            // 149-7-44-5-1단계: 바로 주문 배송정보 헤더
                            title: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF244C3A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_shipping_outlined,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          '배송정보 입력',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '젊은할미가 정성껏 준비해 보내드릴게요.',
                                    style: TextStyle(
                                      color: Color(0xFFF1EBDD),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '"${widget.banchan.name}"을(를)\n어디로 보내드릴까유?',
                                  ),
                                  const SizedBox(height: 16),
                                  // 149-7-44-5-2단계: 바로 주문 입금자명 입력창
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '입금자명',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF244C3A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  TextField(
                                    controller: depositorController,
                                    decoration: InputDecoration(
                                      hintText: '입금자명을 입력해 주세요',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      filled: true,
                                      fillColor: const Color(0xFFFFFBF5),
                                      prefixIcon: const Icon(
                                        Icons.account_balance_wallet_outlined,
                                        color: Color(0xFF244C3A),
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF607568),
                                        fontSize: 14,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8DF),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF244C3A),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // 149-7-44-5-3단계: 바로 주문 받으시는 분 이름 입력창
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '받으시는 분 이름',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF244C3A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  TextField(
                                    controller: recipientNameController,
                                    decoration: InputDecoration(
                                      hintText: '받으시는 분 이름을 입력해 주세요',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      filled: true,
                                      fillColor: const Color(0xFFFFFBF5),
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                        color: Color(0xFF244C3A),
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF607568),
                                        fontSize: 14,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8DF),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF244C3A),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // 149-7-44-5-4단계: 바로 주문 연락처 입력창
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '받으시는 분 연락처',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF244C3A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  TextField(
                                    controller: recipientPhoneController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: '휴대폰 번호를 입력해 주세요',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      filled: true,
                                      fillColor: const Color(0xFFFFFBF5),
                                      prefixIcon: const Icon(
                                        Icons.phone_outlined,
                                        color: Color(0xFF244C3A),
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF607568),
                                        fontSize: 14,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8DF),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF244C3A),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // 149-7-44-5-5단계: 바로 주문 배송지 주소 입력창
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '받으실 배송지 주소',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF244C3A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  TextField(
                                    controller: addressController,
                                    maxLines: 2,
                                    minLines: 1,
                                    keyboardType: TextInputType.streetAddress,
                                    decoration: InputDecoration(
                                      hintText: '도로명 주소와 상세주소를 입력해 주세요',
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                      filled: true,
                                      fillColor: const Color(0xFFFFFBF5),
                                      prefixIcon: const Icon(
                                        Icons.location_on_outlined,
                                        color: Color(0xFF244C3A),
                                      ),
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF607568),
                                        fontSize: 14,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8DF),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF244C3A),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // 149-7-44-9-3단계: 주문 요청사항 입력창
                                  const SizedBox(height: 16),

                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '주문 요청사항 (선택)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF244C3A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  TextField(
                                    controller: orderRequestController,
                                    maxLines: 3,
                                    minLines: 2,
                                    maxLength: 200,
                                    textInputAction: TextInputAction.newline,
                                    decoration: InputDecoration(
                                      hintText: '배송이나 주문 관련 요청사항을 입력해 주세요.\n예: 배송 전 연락 부탁드립니다.',
                                      hintMaxLines: 2,
                                      filled: true,
                                      fillColor: const Color(0xFFFFFBF5),
                                      contentPadding: const EdgeInsets.all(16),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE2E8DF),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFF244C3A),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // 149-7-44-5-6단계: 바로 주문 상품 및 금액 표시
                                  const SizedBox(height: 20),

                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F6F0),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFDCE6D9),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          '주문 상품',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF607568),
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                widget.banchan.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const Text(
                                              '1개',
                                              style: TextStyle(
                                                color: Color(0xFF607568),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const Divider(height: 24),

                                        Row(
                                          children: [
                                            const Expanded(
                                              child: Text(
                                                '최종 주문금액',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF607568),
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${widget.banchan.price}원',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF244C3A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              // 149-7-44-5-7단계: 바로 주문 취소 버튼
                              OutlinedButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF244C3A),
                                  side: const BorderSide(
                                    color: Color(0xFFB9CDBD),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  '취소',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              // 149-7-44-5-8단계: 바로 주문하기 버튼 디자인
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF244C3A),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () async {
                                  if (depositorController.text.trim().isEmpty ||
                                      recipientNameController.text
                                          .trim()
                                          .isEmpty ||
                                      recipientPhoneController.text
                                          .trim()
                                          .isEmpty ||
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

                                  final recipientPhone =
                                      recipientPhoneController.text.replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      );

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
                                  // 149-7-44-9-6단계: 바로 주문 요청사항 연결
                                  final request = OrderRequest(
                                    deliveryAddress: addressController.text
                                        .trim(),
                                    depositorName: depositorController.text
                                        .trim(),
                                    recipientName: recipientNameController.text
                                        .trim(),
                                    recipientPhone: recipientPhone,
                                    orderMemo: orderRequestController.text
                                        .trim(),
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
                                    try {
                                      await saveLastDeliveryInfo(
                                        depositor: depositorController.text
                                            .trim(),
                                        recipientName: recipientNameController
                                            .text
                                            .trim(),
                                        recipientPhone: recipientPhone,
                                        address: addressController.text.trim(),
                                      );
                                    } catch (e) {
                                      debugPrint('바로 주문 배송정보 저장 실패: $e');
                                    }

                                    if (!mounted || !dialogContext.mounted)
                                      return;

                                    Navigator.pop(
                                      dialogContext,
                                    ); // 배송정보 입력 팝업 닫기

                                    // 상품 상세화면은 주문 완료 팝업을 닫을 때까지 유지
                                    // 최종 주문 완료 팝업 선물하기
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        title: const Text(
                                          '🎉 바로 주문 접수 완료!',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: Text(
                                          '${widget.banchan.name} 주문이 정상 접수되었어요!\n 주문 내역을 확인해 보셔유.',
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
                                                color: const Color(0xFF244C3A),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '⚠️ ${orderService.lastOrderError ?? '주문 처리 중 문제가 발생했습니다.'}',
                                        ),
                                        backgroundColor: Colors.redAccent,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                },
                                child: const Text(
                                  '주문 접수하기',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      // 153-10-1-2단계: 바로 주문하기 버튼 가로 오버플로우 방지
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_bag_outlined, size: 21),
                            SizedBox(width: 9),
                            Text(
                              '바로 주문하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 9),
                            Icon(Icons.arrow_forward_rounded, size: 19),
                          ],
                        ),
                      ),
                    ),
                  ),
                ], // 가로 버튼 Row 종료
              ),

              const SizedBox(height: 8),

              // 153-5-2-7단계: 상품 상세화면 하단 내비게이션
              BottomNavigationBar(
                currentIndex: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: const Color(0xFFF47B08),
                unselectedItemColor: Colors.grey,
                backgroundColor: Colors.white,
                elevation: 0,
                onTap: (index) {
                  widget.onNavigateToTab?.call(index);
                },
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
            ], // 전체 Column 종료
          ),
        ),
      ),
    );
  }
}
