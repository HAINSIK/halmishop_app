// lib/providers/cart_provider.dart 전체 교체
import 'package:flutter/material.dart';

import '../models/banchan_model.dart';
import '../services/banchan_service.dart';

class CartItem {
  final Banchan banchan;
  int quantity;

  CartItem({required this.banchan, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final BanchanService _banchanService = BanchanService();

  List<CartItem> get items => _items;

  // 장바구니에 상품 추가
  void addBanchan(Banchan banchan) {
    int index = _items.indexWhere((item) => item.banchan.name == banchan.name);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(banchan: banchan));
    }
    notifyListeners();
  }

  // 수량 증가
  void increaseQuantity(int index) {
    _items[index].quantity++;
    notifyListeners();
  }

  // 수량 감소
  void decreaseQuantity(int index) {
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  // 실시간 장바구니 총 금액 정산
  int get totalPrice {
    return _items.fold(
      0,
      (sum, item) => sum + (item.banchan.price * item.quantity),
    );
  }

  // 💡 [최종 매칭 완료] OrderItemDto와 OrderRequestDto 양식에 완벽 결합된 전송 함수
  Future<bool> placeOrderFromCartWithDetails({
    required String address,
    required String depositor,
  }) async {
    if (_items.isEmpty) return false;

    // 💡 스프링 자바 OrderRequestDto 및 OrderItemDto에 적힌 대소문자 변수명과 100% 똑같이 맵핑했습니다!
    final Map<String, dynamic> orderData = {
      
      'memberId': 1, // OrderRequestDto의 memberId
      'totalPrice': totalPrice, // OrderRequestDto의 totalPrice
      'deliveryAddress': address, // OrderRequestDto의 deliveryAddress
      'depositorName': depositor, // OrderRequestDto의 depositorName (카멜케이스 일치!)
      'items': _items
          .map(
            (item) => {
              'id': item
                  .banchan
                  .id, // 💥 OrderItemDto의 private Long id; 필드와 완벽 매칭!
              'productName': item.banchan.name, // OrderItemDto의 productName
              'price': item.banchan.price, // OrderItemDto의 price
              'quantity': item.quantity, // OrderItemDto의 quantity
            },
          )
          .toList(),
    };

    // 스프링 백엔드 서버 호출 (http.post)
    bool isSuccess = await _banchanService.createOrder(orderData);

    // MySQL 두 테이블에 저장이 완전히 끝나 성공 코드가 떨어졌을 때만 장바구니 비우기
    if (isSuccess) {
      _items.clear();
      notifyListeners();
      return true;
    }
    return false;
  }
}
