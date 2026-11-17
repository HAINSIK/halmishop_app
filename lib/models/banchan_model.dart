class Banchan {
  final int id;
  final String name;
  final int price;
  final String imageUrl;
  final String category;
  final String description; // 148-4-3: 상품 상세 설명
  final bool isLiveProduct;
  // 143-11: 관리자 지정 추천 반찬 여부
  final bool isRecommended;
  // 146-2-8-5-6단계: 오늘 준비한 반찬 여부
  final bool isTodayPrepared;
  // 149-5-11단계: 상품 판매 가능 여부
  final bool isSaleEnabled;

  Banchan({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrl,
    required this.isLiveProduct,
    this.isRecommended = false,
    this.isTodayPrepared = false,
    this.isSaleEnabled = true,
    this.description = '', // 기존 Banchan 생성 코드와 호환
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
      description: json['description']?.toString() ?? '',
      isLiveProduct: parsedLive,

      // 143-11: 서버의 recommended 값을 Flutter에 연결
      isRecommended:
          json['recommended'] == true ||
          json['recommended'] == 1 ||
          json['recommended']?.toString().toLowerCase() == 'true',

      // 146-2-8-5-6단계: 오늘 준비한 반찬 정보
      isTodayPrepared:
          json['todayPrepared'] == true ||
          json['todayPrepared'] == 1 ||
          json['todayPrepared']?.toString().toLowerCase() == 'true',

      //반찬 판매 상태 여부 , // 149-5-11단계: 서버의 saleEnabled 값을 Flutter에 연결
      isSaleEnabled:
          json['saleEnabled'] == true ||
          json['saleEnabled'] == 1 ||
          json['saleEnabled']?.toString().toLowerCase() == 'true',
    );
  }
}
