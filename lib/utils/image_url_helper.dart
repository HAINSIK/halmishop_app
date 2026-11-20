import '../services/api_config.dart';

String getImageUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.trim().isEmpty) {
    return '';
  }

  final url = imageUrl.trim();

  // 이미 완성된 URL이면 그대로 사용
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }

  // 서버 기본 주소
  final baseUrl = ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '');

  // 상대 경로를 절대 경로로 변환
  final path = url.startsWith('/') ? url : '/$url';

  return '$baseUrl$path';
}
