// 💡 개별 주문 상품 정보를 담는 클래스 추가
class OrderItemRequest {
  final int id; // 상품 ID
  final int price;// 주문 가격
  final int quantity; // 주문 수량

  OrderItemRequest({
    required this.id,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'price': price, 'quantity': quantity};
  }

  factory OrderItemRequest.fromJson(Map<String, dynamic> json) {
    return OrderItemRequest(
      id: json['id'] ?? 0,
      price: json['price'] ?? 0,
      quantity: json['quantity'] ?? 0,
    );
  }
}

// 💡 수정된 메인 주문 요청 클래스
class OrderRequest {
  final int memberId;
  final int totalPrice;
  final String deliveryAddress;
  final String depositorName;
  final List<OrderItemRequest> orderItems; // 💡 단일 상품명 대신 아이템 리스트로 변경

  OrderRequest({
    required this.memberId,
    required this.totalPrice,
    required this.deliveryAddress,
    required this.depositorName,
    required this.orderItems,
  });

  factory OrderRequest.fromJson(Map<String, dynamic> json) {
    var list = json['orderItems'] as List? ?? [];
    List<OrderItemRequest> orderItemList = list
        .map((i) => OrderItemRequest.fromJson(i))
        .toList();

    return OrderRequest(
      memberId:
          json['memberId'] ??
          (json['member'] != null ? json['member']['id'] : 0),
      totalPrice: json['totalPrice'] ?? 0,
      deliveryAddress:
          json['deliveryAddress'] ?? json['delivery_address'] ?? '',
      depositorName: json['depositorName'] ?? '',
      orderItems: orderItemList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'memberId': memberId, // 💡 스프링 DTO와 완벽 매핑되도록 Camel Case 유지
      'totalPrice': totalPrice,
      'deliveryAddress': deliveryAddress,
      'depositorName': depositorName,
      'orderItems': orderItems
          .map((item) => item.toJson())
          .toList(), // 💡 리스트 직렬화
    };
  }
}
