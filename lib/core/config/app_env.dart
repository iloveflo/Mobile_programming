// lib/core/config/app_env.dart

class AppEnv {
  // Cờ bật/tắt Mock (Mặc định true để tiện code UI)
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );

  // Môi trường chạy (dev / prod)
  static const String _env = String.fromEnvironment('ENV', defaultValue: 'dev');

  // Base URL tự động chuyển theo môi trường hoặc cấu hình qua --dart-define=BASE_URL=...
  static String get baseUrl {
    const String customBase = String.fromEnvironment('BASE_URL');
    if (customBase.isNotEmpty) {
      return customBase;
    }
    if (_env == 'prod') {
      return 'https://api.production.com/api/v1';
    }
    // Mặc định chạy server local khi dev (10.0.2.2 cho Android Emulator)
    return 'http://10.0.2.2:3000/api/v1';
  }
}
