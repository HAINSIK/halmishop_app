class OrderRequest {
  final int memberId; // 주문할 반찬 ID (Long -> int 대응)
  final String productName; // 주문 수량
  final int totalPrice;
  final String deliveryAddress;
  final String depositorName;
    
  OrderRequest({
    required this.memberId,
    required this.productName,
    required this.totalPrice,
    required this.deliveryAddress,
    required this.depositorName,
  });

  Map<String, dynamic> toJson() {
    return {
      'memberId' : memberId, // 스프링 DTO 필드명과 일치시켜야 합니다.
      'productName' : productName,
      'totalPrice': totalPrice,
     'deliveryAddress' : deliveryAddress,
      'depositorName' : depositorName,
    };
  }
}
