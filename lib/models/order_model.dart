class OrderItemRequest {
  final int id;
  final int quantity;

  const OrderItemRequest({required this.id, required this.quantity});

  Map<String, dynamic> toJson() => {'id': id, 'quantity': quantity};

  factory OrderItemRequest.fromJson(Map<String, dynamic> json) => OrderItemRequest(
    id: _asInt(json['id']),
    quantity: _asInt(json['quantity']),
  );
}

class OrderRequest {
  final String deliveryAddress;
  final String depositorName;
  final List<OrderItemRequest> items;

  const OrderRequest({
    required this.deliveryAddress,
    required this.depositorName,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'deliveryAddress': deliveryAddress,
    'depositorName': depositorName,
    'items': items.map((item) => item.toJson()).toList(),
  };
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
