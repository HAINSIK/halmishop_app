import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/banchan_model.dart';
import 'models/order_model.dart';
import 'services/banchan_service.dart';
import 'services/order_service.dart';

class CartItem {
  final Banchan banchan;
  int quantity;
  CartItem({required this.banchan, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final OrderService _orderService = OrderService();
  final BanchanService _banchanService = BanchanService();

  Future<void> _pendingCartSave = Future.value();

  Future<String?> _cartStorageKey() async {
    final prefs = await SharedPreferences.getInstance();

    final memberId = prefs.getString('member_id');

    if (memberId == null || memberId.isEmpty) {
      return null;
    }

    return 'cart_member_$memberId';
  }

  Future<void> _saveCart() {
    // 저장 요청 시점의 장바구니 데이터를 미리 복사
    final cartData = _items.map((item) {
      return {'productId': item.banchan.id, 'quantity': item.quantity};
    }).toList();

    final encodedData = jsonEncode(cartData);

    // 저장 요청을 순서대로 실행
    final keyFuture = _cartStorageKey();

    final saveTask = _pendingCartSave
        .catchError((Object error) {
          debugPrint('이전 장바구니 저장 오류: $error');
        })
        .then((_) async {
          // 저장 요청이 발생했을 때의 회원 저장 공간 사용
          final key = await keyFuture;
          if (key == null) return;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(key, encodedData);
        });

    _pendingCartSave = saveTask;

    return saveTask;
  }

  Future<void> waitForCartSave() async {
    try {
      await _pendingCartSave;
      debugPrint('장바구니 저장 작업 완료');
    } catch (e) {
      debugPrint('장바구니 저장 대기 중 오류: $e');
      rethrow;
    }
  }

  Future<List<Map<String, int>>> _loadSavedCart() async {
    final key = await _cartStorageKey();

    if (key == null) return [];

    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(key);

    if (savedData == null || savedData.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(savedData);

      if (decoded is! List) return [];

      final List<Map<String, int>> result = [];

      for (final item in decoded) {
        if (item is! Map) continue;

        final productId = int.tryParse(item['productId'].toString());

        final quantity = int.tryParse(item['quantity'].toString());

        if (productId == null || productId <= 0) continue;
        if (quantity == null || quantity <= 0) continue;

        result.add({'productId': productId, 'quantity': quantity});
      }

      return result;
    } catch (e) {
      debugPrint('장바구니 저장 데이터 읽기 오류: $e');
      return [];
    }
  }

  Future<bool> restoreCart() async {
    final key = await _cartStorageKey();

    if (key == null) return false;

    final savedItems = await _loadSavedCart();

    // 서버에서 최신 상품 목록 가져오기
    final products = await _banchanService.fetchBanchanList();

    // 상품 조회 실패 시 기존 장바구니를 변경하지 않음
    if (products.isEmpty) {
      debugPrint('장바구니 복원 보류: 상품 목록이 비어 있습니다.');
      return false;
    }

    // 비동기 작업 중 로그인 계정이 바뀌었는지 확인
    if (await _cartStorageKey() != key) {
      debugPrint('장바구니 복원 취소: 로그인 계정 변경');
      return false;
    }

    final List<CartItem> restoredItems = [];

    for (final saved in savedItems) {
      final productId = saved['productId'];
      final quantity = saved['quantity'];

      for (final product in products) {
        if (product.id == productId) {
          restoredItems.add(CartItem(banchan: product, quantity: quantity!));
          break;
        }
      }
    }

    _items.clear();
    _items.addAll(restoredItems);

    notifyListeners();

    debugPrint('장바구니 복원 완료: ${_items.length}개 품목');

    return true;
  }

  List<CartItem> get items => List.unmodifiable(_items);

  void clearCartForAccountChange() {
    _items.clear();
    notifyListeners();
  }

  void addBanchan(Banchan banchan) {
    final index = _items.indexWhere((item) => item.banchan.id == banchan.id);

    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(banchan: banchan));
    }

    notifyListeners();

    _saveCart();
  }

  void increaseQuantity(int index) {
    if (index < 0 || index >= _items.length) return;
    _items[index].quantity++;
    notifyListeners();
    _saveCart();
  }

  void decreaseQuantity(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
    _saveCart();
  }

  int get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.banchan.price * item.quantity);

  Future<bool> placeOrderFromCartWithDetails({
    required String address,
    required String depositor,
    required String recipientName,
    required String recipientPhone,
  }) async {
    if (_items.isEmpty) return false;
    final request = OrderRequest(
      deliveryAddress: address.trim(),
      depositorName: depositor.trim(),
      recipientName: recipientName.trim(),
      recipientPhone: recipientPhone.trim(),
      items: _items
          .map(
            (item) =>
                OrderItemRequest(id: item.banchan.id, quantity: item.quantity),
          )
          .toList(),
    );
    final success = await _orderService.createOrder(request);
    if (success) {
      _items.clear();
      notifyListeners();

      await _saveCart();
    }
    return success;
  }
}
