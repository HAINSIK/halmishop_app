import 'package:flutter/material.dart';
import 'models/banchan_model.dart';
import 'models/order_model.dart';
import 'services/order_service.dart';

class CartItem {
  final Banchan banchan;
  int quantity;
  CartItem({required this.banchan, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final OrderService _orderService = OrderService();

  List<CartItem> get items => List.unmodifiable(_items);

  void addBanchan(Banchan banchan) {
    final index = _items.indexWhere((item) => item.banchan.id == banchan.id);
    if (index >= 0) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(banchan: banchan));
    }
    notifyListeners();
  }

  void increaseQuantity(int index) {
    if (index < 0 || index >= _items.length) return;
    _items[index].quantity++;
    notifyListeners();
  }

  void decreaseQuantity(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_items[index].quantity > 1) {
      _items[index].quantity--;
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
  }

  int get totalPrice => _items.fold(0, (sum, item) => sum + item.banchan.price * item.quantity);

  Future<bool> placeOrderFromCartWithDetails({
    required String address,
    required String depositor,
  }) async {
    if (_items.isEmpty) return false;
    final request = OrderRequest(
      deliveryAddress: address.trim(),
      depositorName: depositor.trim(),
      items: _items.map((item) => OrderItemRequest(
        id: item.banchan.id,
        quantity: item.quantity,
      )).toList(),
    );
    final success = await _orderService.createOrder(request);
    if (success) {
      _items.clear();
      notifyListeners();
    }
    return success;
  }
}
