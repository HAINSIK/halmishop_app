// lib/screens/cart_screen.dart 전체 교체
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cart_provider.dart';
import 'order_list_screen.dart';
import '../utils/image_url_helper.dart';
import '../services/banchan_service.dart';

// 149-7-43-4단계: 회원별 마지막 배송정보 불러오기
Future<Map<String, String>> loadLastDeliveryInfo() async {
  final prefs = await SharedPreferences.getInstance();
  final memberId = prefs.getString('member_id');

  if (memberId == null || memberId.isEmpty) {
    return {};
  }

  final key = 'delivery_info_member_$memberId';

  return {
    'depositor': prefs.getString('${key}_depositor') ?? '',
    'recipientName': prefs.getString('${key}_recipientName') ?? '',
    'recipientPhone': prefs.getString('${key}_recipientPhone') ?? '',
    'address': prefs.getString('${key}_address') ?? '',
  };
}

// 149-7-43-4단계: 주문 성공 시 배송정보 저장
Future<void> saveLastDeliveryInfo({
  required String depositor,
  required String recipientName,
  required String recipientPhone,
  required String address,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final memberId = prefs.getString('member_id');

  if (memberId == null || memberId.isEmpty) {
    return;
  }

  final key = 'delivery_info_member_$memberId';

  await prefs.setString('${key}_depositor', depositor.trim());
  await prefs.setString('${key}_recipientName', recipientName.trim());
  await prefs.setString('${key}_recipientPhone', recipientPhone.trim());
  await prefs.setString('${key}_address', address.trim());
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.items;

    return Scaffold(
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '장바구니가 비어있습니다.\n맛있는 반찬을 담아보세요 👵',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // 장바구니 아이템 리스트 영역
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  getImageUrl(item.banchan.imageUrl),
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.orange.shade50,
                                        child: const Icon(
                                          Icons.fastfood,
                                          color: Colors.orange,
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.banchan.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${item.banchan.price}원',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      cartProvider.decreaseQuantity(index);
                                    },
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      size: 22,
                                    ),
                                    onPressed: () {
                                      cartProvider.increaseQuantity(index);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 하단 실시간 총 결제 금액 계산 바
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '총 결제 금액',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${cartProvider.totalPrice}원',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF244C3A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 54),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () async {
                            // 149-7-41-11단계: 주문 전 최신 판매 상태 확인
                            final latestProducts = await BanchanService()
                                .fetchBanchanList();

                            if (!context.mounted) return;

                            // 서버 조회 실패 시 주문 진행 중단
                            if (latestProducts.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '상품 정보를 확인할 수 없습니다. 잠시 후 다시 시도해 주세요.',
                                  ),
                                ),
                              );
                              return;
                            }

                            final stoppedProducts = cartProvider.items.where((
                              item,
                            ) {
                              for (final product in latestProducts) {
                                if (product.id == item.banchan.id) {
                                  return !product.isSaleEnabled;
                                }
                              }
                              return true;
                            }).toList();

                            debugPrint(
                              '판매중지 또는 확인 불가 상품: ${stoppedProducts.length}개',
                            );

                            // 149-7-41-11-4단계: 판매중지 상품 목록 안내
                            if (stoppedProducts.isNotEmpty) {
                              await showDialog<void>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text(
                                    '⚠️ 판매 준비중인 반찬 안내',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '현재 ${stoppedProducts.length}개 상품을 주문할 수 없습니다.',
                                        ),
                                        const SizedBox(height: 16),
                                        ...stoppedProducts.map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.info_outline,
                                                  color: Colors.redAccent,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    item.banchan.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          '판매 준비중인 반찬을 장바구니에서 삭제한 후 다시 주문해 주세요.',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext),
                                      child: const Text('취소'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF244C3A,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () async {
                                        // 판매중지 상품 ID만 수집
                                        final stoppedProductIds =
                                            stoppedProducts
                                                .map((item) => item.banchan.id)
                                                .toSet();

                                        // 판매중지 상품만 장바구니에서 삭제 및 저장
                                        await cartProvider
                                            .removeCartItemsByProductIds(
                                              stoppedProductIds,
                                            );

                                        if (!dialogContext.mounted) return;

                                        Navigator.pop(dialogContext);

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '판매중지 상품을 장바구니에서 삭제했습니다.',
                                                ),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                      },
                                      child: const Text('판매중지 상품 모두 삭제'),
                                    ),
                                  ],
                                ),
                              );

                              return;
                            }
                            // 149-7-43-4-3단계: 마지막 배송정보 자동 불러오기
                            final lastDeliveryInfo =
                                await loadLastDeliveryInfo();

                            if (!context.mounted) return;

                            // 마지막 주문 배송정보로 입력창 초기화
                            final TextEditingController addressController =
                                TextEditingController(
                                  text: lastDeliveryInfo['address'] ?? '',
                                );

                            final TextEditingController depositorController =
                                TextEditingController(
                                  text: lastDeliveryInfo['depositor'] ?? '',
                                );

                            final TextEditingController
                            recipientNameController = TextEditingController(
                              text: lastDeliveryInfo['recipientName'] ?? '',
                            );

                            final TextEditingController
                            recipientPhoneController = TextEditingController(
                              text: lastDeliveryInfo['recipientPhone'] ?? '',
                            );

                            // 149-7-44-9-17단계: 장바구니 주문 요청사항 컨트롤러
                            final TextEditingController orderMemoController =
                                TextEditingController();

                            // 149-7-43-2단계: 배송정보 입력 전 최종 주문 확인
                            final confirmed = await showDialog<bool>(
                              context: context,
                              barrierDismissible: false,
                              builder: (dialogContext) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: const Text(
                                  '🛒 주문하실 반찬을 확인해 주세요',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '모든 상품이 주문 가능합니다.',
                                        style: TextStyle(
                                          color: Color(0xFF244C3A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      ...cartProvider.items.map(
                                        (item) => Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${item.banchan.name} × ${item.quantity}',
                                                ),
                                              ),
                                              Text(
                                                '${item.banchan.price * item.quantity}원',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      const Divider(height: 24),

                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            '총 주문금액',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${cartProvider.totalPrice}원',
                                            style: const TextStyle(
                                              color: Color(0xFF244C3A),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: const Text('취소'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF244C3A),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: const Text('배송정보 입력하기'),
                                  ),
                                ],
                              ),
                            );

                            // 취소를 누르면 배송정보 입력창을 열지 않음
                            if (confirmed != true || !context.mounted) {
                              return;
                            }

                            // 💡 2. 정보 입력용 다이얼로그 열기
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                // 149-7-43-5-1단계: 젊은할미 배송정보 헤더
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      const Text('맛깔나는 반찬을 어디로 보내드릴까요?'),
                                      const SizedBox(height: 16),

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
                                      // 149-7-43-5-2단계: 입금자명 입력창 디자인
                                      TextField(
                                        controller: depositorController,
                                        decoration: InputDecoration(
                                          hintText: '입금자명을 입력해 주세요',
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.never,
                                          filled: true,
                                          fillColor: const Color(0xFFFFFBF5),
                                          prefixIcon: const Icon(
                                            Icons
                                                .account_balance_wallet_outlined,
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8DF),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF244C3A),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // 149-7-43-5-13단계: 받으시는 분 이름 제목
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
                                      // 149-7-43-5-3단계: 받으시는 분 입력창 디자인
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8DF),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF244C3A),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      // 149-7-43-5-14단계: 연락처 제목
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
                                      // 149-7-43-5-4단계: 연락처 입력창 디자인
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8DF),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF244C3A),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),
                                      // 149-7-43-5-15단계: 배송지 주소 제목
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
                                      // 149-7-43-5-5단계: 배송지 주소 입력창 디자인
                                      TextField(
                                        controller: addressController,
                                        maxLines: 2,
                                        minLines: 1,
                                        keyboardType:
                                            TextInputType.streetAddress,
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8DF),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF244C3A),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),

                                      // 149-7-44-9-18단계: 장바구니 주문 요청사항 입력창
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
                                        controller: orderMemoController,
                                        maxLines: 3,
                                        minLines: 2,
                                        maxLength: 200,
                                        textInputAction:
                                            TextInputAction.newline,
                                        decoration: InputDecoration(
                                          hintText:
                                              '배송이나 주문 관련 요청사항을 입력해 주세요.\n'
                                              '예: 배송 전 연락 부탁드립니다.',
                                          hintMaxLines: 2,
                                          filled: true,
                                          fillColor: const Color(0xFFFFFBF5),
                                          contentPadding: const EdgeInsets.all(
                                            16,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFFE2E8DF),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF244C3A),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // 149-7-43-5-6단계: 최종 주문금액 표시
                                      const SizedBox(height: 20),

                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 18,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3F6F0),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFDCE6D9),
                                          ),
                                        ),
                                        child: Row(
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
                                              '${cartProvider.totalPrice}원',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF244C3A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  // 149-7-43-5-7단계: 취소 버튼 디자인
                                  OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF607568),
                                      side: const BorderSide(
                                        color: Color(0xFFDCE6D9),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      '취소',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    // 149-7-43-5-8단계: 젊은할미 주문 접수 버튼 디자인
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF244C3A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (depositorController.text
                                              .trim()
                                              .isEmpty ||
                                          recipientNameController.text
                                              .trim()
                                              .isEmpty ||
                                          recipientPhoneController.text
                                              .trim()
                                              .isEmpty ||
                                          addressController.text
                                              .trim()
                                              .isEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '⚠️ 입금자명, 받으시는 분, 연락처, 배송 주소를 모두 입력해주세요.',
                                                ),
                                              ),
                                            );
                                        return;
                                      }

                                      final recipientPhone =
                                          recipientPhoneController.text
                                              .replaceAll(
                                                RegExp(r'[^0-9]'),
                                                '',
                                              );

                                      if (!RegExp(r'^01[016789]\d{7,8}$')
                                          .hasMatch(recipientPhone)) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '⚠️ 받으시는 분의 휴대폰 번호를 정확히 입력해주세요.',
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                      final total = cartProvider.totalPrice;
                                      // 💥 [버그 박멸] 주소와 입금자를 정확하게 아규먼트로 바인딩하여 함수를 호출합니다!
                                      bool isSuccess = await context
                                          .read<CartProvider>()
                                          .placeOrderFromCartWithDetails(
                                            address: addressController.text
                                                .trim(),
                                            depositor: depositorController.text
                                                .trim(),
                                            recipientName:
                                                recipientNameController.text
                                                    .trim(),
                                            recipientPhone: recipientPhone,
                                            // 149-7-44-9-20단계: 주문 요청사항 전달
                                            orderMemo: orderMemoController.text
                                                .trim(),
                                          );
                                      if (isSuccess) {
                                        // 149-7-43-4-4단계: 정상 주문 시 마지막 배송정보 저장
                                        await saveLastDeliveryInfo(
                                          depositor: depositorController.text
                                              .trim(),
                                          recipientName: recipientNameController
                                              .text
                                              .trim(),
                                          recipientPhone: recipientPhone,
                                          address: addressController.text
                                              .trim(),
                                        );

                                        if (!context.mounted) return;

                                        Navigator.pop(context); // 입력 팝업 닫기

                                        // 성공 완료 최종 팝업
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            title: const Text(
                                              '🎉 주문 접수 완료!',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: Text(
                                              '총 $total원의 주문이 정상 접수되었구만유!\n주문 내역에서 확인해 보셔유.',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
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
                                                    color: const Color(
                                                      0xFF244C3A,
                                                    ),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      } else {
                                        final errorMessage =
                                            context
                                                .read<CartProvider>()
                                                .lastOrderError ??
                                            '주문 처리 중 문제가 발생했습니다.';

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text('⚠️ $errorMessage'),
                                            backgroundColor: Colors.redAccent,
                                            duration: const Duration(
                                              seconds: 3,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    child: const Text(
                                      '주문 접수하기',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          // 149-7-43-5-9단계: 장바구니 하단 주문 버튼 디자인
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.white,
                                size: 21,
                              ),
                              SizedBox(width: 10),
                              Text(
                                '주문하기',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
