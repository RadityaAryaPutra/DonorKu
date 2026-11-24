class AppConfig {
  // Dapat diganti saat menjalankan:
  // flutter run -d chrome --dart-define=API_URL=http://127.0.0.1:8000/api
  // Emulator Android: http://10.0.2.2:8000/api
  // HP asli: http://IP-LAPTOP:8000/api
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );
}