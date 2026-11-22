import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart' hide BorderStyle, Border;
import 'package:flutter/painting.dart' as painting;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dart:typed_data';

import '../services/api_config.dart';

class OrderListScreen extends StatefulWidget {
  final VoidCallback? onViewAllProducts;

  const OrderListScreen({super.key, this.onViewAllProducts});

  @override
  State<OrderListScreen> createState() => OrderListScreenState();
}

class OrderListScreenState extends State<OrderListScreen> {
  String get baseUrl => '${ApiConfig.baseUrl}/api/orders';
  late Future<List<dynamic>> _orderFuture;
  bool _isAdmin = false;
  String _selectedStatus = '전체';

  final List<String> _orderStatuses = [
    '전체',
    '입금대기',
    '입금확인중',
    '입금확인',
    '배송준비',
    '배송중',
    '배송완료',
    '주문취소',
  ];

  @override
  void initState() {
    super.initState();
    _orderFuture = _fetchOrders();
  }

  Future<void> refreshOrders() async {
    setState(() {
      _orderFuture = _fetchOrders();
    });
  }

  Future<List<dynamic>> _fetchOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (mounted)
        setState(() => _isAdmin = prefs.getString('member_role') == 'ADMIN');
      if (token == null || token.isEmpty) return [];
      final response = await http
          .get(Uri.parse(baseUrl), headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final orders = jsonDecode(utf8.decode(response.bodyBytes));

        // 150단계: 결제정보 수신 확인
        for (final order in orders) {
          debugPrint(
            '💳 주문번호: ${order['id']} / '
            '결제수단: ${order['paymentMethod']} / '
            '결제상태: ${order['paymentStatus']} / '
            '입금알림: ${order['paymentNotifiedAt']} / '
            '입금확인: ${order['paymentConfirmedAt']}',
          );
        }
        return orders;
      }
      return [];
    } catch (e) {
      debugPrint('❌ 주문 내역 가져오기 실패: $e');
      return [];
    }
  }

  Future<String> _savedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') ?? '';
  }

  Future<void> _deleteOrder(int orderId) async {
    final url = Uri.parse('$baseUrl/$orderId');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';
      final response = await http
          .delete(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        setState(() {
          _orderFuture = _fetchOrders();
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('주문이 정상적으로 취소되었어유!')));
      } else {
        debugPrint('❌ 삭제 실패: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('서버와 연결이 안 되네유. 네트워크를 확인하셔요!\n($e)');
    }
  }

  Future<void> _updateStatus(int orderId, String newStatus) async {
    try {
      // 백엔드 PATCH API 호출
      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/orderstatus'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${await _savedToken()}',
        },
        body: jsonEncode({"order_status": newStatus}),
      );

      if (response.statusCode == 200) {
        // 성공 시 FutureBuilder 화면 새로고침
        setState(() {
          _orderFuture = _fetchOrders();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('주문 상태가 [$newStatus](으)로 변경되었어유!')),
        );
      } else {
        debugPrint('❌ 상태 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 상태 변경 통신 에러: $e');
    }
  }

  Future<void> _updateTracking(
    int orderId,
    String courier,
    String trackingNumber,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/tracking'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _savedToken()}',
        },
        body: jsonEncode({
          'courier': courier,
          'trackingNumber': trackingNumber,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _orderFuture = _fetchOrders();
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('송장 정보가 저장되었습니다.')));
      } else {
        _showErrorDialog(
          '송장 저장에 실패했습니다. (${response.statusCode})\n${utf8.decode(response.bodyBytes)}',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('송장 저장 중 오류가 발생했습니다.\n$e');
      }
    }
  }

  Future<void> _openTracking(String courier, String trackingNumber) async {
    final number = trackingNumber.trim();

    if (number.isEmpty) return;

    String? trackingUrl;

    switch (courier) {
      case 'CJ대한통운':
        trackingUrl =
            'https://trace.cjlogistics.com/next/tracking.html?wblNo=$number';
        break;

      case '한진택배':
        trackingUrl =
            'https://www.hanjin.com/kor/CMS/DeliveryMgr/WaybillResult.do'
            '?mCode=MN038&schLang=KR&wblnumText2=$number';
        break;

      case '롯데택배':
        trackingUrl =
            'https://www.lotteglogis.com/home/reservation/tracking/linkView'
            '?InvNo=$number';
        break;

      case '우체국택배':
        trackingUrl =
            'https://service.epost.go.kr/trace.RetrieveDomRigiTraceList.comm'
            '?displayHeader=N&sid1=$number';
        break;

      case '로젠택배':
        trackingUrl = 'https://www.ilogen.com/m/personal/trace.pop/$number';
        break;
    }

    if (trackingUrl == null) {
      _showErrorDialog('등록되지 않은 택배사입니다.');
      return;
    }

    final uri = Uri.parse(trackingUrl);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showErrorDialog('배송조회 페이지를 열지 못했습니다.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('배송조회 중 오류가 발생했습니다.\n$e');
      }
    }
  }

  Future<void> _updateAddress(int orderId, String newAddress) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/delivery_address'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${await _savedToken()}',
        },
        body: jsonEncode({"delivery_address": newAddress}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _orderFuture = _fetchOrders(); // 성공 시 장부 새로고침
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('배송지 주소가 똑부러지게 변경되었어유!')));
      } else {
        debugPrint('❌ 주소 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 주소 변경 통신 에러: $e');
    }
  }

  Future<void> _updatedepositorName(int orderId, String newName) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/depositor_Name'),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${await _savedToken()}',
        },
        body: jsonEncode({"depositor_name": newName}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _orderFuture = _fetchOrders(); // 성공 시 장부 새로고침
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('입금자명이 똑부러지게 변경되었어유!')));
      } else {
        debugPrint('❌ 입금자 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ 입금자 변경 통신 에러: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ 확인해 보셔요'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('확인'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showAddressDialog(int orderId, String currentAddress) {
    final TextEditingController addressController = TextEditingController(
      text: currentAddress,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🚚 배송지 주소 변경'),
        content: TextField(
          controller: addressController,
          decoration: const InputDecoration(
            hintText: "새 주소를 입력하셔요",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('변경하기', style: TextStyle(color: Colors.orange)),
            onPressed: () {
              if (addressController.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop();
                _updateAddress(orderId, addressController.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }

  void _showNameDialog(int orderId, String currentAddress) {
    final TextEditingController nameController = TextEditingController(
      text: currentAddress,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('💰 입금자명 변경'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: "새 입금자명을 입력하셔요",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('변경하기', style: TextStyle(color: Colors.orange)),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop();
                _updatedepositorName(orderId, nameController.text.trim());
              }
            },
          ),
        ],
      ),
    );
  }

  void _showTrackingDialog(
    int orderId,
    String currentCourier,
    String currentTrackingNumber,
  ) {
    final List<String> couriers = ['CJ대한통운', '한진택배', '롯데택배', '우체국택배', '로젠택배'];

    String selectedCourier = couriers.contains(currentCourier)
        ? currentCourier
        : couriers.first;

    final trackingController = TextEditingController(
      text: currentTrackingNumber,
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('📦 택배 송장 등록'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCourier,
                decoration: const InputDecoration(
                  labelText: '택배사 선택',
                  border: OutlineInputBorder(),
                ),
                items: couriers.map((courier) {
                  return DropdownMenuItem(value: courier, child: Text(courier));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedCourier = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: trackingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '송장번호',
                  hintText: '송장번호를 입력하세요',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                final trackingNumber = trackingController.text.trim();

                if (trackingNumber.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('송장번호를 입력해 주세요.')),
                  );
                  return;
                }

                Navigator.pop(ctx);

                _updateTracking(orderId, selectedCourier, trackingNumber);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '할미네 주문 장부 📜',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF244C3A),
        actions: [
          // 150단계: 주문장부 새로고침
          IconButton(
            tooltip: '주문목록 새로고침',
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: refreshOrders,
          ),

          if (_isAdmin)
            IconButton(
              tooltip: '오늘의 반찬 집계',
              icon: const Icon(Icons.summarize, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyProductSummaryScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // 관리자 전용 주문 상태 필터
          if (_isAdmin)
            Container(
              width: double.infinity,
              color: const Color(0xFFF8F6F0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _orderStatuses.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final status = _orderStatuses[index];
                    final isSelected = _selectedStatus == status;

                    return ChoiceChip(
                      label: Text(status),
                      selected: isSelected,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),

                      onSelected: (_) {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                      selectedColor: const Color(0xFF244C3A),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF244C3A),
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      showCheckmark: false,
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF244C3A)
                            : const Color(0xFFD7DDD5),
                      ),
                    );
                  },
                ),
              ),
            ),

          // 기존 주문목록
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _orderFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('장부 로딩 에러: ${snapshot.error}'));
                }
                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return RefreshIndicator(
                    color: const Color(0xFF244C3A),
                    onRefresh: () async {
                      await refreshOrders();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.65,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/characters/halmi_login.png',
                                width: 150,
                                height: 150,
                                fit: BoxFit.contain,
                              ),

                              const SizedBox(height: 24),

                              const Text(
                                '아직 주문 내역이 없어요!',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF244C3A),
                                ),
                              ),

                              const SizedBox(height: 12),

                              const Text(
                                '젊은할미가 정성껏 준비한 반찬들,\n'
                                '지금 구경해 보세요.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: Colors.grey,
                                ),
                              ),
                              if (!_isAdmin) ...[
                                const SizedBox(height: 28),

                                SizedBox(
                                  width: 230,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: widget.onViewAllProducts,
                                    icon: const Icon(
                                      Icons.storefront_outlined,
                                      size: 21,
                                    ),
                                    label: const Text(
                                      '전체 반찬 구경하기',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF244C3A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final orders = snapshot.data!;

                final filteredOrders = orders.where((order) {
                  if (_selectedStatus == '전체') {
                    return true;
                  }

                  final orderStatus = order['orderStatus'] ?? '주문접수';
                  final paymentStatus = order['paymentStatus'] ?? 'WAITING';
                  final paymentMethod = order['paymentMethod'] ?? '';

                  // 입금대기
                  if (_selectedStatus == '입금대기') {
                    return orderStatus == '주문접수' &&
                        paymentMethod == 'BANK_TRANSFER' &&
                        paymentStatus == 'WAITING';
                  }

                  // 입금확인중
                  if (_selectedStatus == '입금확인중') {
                    return orderStatus == '주문접수' &&
                        paymentMethod == 'BANK_TRANSFER' &&
                        paymentStatus == 'NOTIFIED';
                  }

                  // 나머지는 주문상태로 구분
                  return orderStatus == _selectedStatus;
                }).toList();

                if (filteredOrders.isEmpty) {
                  return RefreshIndicator(
                    color: const Color(0xFF244C3A),
                    onRefresh: () async {
                      await refreshOrders();
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: _isAdmin
                                ? const Text(
                                    '선택한 상태의 주문이 없습니다.',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/characters/halmi_login.png',
                                        width: 150,
                                        height: 150,
                                        fit: BoxFit.contain,
                                      ),

                                      const SizedBox(height: 24),

                                      const Text(
                                        '해당하는 주문 내역이 없어요!',
                                        style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF244C3A),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      const Text(
                                        '젊은할미가 정성껏 준비한 반찬들,\n'
                                        '지금 구경해 보세요.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.6,
                                          color: Colors.grey,
                                        ),
                                      ),

                                      const SizedBox(height: 28),

                                      SizedBox(
                                        width: 230,
                                        height: 48,
                                        child: ElevatedButton.icon(
                                          onPressed: widget.onViewAllProducts,
                                          icon: const Icon(
                                            Icons.storefront_outlined,
                                            size: 21,
                                          ),
                                          label: const Text(
                                            '전체 반찬 구경하기',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF244C3A,
                                            ),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
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

                return RefreshIndicator(
                  color: const Color(0xFF244C3A),
                  onRefresh: () async {
                    await refreshOrders();
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredOrders.length,

                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final int orderId = order['id']; // 삭제를 위한 주문 ID 추출

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color(0xFFE2E8DF),
                            width: 1,
                          ),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 💡 상단 행: 주문번호 - 주문상태 - 취소버튼(우측 끝 배치)
                              Row(
                                children: [
                                  Text(
                                    '주문번호 : #$orderId',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF244C3A),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8), // 간격 소폭 추가
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
                                      order['orderStatus'] == '주문접수' &&
                                              order['paymentMethod'] ==
                                                  'BANK_TRANSFER'
                                          ? (order['paymentStatus'] ==
                                                    'NOTIFIED'
                                                ? '입금확인중'
                                                : order['paymentStatus'] ==
                                                      'PAID'
                                                ? '주문확정'
                                                : '입금대기')
                                          : (order['orderStatus'] ?? '주문접수'),
                                      style: const TextStyle(
                                        color: Color(0xFF244C3A),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Spacer(), // 💥 왼쪽 요소들을 밀어내어 버튼을 우측 끝에 고정합니다.
                                  // 💡 새로 추가된 주문 취소 버튼
                                  // 150단계: 입금대기 중인 고객 주문만 직접 취소 가능
                                  if (!_isAdmin &&
                                      order['orderStatus'] == '주문접수' &&
                                      order['paymentStatus'] == 'WAITING')
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.redAccent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        // 실수 방지를 위해 취소 의사를 묻는 다이얼로그 띄우기
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text('주문 취소하기'),
                                            content: Text(
                                              '주문번호 #$orderId 정말 취소하시겠습니까?',
                                            ),
                                            actions: [
                                              TextButton(
                                                child: const Text('아니오'),
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(),
                                              ),
                                              TextButton(
                                                child: const Text(
                                                  '예, 취소해주세요',
                                                  style: TextStyle(
                                                    color: Colors.redAccent,
                                                  ),
                                                ),
                                                onPressed: () {
                                                  Navigator.of(ctx).pop();
                                                  _deleteOrder(
                                                    orderId,
                                                  ); // 💥 실제 삭제 함수 실행
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Icons.delete_forever,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        '주문취소',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              // 150단계: 고객 입금대기 안내
                              if (!_isAdmin &&
                                  order['orderStatus'] == '주문접수' &&
                                  order['paymentMethod'] == 'BANK_TRANSFER' &&
                                  order['paymentStatus'] == 'WAITING') ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8EC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: painting.Border.all(
                                      color: const Color(0xFFF1DFC1),
                                    ),
                                  ),
                                  child: const Text(
                                    '💳 주문이 정상적으로 접수되었습니다.\n'
                                    '안내된 계좌로 입금하신 후 '
                                    '입금했어요 버튼을 눌러주세요.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.6,
                                      color: Color(0xFF795622),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // 150단계: 고객 입금완료 알림 버튼
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (dialogContext) => AlertDialog(
                                          title: const Text('입금확인 요청'),
                                          content: const Text(
                                            '안내된 계좌로 실제 입금을 완료하셨나요?\n\n'
                                            '확인을 누르면 사장님께 입금확인 요청이 전달됩니다.\n'
                                            '실제 입금 여부는 사장님이 확인한 후 처리됩니다.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                  dialogContext,
                                                  false,
                                                );
                                              },
                                              child: const Text('취소'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                  dialogContext,
                                                  true,
                                                );
                                              },
                                              child: const Text(
                                                '입금했어요',
                                                style: TextStyle(
                                                  color: Color(0xFF244C3A),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed != true) {
                                        return;
                                      }

                                      // 150단계: 입금알림 서버 전송
                                      try {
                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        final token = prefs.getString(
                                          'jwt_token',
                                        );

                                        if (token == null || token.isEmpty) {
                                          if (!context.mounted) return;

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                '로그인 정보가 없습니다. 다시 로그인해 주세요.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        final response = await http
                                            .patch(
                                              Uri.parse(
                                                '$baseUrl/$orderId/payment-notify',
                                              ),
                                              headers: {
                                                'Authorization':
                                                    'Bearer $token',
                                                'Content-Type':
                                                    'application/json',
                                              },
                                            )
                                            .timeout(
                                              const Duration(seconds: 15),
                                            );

                                        if (!context.mounted) return;

                                        if (response.statusCode == 200) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    '입금확인 요청이 정상적으로 접수되었습니다.',
                                                  ),
                                                ),
                                              );

                                          // 150단계: 입금알림 성공 후 주문장부 새로고침
                                          await refreshOrders();
                                        } else {
                                          final errorBody = jsonDecode(
                                            utf8.decode(response.bodyBytes),
                                          );

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    errorBody['message'] ??
                                                        '입금확인 요청에 실패했습니다.',
                                                  ),
                                                ),
                                              );
                                        }
                                      } catch (e) {
                                        if (!context.mounted) return;

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '서버 연결에 실패했습니다. 잠시 후 다시 시도해 주세요.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      size: 20,
                                    ),
                                    label: const Text('입금했어요'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF244C3A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              // 150단계: 관리자 입금확인 요청 안내
                              if (_isAdmin &&
                                  order['paymentMethod'] == 'BANK_TRANSFER' &&
                                  order['paymentStatus'] == 'NOTIFIED') ...[
                                const SizedBox(height: 12),

                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8EC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: painting.Border.all(
                                      color: const Color(0xFFF1DFC1),
                                    ),
                                  ),
                                  child: const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.notifications_active_outlined,
                                            color: Color(0xFF795622),
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '입금확인 요청이 도착했습니다!',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF795622),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '고객이 입금완료를 알렸습니다.\n'
                                        '실제 계좌 입금내역을 확인한 후 '
                                        '입금확정 처리를 진행해 주세요.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.6,
                                          color: Color(0xFF795622),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // 150단계: 관리자 입금확정 버튼
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (dialogContext) => AlertDialog(
                                          title: const Text('입금확정 처리'),
                                          content: Text(
                                            '주문번호: #$orderId\n'
                                            '입금자명: ${order['depositorName'] ?? '정보 없음'}\n'
                                            '주문금액: ${order['totalPrice'] ?? 0}원\n\n'
                                            '실제 은행 계좌에서 입금자명과 금액을 확인하셨나요?\n\n'
                                            '확정하면 결제상태가 PAID로 변경되고 '
                                            '주문상태가 입금확인으로 변경됩니다.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                  dialogContext,
                                                  false,
                                                );
                                              },
                                              child: const Text('취소'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                  dialogContext,
                                                  true,
                                                );
                                              },
                                              child: const Text(
                                                '입금확정',
                                                style: TextStyle(
                                                  color: Color(0xFF244C3A),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirmed != true) {
                                        return;
                                      }

                                      // 150단계: 관리자 입금확정 서버 전송
                                      try {
                                        final prefs =
                                            await SharedPreferences.getInstance();
                                        final token = prefs.getString(
                                          'jwt_token',
                                        );

                                        if (token == null || token.isEmpty) {
                                          if (!context.mounted) return;

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                '로그인 정보가 없습니다. 다시 로그인해 주세요.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        final response = await http
                                            .patch(
                                              Uri.parse(
                                                '$baseUrl/$orderId/payment-confirm',
                                              ),
                                              headers: {
                                                'Authorization':
                                                    'Bearer $token',
                                                'Content-Type':
                                                    'application/json',
                                              },
                                            )
                                            .timeout(
                                              const Duration(seconds: 15),
                                            );

                                        if (!context.mounted) return;

                                        if (response.statusCode == 200) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    '입금확정 처리가 완료되었습니다.',
                                                  ),
                                                ),
                                              );

                                          // 입금확정 후 주문장부 자동 새로고침
                                          await refreshOrders();
                                        } else {
                                          String message = '입금확정 처리에 실패했습니다.';

                                          try {
                                            final errorBody = jsonDecode(
                                              utf8.decode(response.bodyBytes),
                                            );

                                            if (errorBody is Map &&
                                                errorBody['message'] != null) {
                                              message = errorBody['message']
                                                  .toString();
                                            }
                                          } catch (_) {
                                            // 서버 응답이 JSON이 아니어도 기본 오류 메시지 표시
                                          }

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text(message)),
                                          );
                                        }
                                      } catch (e) {
                                        if (!context.mounted) return;

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              '서버 연결에 실패했습니다. 잠시 후 다시 시도해 주세요.',
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.verified_outlined,
                                      size: 20,
                                    ),
                                    label: const Text('입금확정 처리'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF244C3A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const Divider(height: 24),

                              if (order['items'] is List &&
                                  (order['items'] as List).isNotEmpty) ...[
                                Text(
                                  _isAdmin ? '주문 상품별 수량' : '내 주문 상품',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // const Text(
                                //   '주문 상품별 수량',
                                //   style: TextStyle(
                                //     fontSize: 18,
                                //     fontWeight: FontWeight.bold,
                                //   ),
                                // ),
                                const SizedBox(height: 8),

                                ...(order['items'] as List).map((item) {
                                  final productName =
                                      item['productName'] ?? '상품명 없음';
                                  final quantity = item['quantity'] ?? 0;
                                  final price = item['price'] ?? 0;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$productName (단가 ${price}원)',
                                            style: const TextStyle(
                                              fontSize: 15,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${quantity}개',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF244C3A),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ] else
                                Text(
                                  '반찬명: ${order['productName']}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                              // Text(
                              //   '반찬명: ${order['productName']}',
                              //   style: const TextStyle(
                              //     fontSize: 18,
                              //     fontWeight: FontWeight.bold,
                              //   ),
                              // ),
                              const SizedBox(height: 10),
                              Text(
                                '총 금액: ${order['totalPrice']}원',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF244C3A),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '🚚 배송지: ${order['deliveryAddress']}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  // 💡 주문완료 상태일 때만 주소를 고칠 수 있게 버튼 배치
                                  // 배송준비 전까지 배송지 변경 가능
                                  if (order['orderStatus'] == '주문접수' ||
                                      order['orderStatus'] == '입금확인')
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        foregroundColor: const Color(
                                          0xFF607568,
                                        ),
                                      ),
                                      onPressed: () => _showAddressDialog(
                                        orderId,
                                        order['deliveryAddress'] ?? '',
                                      ),
                                      child: const Text(
                                        ' [배송지 변경]',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '💰 입금자: ${order['depositorName']}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),

                                  // 입금대기 상태에서만 입금자명 변경 가능
                                  if (order['orderStatus'] == '주문접수' &&
                                      order['paymentMethod'] ==
                                          'BANK_TRANSFER' &&
                                      order['paymentStatus'] == 'WAITING')
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        foregroundColor: const Color(
                                          0xFF607568,
                                        ),
                                      ),
                                      onPressed: () => _showNameDialog(
                                        orderId,
                                        order['depositorName'] ?? '',
                                      ),
                                      child: const Text(
                                        ' [입금자명 변경]',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              // Text(
                              //   '🚚 배송지: ${order['deliveryAddress']}',
                              //   style: const TextStyle(
                              //     color: Colors.grey,
                              //     fontSize: 13,
                              //   ),
                              // ),
                              // const SizedBox(height: 2),
                              // Text(
                              //   '💰 입금자: ${order['depositorName']}',
                              //   style: const TextStyle(
                              //     color: Colors.grey,
                              //     fontSize: 13,
                              //   ),
                              // ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF607568),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '주문일시: ${(() {
                                        final rawDate = order['orderDate']?.toString() ?? '';
                                        final date = DateTime.tryParse(rawDate);

                                        if (date == null) return rawDate;

                                        final year = date.year;
                                        final month = date.month.toString().padLeft(2, '0');
                                        final day = date.day.toString().padLeft(2, '0');
                                        final hour = date.hour.toString().padLeft(2, '0');
                                        final minute = date.minute.toString().padLeft(2, '0');

                                        return '$year.$month.$day $hour:$minute';
                                      })()}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // 149-7-44-9-22-6단계: 주문 요청사항 표시
                              if ((order['orderMemo'] ?? '')
                                  .toString()
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFBF5),
                                    borderRadius: BorderRadius.circular(10),
                                    border:
                                        const painting.Border.fromBorderSide(
                                          BorderSide(color: Color(0xFFE2E8DF)),
                                        ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '📝 주문 요청사항',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF244C3A),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        order['orderMemo'].toString(),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF444444),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],

                              // 택배 송장 정보
                              if (order['trackingNumber'] != null &&
                                  order['trackingNumber']
                                      .toString()
                                      .isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '📦 택배사: ${order['courier'] ?? '-'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: SelectableText(
                                              '송장번호: ${order['trackingNumber']}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _openTracking(
                                            order['courier']?.toString() ?? '',
                                            order['trackingNumber']
                                                    ?.toString() ??
                                                '',
                                          ),
                                          icon: const Icon(
                                            Icons.local_shipping,
                                          ),
                                          label: const Text('배송조회 바로가기'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.blue.shade600,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (_isAdmin) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '👤 고객명: ${order['memberName'] ?? '-'}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '📞 연락처: ${order['memberPhoneNumber'] ?? '-'}',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              if (_isAdmin) ...[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      _showTrackingDialog(
                                        orderId,
                                        order['courier'] ?? '',
                                        order['trackingNumber'] ?? '',
                                      );
                                    },
                                    icon: const Icon(Icons.local_shipping),
                                    label: Text(
                                      order['trackingNumber'] == null ||
                                              order['trackingNumber']
                                                  .toString()
                                                  .isEmpty
                                          ? '송장 등록'
                                          : '송장 수정',
                                    ),
                                  ),
                                ),
                              ],

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // 150단계: 입금확인 후 배송준비 처리
                                  if (_isAdmin &&
                                      order['orderStatus'] == '입금확인' &&
                                      order['paymentStatus'] == 'PAID')
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF244C3A,
                                        ),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _updateStatus(orderId, '배송준비'),
                                      icon: const Icon(
                                        Icons.inventory_2_outlined,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        '배송준비',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),

                                  // 배송준비 완료 후 배송 시작
                                  if (_isAdmin &&
                                      order['orderStatus'] == '배송준비' &&
                                      order['paymentStatus'] == 'PAID')
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade400,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _updateStatus(orderId, '배송중'),
                                      icon: const Icon(
                                        Icons.local_shipping,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        '배송 시작',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),

                                  // 배송중 상태에서 배송완료 처리
                                  if (_isAdmin &&
                                      order['orderStatus'] == '배송중' &&
                                      order['paymentStatus'] == 'PAID')
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade400,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _updateStatus(orderId, '배송완료'),
                                      icon: const Icon(
                                        Icons.done_all,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        '배송 완료',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DailyProductSummaryScreen extends StatefulWidget {
  const DailyProductSummaryScreen({super.key});

  @override
  State<DailyProductSummaryScreen> createState() =>
      _DailyProductSummaryScreenState();
}

class _DailyProductSummaryScreenState extends State<DailyProductSummaryScreen> {
  DateTime _selectedDate = DateTime.now();
  List<dynamic> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  String get _dateString {
    final year = _selectedDate.year.toString().padLeft(4, '0');
    final month = _selectedDate.month.toString().padLeft(2, '0');
    final day = _selectedDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token') ?? '';

      final uri = Uri.parse('${ApiConfig.baseUrl}/api/orders/summary')
          .replace(queryParameters: {'date': _dateString});

      final response = await http
          .get(uri, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (!mounted) return;

        setState(() {
          _items = data;
          _isLoading = false;
        });
      } else {
        throw Exception(
          '조회 실패 (${response.statusCode}): ${utf8.decode(response.bodyBytes)}',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<dynamic>> _fetchOrdersForExcel() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';

    if (token.isEmpty) {
      throw Exception('로그인 정보가 없습니다.');
    }

    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}/api/orders'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return List<dynamic>.from(data);
    }

    throw Exception('주문 목록 조회 실패 (${response.statusCode})');
  }

  List<dynamic> _filterOrdersForExcel(List<dynamic> orders) {
    return orders.where((order) {
      final orderDate = DateTime.tryParse(order['orderDate']?.toString() ?? '');

      if (orderDate == null) return false;

      final sameDate =
          orderDate.year == _selectedDate.year &&
          orderDate.month == _selectedDate.month &&
          orderDate.day == _selectedDate.day;

      final status = order['orderStatus']?.toString() ?? '';

      final notCancelled = status != '주문취소';

      return sameDate && notCancelled;
    }).toList();
  }

  Future<void> _exportExcel() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 선택한 날짜의 고객별 주문 가져오기
      final allOrders = await _fetchOrdersForExcel();
      final orders = _filterOrdersForExcel(allOrders);

      if (orders.isEmpty) {
        throw Exception('선택한 날짜에 출력할 주문이 없습니다.');
      }

      // 엑셀 파일 생성
      final excel = Excel.createExcel();

      // 첫 번째 시트: 주방 집계
      final kitchenSheet = excel['Sheet1'];

      kitchenSheet.setColumnWidth(0, 25);
      kitchenSheet.setColumnWidth(1, 18);

      // 주방 집계표 머리글 스타일
      // kitchenSheet.row(0).forEach((cell) {
      //   cell.cellStyle = CellStyle(
      //     bold: true,
      //     fontSize: 14,
      //     backgroundColorHex: ExcelColor.fromHexString('#F4B183'),
      //     horizontalAlign: HorizontalAlign.Center,
      //   );
      // });

      kitchenSheet.appendRow([
        TextCellValue('반찬 이름'),
        TextCellValue('총 준비 수량'),
      ]);

      final Map<String, int> totals = {};

      for (final order in orders) {
        final items = order['items'] as List<dynamic>? ?? [];

        for (final item in items) {
          final name = item['productName'].toString();
          final quantity = (item['quantity'] as num).toInt();

          totals[name] = (totals[name] ?? 0) + quantity;
        }
      }

      // 반찬별 이름과 총 준비 수량 기록
      for (final entry in totals.entries) {
        kitchenSheet.appendRow([
          TextCellValue(entry.key),
          IntCellValue(entry.value),
        ]);
      }

      // 전체 반찬 준비 수량 합계
      final grandTotal = totals.values.fold<int>(
        0,
        (sum, quantity) => sum + quantity,
      );

      kitchenSheet.appendRow([
        TextCellValue('전체 합계'),
        IntCellValue(grandTotal),
      ]);

      final totalRowIndex = kitchenSheet.maxRows - 1;

      for (int col = 0; col < 2; col++) {
        kitchenSheet
            .cell(
              CellIndex.indexByColumnRow(
                columnIndex: col,
                rowIndex: totalRowIndex,
              ),
            )
            .cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#FFF2CC'),
          leftBorder: Border(borderStyle: BorderStyle.Thin),
          rightBorder: Border(borderStyle: BorderStyle.Thin),
          topBorder: Border(borderStyle: BorderStyle.Thin),
          bottomBorder: Border(borderStyle: BorderStyle.Thin),
        );
      }

      final headerStyle = CellStyle(
        bold: true,
        fontSize: 14,
        backgroundColorHex: ExcelColor.fromHexString('#F4B183'),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
      );
      kitchenSheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;

      kitchenSheet.cell(CellIndex.indexByString('B1')).cellStyle = headerStyle;

      // 두 번째 시트: 고객별 포장표
      final packingSheet = excel['고객별 포장표'];

      // 고객별 포장표 열 너비
      packingSheet.setColumnWidth(0, 12);
      packingSheet.setColumnWidth(1, 18);
      packingSheet.setColumnWidth(2, 22);
      packingSheet.setColumnWidth(3, 12);
      packingSheet.setColumnWidth(3, 12);

      // // 고객별 포장표 머리글 스타일
      // packingSheet.row(0).forEach((cell) {
      //   cell.cellStyle = CellStyle(
      //     bold: true,
      //     fontSize: 13,
      //     backgroundColorHex: ExcelColor.fromHexString('#F4B183'),
      //     horizontalAlign: HorizontalAlign.Center,
      //   );
      // });

      packingSheet.appendRow([
        TextCellValue('주문번호'),
        TextCellValue('고객 이름'),
        TextCellValue('반찬 이름'),
        TextCellValue('반찬 가격'),
        TextCellValue('주문 수량'),
      ]);

      packingSheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;
      packingSheet.cell(CellIndex.indexByString('B1')).cellStyle = headerStyle;
      packingSheet.cell(CellIndex.indexByString('C1')).cellStyle = headerStyle;
      packingSheet.cell(CellIndex.indexByString('D1')).cellStyle = headerStyle;
      packingSheet.cell(CellIndex.indexByString('E1')).cellStyle = headerStyle;

      // 고객별 포장 데이터 모으기
      final List<Map<String, dynamic>> packingRows = [];

      for (final order in orders) {
        final orderId = order['id'];
        final memberName = order['memberName']?.toString() ?? '';
        final items = order['items'] as List<dynamic>? ?? [];

        for (final item in items) {
          packingRows.add({
            'orderId': orderId,
            'memberName': memberName,
            'productName': item['productName'].toString(),
            'price': (item['price'] as num).toInt(),
            'quantity': (item['quantity'] as num).toInt(),
          });
        }
      }

      // 고객 이름순 → 주문번호순 정렬
      packingRows.sort((a, b) {
        final nameCompare = a['memberName'].toString().compareTo(
          b['memberName'].toString(),
        );

        if (nameCompare != 0) return nameCompare;

        return (a['orderId'] as num).compareTo(b['orderId'] as num);
      });

      // 정렬된 데이터 엑셀에 기록
      for (final row in packingRows) {
        packingSheet.appendRow([
          TextCellValue(row['orderId'].toString()),
          TextCellValue(row['memberName']),
          TextCellValue(row['productName']),
          IntCellValue(row['price']),
          IntCellValue(row['quantity']),
        ]);

        final rowIndex = packingSheet.maxRows - 1;

        for (int col = 0; col < 5; col++) {
          packingSheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: col,
                  rowIndex: rowIndex,
                ),
              )
              .cellStyle = CellStyle(
            leftBorder: Border(borderStyle: BorderStyle.Thin),
            rightBorder: Border(borderStyle: BorderStyle.Thin),
            topBorder: Border(borderStyle: BorderStyle.Thin),
            bottomBorder: Border(borderStyle: BorderStyle.Thin),
          );
        }
      }

      // 엑셀 파일 저장
      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('엑셀 파일 생성에 실패했습니다.');
      }

      String? savedPath;

      if (kIsWeb) {
        // 크롬: 기존처럼 자동 다운로드
        savedPath = await FileSaver.instance.saveFile(
          name: '할미샵_주문정리_$_dateString',
          bytes: Uint8List.fromList(bytes),
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        // 갤럭시: 저장 위치 선택 창 열기
        savedPath = await FileSaver.instance.saveAs(
          name: '할미샵_주문정리_$_dateString',
          bytes: Uint8List.fromList(bytes),
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );

        // 사용자가 저장을 취소한 경우
        if (savedPath == null) {
          if (!mounted) return;

          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('파일 저장을 취소했습니다.')));
          return;
        }
      }

      debugPrint('📁 주문 엑셀 저장 결과: $savedPath');

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('엑셀 파일 저장이 완료되었습니다.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('엑셀 저장 실패: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 한진택배 송장 업로드용 엑셀 생성
  Future<void> _exportHanjinExcel() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 선택한 날짜의 주문 가져오기
      final allOrders = await _fetchOrdersForExcel();
      final orders = _filterOrdersForExcel(allOrders);

      if (orders.isEmpty) {
        throw Exception('선택한 날짜에 출력할 주문이 없습니다.');
      }

      // 한진택배 전용 엑셀 생성
      final excel = Excel.createExcel();
      final hanjinSheet = excel['Sheet1'];

      // 한진택배 원본 양식의 1행 필드명 (순서 변경 금지)
      hanjinSheet.appendRow([
        TextCellValue('받으시는 분'),
        TextCellValue('받으시는 분 전화'),
        TextCellValue('받는분담당자'),
        TextCellValue('받는분핸드폰'),
        TextCellValue('받는분우편번호'),
        TextCellValue('받는분총주소'),
        TextCellValue('수량'),
        TextCellValue('품목명'),
        TextCellValue('운임Type'),
        TextCellValue('지불조건'),
        TextCellValue('출고번호'),
        TextCellValue('특기사항'),
        TextCellValue('메모1'),
        TextCellValue('메모2'),
        TextCellValue('메모3'),
        TextCellValue('메모4'),
      ]);

      // 2행부터 한진택배 수령인 정보 입력
      for (final order in orders) {
        final receiverName = order['memberName']?.toString().trim() ?? '';
        final receiverPhone =
            order['memberPhoneNumber']?.toString().trim() ?? '';
        final receiverAddress =
            order['deliveryAddress']?.toString().trim() ?? '';

        // 필수 배송정보가 없는 주문은 누락 방지를 위해 오류 표시
        if (receiverName.isEmpty ||
            receiverPhone.isEmpty ||
            receiverAddress.isEmpty) {
          throw Exception('주문번호 ${order['id']}: 받는 사람 이름, 전화번호 또는 주소가 없습니다.');
        }

        hanjinSheet.appendRow([
          TextCellValue(receiverName), // A: 받으시는 분
          TextCellValue(receiverPhone), // B: 받으시는 분 전화
          TextCellValue(''), // C
          TextCellValue(''), // D
          TextCellValue(''), // E
          TextCellValue(receiverAddress), // F: 받는분총주소
          TextCellValue(''), // G
          TextCellValue(''), // H
          TextCellValue(''), // I
          TextCellValue(''), // J
          TextCellValue(''), // K
          TextCellValue(''), // L
          TextCellValue(''), // M
          TextCellValue(''), // N
          TextCellValue(''), // O
          TextCellValue(''), // P
        ]);
      }

      // 한진택배 엑셀 파일 저장
      final bytes = excel.encode();

      if (bytes == null) {
        throw Exception('한진택배 엑셀 파일 생성에 실패했습니다.');
      }

      String? savedPath;

      if (kIsWeb) {
        // 크롬: 기존처럼 자동 다운로드
        savedPath = await FileSaver.instance.saveFile(
          name: '할미샵_한진택배_$_dateString',
          bytes: Uint8List.fromList(bytes),
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      } else {
        // 갤럭시: 저장 위치 선택 창 열기
        savedPath = await FileSaver.instance.saveAs(
          name: '할미샵_한진택배_$_dateString',
          bytes: Uint8List.fromList(bytes),
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );

        // 저장을 취소한 경우
        if (savedPath == null) {
          if (!mounted) return;

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('한진택배 엑셀 저장을 취소했습니다.')));
          return;
        }
      }

      debugPrint('📁 한진택배 엑셀 저장 결과: $savedPath');

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('한진택배 엑셀 파일 저장이 완료되었습니다.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('한진택배 엑셀 생성 실패: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = picked;
    });

    await _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    final totalQuantity = _items.fold<int>(
      0,
      (sum, item) => sum + (item['totalQuantity'] as num).toInt(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 반찬 집계'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text('집계 날짜: $_dateString'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _exportExcel,
                  icon: const Icon(Icons.file_download),
                  label: const Text('엑셀 저장하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _exportHanjinExcel,
                  icon: const Icon(Icons.local_shipping),
                  label: const Text('한진택배 송장 엑셀 저장'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_errorMessage!),
                ),
              ),
            )
          else if (_items.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  '해당 날짜의 주문 내역이 없습니다.',
                  style: TextStyle(fontSize: 17),
                ),
              ),
            )
          else ...[
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        item['productName'].toString(),
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Text(
                        '${item['totalQuantity']}개',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF244C3A),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: const Color(0xFFE8F0E7),
              child: Text(
                '전체 ${_items.length}종류 · 총 $totalQuantity개',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
