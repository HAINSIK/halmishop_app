import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart' hide BorderStyle, Border;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';

import 'dart:typed_data';

import '../services/api_config.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

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
    '주문접수',
    '입금확인',
    '배송준비',
    '배송중',
    '배송완료',
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
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      print('❌ 주문 내역 가져오기 실패: $e');
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
        print('❌ 삭제 실패: ${response.statusCode}');
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
        print('❌ 상태 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 상태 변경 통신 에러: $e');
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
        print('❌ 주소 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 주소 변경 통신 에러: $e');
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
        print('❌ 입금자 변경 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 입금자 변경 통신 에러: $e');
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
        title: const Text('할미네 주문 장부 📜'),
        backgroundColor: Colors.orangeAccent,
        actions: [
          if (_isAdmin)
            IconButton(
              tooltip: '오늘의 반찬 집계',
              icon: const Icon(Icons.summarize),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DailyProductSummaryScreen(),
                  ),
                );
              },
            ),

          if (_isAdmin)
            PopupMenuButton<String>(
              tooltip: '주문 상태 필터',
              icon: const Icon(Icons.filter_list),
              onSelected: (status) {
                setState(() {
                  _selectedStatus = status;
                });
              },
              itemBuilder: (context) => _orderStatuses
                  .map(
                    (status) => PopupMenuItem<String>(
                      value: status,
                      child: Row(
                        children: [
                          if (_selectedStatus == status)
                            const Icon(Icons.check, size: 18)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(status),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('장부 로딩 에러: ${snapshot.error}'));
          }
          if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '아직 주문 내역이 없습니더. 👵\n맛있는 반찬을 먼저 주문해 보셔요!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final orders = snapshot.data!;
          final filteredOrders = _selectedStatus == '전체'
              ? orders
              : orders
                    .where(
                      (order) =>
                          (order['orderStatus'] ?? '주문접수') == _selectedStatus,
                    )
                    .toList();

          if (filteredOrders.isEmpty) {
            return Center(
              child: Text(
                '선택한 상태의 주문이 없습니다.',
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              final int orderId = order['id']; // 삭제를 위한 주문 ID 추출

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
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
                              color: Colors.orange,
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
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              order['orderStatus'] ?? '주문접수',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(), // 💥 왼쪽 요소들을 밀어내어 버튼을 우측 끝에 고정합니다.
                          // 💡 새로 추가된 주문 취소 버튼
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              // 실수 방지를 위해 취소 의사를 묻는 다이얼로그 띄우기
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('주문 취소하기'),
                                  content: Text(
                                    '주문번호 #$orderId 내역을 정말 장부에서 지우시겠어유?',
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text('아니오'),
                                      onPressed: () => Navigator.of(ctx).pop(),
                                    ),
                                    TextButton(
                                      child: const Text(
                                        '예, 지워주셔요',
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                        _deleteOrder(orderId); // 💥 실제 삭제 함수 실행
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: const Icon(Icons.delete_forever, size: 16),
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
                          final productName = item['productName'] ?? '상품명 없음';
                          final quantity = item['quantity'] ?? 0;
                          final price = item['price'] ?? 0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$productName (단가 ${price}원)',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                Text(
                                  '${quantity}개',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(230, 34, 32, 199),
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
                          color: Colors.redAccent,
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
                          if (_isAdmin || order['orderStatus'] == '주문접수')
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: Colors.orange,
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
                          if (_isAdmin || order['orderStatus'] == '주문접수')
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: Colors.orange,
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
                      Text(
                        '💰 주문일시: ${order['orderDate']}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),

                      // 택배 송장 정보
                      if (order['trackingNumber'] != null &&
                          order['trackingNumber'].toString().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      style: const TextStyle(fontSize: 14),
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
                                    order['trackingNumber']?.toString() ?? '',
                                  ),
                                  icon: const Icon(Icons.local_shipping),
                                  label: const Text('배송조회 바로가기'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                      order['trackingNumber'].toString().isEmpty
                                  ? '송장 등록'
                                  : '송장 수정',
                            ),
                          ),
                        ),
                      ],

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 1. 배송 시작 버튼 (현재 상태가 '주문완료'일 때만 보이거나 활성화)
                          if (_isAdmin &&
                              (order['orderStatus'] == '주문접수' ||
                                  order['orderStatus'] == '입금확인' ||
                                  order['orderStatus'] == '배송준비'))
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade400,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              onPressed: () => _updateStatus(orderId, '배송중'),
                              icon: const Icon(Icons.local_shipping, size: 16),
                              label: const Text(
                                '배송 시작',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),

                          if (_isAdmin && order['orderStatus'] == '배송중')
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade400,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                              onPressed: () => _updateStatus(orderId, '배송완료'),
                              icon: const Icon(Icons.done_all, size: 16),
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
          );
        },
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

      await FileSaver.instance.saveFile(
        name: '할미샵_주문정리_$_dateString',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

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

      await FileSaver.instance.saveFile(
        name: '할미샵_한진택배_$_dateString',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

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
                          color: Colors.blueAccent,
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
              color: Colors.orange.shade50,
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
