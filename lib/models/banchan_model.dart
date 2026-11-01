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
    // return Banchan(
    //   id: json['id'] ?? 0,
    //   name: json['name'] ?? '',
    //   price: json['price'] ?? 0,
    //   category: json['category'] ?? '',
    //   isLiveProduct: json['is_Live_Product'] ?? false,
    //   imageUrl:
    //       json['imageUrl'] ?? 'https://placeholder.com', // 이미지 없을 때 기본 이미지
    // );

    final rawId = json['id'];
    int parsedId = 0;
    if (rawId != null) {
      parsedId = int.tryParse(rawId.toString()) ?? 0;
    }

    final rawPrice = json['price'];
    int parsedPrice = 0;
    if (rawPrice != null) {
      parsedPrice = int.tryParse(rawPrice.toString()) ?? 0;
    }

    final rawLive = json['liveProduct'];
    bool parsedLive = false;
    
    if (rawLive != null) {
      if (rawLive is bool) {
        parsedLive = rawLive; // 이미 bool 형태면 그대로 대입
      } else if (rawLive is num) {
        parsedLive = (rawLive == 1); // 💡 MySQL의 1이면 true, 0이면 false로 캐스팅!
      } else {
        // 문자열 등으로 들어올 경우의 방어
        String liveStr = rawLive.toString().trim().toLowerCase();
        parsedLive = (liveStr == 'true' || liveStr == '1');
      }
    }

     return Banchan(
      id: parsedId,
      name: json['name'] ?? '',
      price: parsedPrice, 
      imageUrl: json['imageUrl'] ?? 'https://placeholder.com', 
      category: json['category'] ?? '',
      isLiveProduct: parsedLive, // ◀ 정밀 가공된 결과 바인딩 완료!
    );
    }
}
