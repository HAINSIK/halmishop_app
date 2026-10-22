class RegisterRequest {
  final String password;
  final String name;
  final String phoneNumber;

  RegisterRequest({
    required this.password,
    required this.name,
    required this.phoneNumber
  });

  // 서버로 보낼 JSON 구조 변환
  Map<String, dynamic> toJson() {
    return {
      'password': password,
      'name': name,
      'phoneNumber': phoneNumber
    };
  }
}
// lib/models/user_model.dart 에 아래 내용 추가

class LoginRequest {
  final String phoneNumber;
  final String password;

  LoginRequest({required this.phoneNumber, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber, // 스프링 로그인 DTO 필드명과 맞추세요
      'password': password
    };
  }
}

class LoginResponse {
  final String token; // 서버에서 발급한 JWT 토큰

  LoginResponse({required this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? json['accessToken'] ?? '', // 스프링 응답 key 확인 필요
    );
  }
}

