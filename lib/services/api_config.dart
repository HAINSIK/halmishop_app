class ApiConfig {
  // Chrome local test: localhost. For a physical phone, override with the PC's LAN IP:
  // flutter run -d <device> --dart-define=API_BASE_URL=http://192.168.0.10:8080
  // Use HTTPS for any internet-facing deployment.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
