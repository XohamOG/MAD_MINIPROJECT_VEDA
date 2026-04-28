class AppConfig {
  const AppConfig._();

  // On Android emulators use 10.0.2.2, but on physical devices use your PC LAN IP.
  // Override anytime with:
  // flutter run --dart-define=API_BASE_URL=http://<YOUR_PC_LAN_IP>:8000/api
  static const String baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.29.107:8000/api');
}
