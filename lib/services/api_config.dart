class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // defaultValue: 'http://192.168.45.150:8080',

    defaultValue: 'http://localhost:8080',
  );
}
