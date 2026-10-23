class Banchan {
  final int id;
  final String name;
  final int price;
  final String imageUrl;
  final String category;
  final bool isLiveProduct;

  Banchan({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.isLiveProduct,
  });

  // JSON 데이터를 플러터 객체로 변환
  factory Banchan.fromJson(Map<String, dynamic> json) {
    return Banchan(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      category: json['category'] ?? '',
      isLiveProduct: json['is_Live_Product'] ?? false,
      imageUrl:
          json['imageUrl'] ?? 'https://placeholder.com', // 이미지 없을 때 기본 이미지
    );
  }
}
