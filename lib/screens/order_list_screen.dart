import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final String baseUrl = 'http://localhost:8080/api/orders';
  late Future<List<dynamic>> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = _fetchOrders();
  }

  Future<List<dynamic>> _fetchOrders() async {
    try {
      final savedMemberId = web.window.localStorage.getItem('member_id') ?? '1';
      print('🔍 실제 내 회원 ID 번호로 장부 조회 요청 중: $savedMemberId번');

      final response = await http.get(
        Uri.parse('$baseUrl?memberId=$savedMemberId'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
      return [];
    } catch (e) {
      print('❌ 주문 내역 가져오기 실패: $e');
      return [];
    }
  }

  Future<void> _deleteOrder(int orderId) async {
    final url = Uri.parse('$baseUrl/$orderId');

    try {
      final response = await http.delete(url);

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
        headers: {"Content-Type": "application/json"},
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

  Future<void> _updateAddress(int orderId, String newAddress) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId/delivery_address'),
        headers: {"Content-Type": "application/json"},
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
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"depositor_name": newName}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _orderFuture = _fetchOrders(); // 성공 시 장부 새로고침
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('입금자명이 똑부러지게 변경되었어유!')));
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('할미네 주문 장부 📜'),
        backgroundColor: Colors.orangeAccent,
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

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
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
                              order['orderStatus'] ?? '주문완료',
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
                      Text(
                        '반찬명: ${order['productName']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                          if (order['orderStatus'] == '주문완료' ||
                              order['orderStatus'] == null)
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // 1. 배송 시작 버튼 (현재 상태가 '주문완료'일 때만 보이거나 활성화)
                          if (order['orderStatus'] == '주문완료' ||
                              order['orderStatus'] == null)
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

                          if (order['orderStatus'] == '배송중')
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
