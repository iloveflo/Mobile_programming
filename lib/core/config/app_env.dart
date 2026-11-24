// lib/core/config/app_env.dart

class AppEnv {
  // Cờ bật/tắt Mock (Mặc định false khi chạy thật)
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: false,
  );

  // Môi trường chạy (dev / prod)
  static const String _env = String.fromEnvironment(
    'ENV',
    defaultValue: 'prod',
  );

  static const String _customBase = String.fromEnvironment('BASE_URL');

  static const String primaryProdUrl =
      'https://fincredit.binha10k56.id.vn/api/v1';
  static const String fallbackProdUrl =
      'https://fincredit-api-gjiz.onrender.com/api/v1';

  static bool _usingFallback = false;

  /// Có cấu hình server dự phòng Render hay không (chỉ bật ở prod khi không override BASE_URL)
  static bool get hasFallback => _env == 'prod' && _customBase.isEmpty;

  /// Đang sử dụng server dự phòng Render hay không
  static bool get isUsingFallback => _usingFallback && hasFallback;

  /// URL chính (Coolify ở prod, hoặc custom/local ở dev)
  static String get primaryBaseUrl {
    if (_customBase.isNotEmpty) {
      return _customBase;
    }
    if (_env == 'prod') {
      return primaryProdUrl;
    }
    return 'http://10.0.2.2/api/v1';
  }

  /// URL dự phòng (Render ở prod)
  static String? get fallbackBaseUrl => hasFallback ? fallbackProdUrl : null;

  /// Base URL đang hoạt động (tự động chuyển sang Render khi failover kích hoạt)
  static String get baseUrl =>
      isUsingFallback ? fallbackProdUrl : primaryBaseUrl;

  /// Chuyển lưu lượng sang server dự phòng Render
  static void switchToFallback() {
    if (hasFallback) {
      _usingFallback = true;
    }
  }

  /// Quay lại server chính Coolify (khi khởi động lại app và Coolify đã phục hồi)
  static void resetToPrimary() {
    _usingFallback = false;
  }

  /// Tạo URI `/health` ở origin gốc từ một API baseUrl bất kỳ
  static Uri healthUriFor(String apiBaseUrl) {
    final trimmed = apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final origin = trimmed.replaceFirst(RegExp(r'/api(/v\d+)?$'), '');
    return Uri.parse('$origin/health');
  }
}
