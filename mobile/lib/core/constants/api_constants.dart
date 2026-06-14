class ApiConstants {
  ApiConstants._();

  // Linux desktop / iOS sim / web: localhost. Android emulator: 10.0.2.2.
  // Physical device: your machine's LAN IP (and add it to DJANGO_ALLOWED_HOSTS).
  static const String baseUrl = 'http://127.0.0.1:8000/api/';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
