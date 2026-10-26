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

    factory OrderRequest.fromJson(Map<String, dynamic> json) {
    return OrderRequest(
        // 서버에서 member 객체 통째로 내려올 경우 json['member']['id']로 파싱 필요할 수 있음
      memberId: json['memberId'] ?? (json['member'] != null ? json['member']['id'] : 0),
      productName: json['productName'] ?? '',
      totalPrice: json['totalPrice'] ?? 0,
      deliveryAddress: json['delivery_address'] ?? '',
      depositorName: json['depositorName'] ?? '',
     
    );
  }

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
