import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/auth_token_model.dart';
import '../models/user_model.dart';

/// Dịch vụ lưu trữ phiên làm việc và mã xác thực cục bộ (Session & Token Storage)
/// Tích hợp bộ nhớ đệm (In-Memory Cache) và mã hóa Android Keystore AES-GCM khi chạy trên Android APK
class SessionStorageService {
  static const MethodChannel _keystoreChannel = MethodChannel(
    'fincredit/secure_storage',
  );

  final Directory? customDirectory;
  final bool? useKeystoreOverride;

  AuthTokenModel? _cachedToken;
  UserModel? _cachedUser;
  String? _cachedIdentifier;
  ({String identifier, String password})? _cachedBiometric;
  bool _isInitialized = false;

  SessionStorageService({this.customDirectory, this.useKeystoreOverride});

  Directory get _storageDir {
    if (customDirectory != null) {
      if (!customDirectory!.existsSync()) {
        customDirectory!.createSync(recursive: true);
      }
      return customDirectory!;
    }
    // Trên Android APK: ưu tiên lưu ở app-private filesDir (/data/user/0/<pkg>/files)
    // thay vì /cache (Directory.systemTemp) để không bị OS dọn mất hoặc lộ qua cache.
    final tempDir = Directory.systemTemp;
    final dirPath = Platform.isAndroid && tempDir.path.endsWith('/cache')
        ? '${tempDir.parent.path}/files/fincredit_secure'
        : '${tempDir.path}/fincredit_storage';
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  File get _sessionFile => File('${_storageDir.path}/auth_session.json');

  File get _sessionKeyFile => File('${_storageDir.path}/.session_key');

  File get _biometricFile => File('${_storageDir.path}/biometric_binding.json');

  List<int> _getOrCreateSessionKey() {
    final keyFile = _sessionKeyFile;
    if (keyFile.existsSync()) {
      final raw = keyFile.readAsStringSync().trim();
      if (raw.isNotEmpty) {
        try {
          final decoded = base64Decode(raw);
          if (decoded.length == 32) return decoded;
        } catch (_) {}
      }
    }
    final rng = Random.secure();
    final key = List<int>.generate(32, (_) => rng.nextInt(256));
    keyFile.writeAsStringSync(base64Encode(key), flush: true);
    return key;
  }

  String _sealPayload(String plainJson) {
    final key = _getOrCreateSessionKey();
    final rng = Random.secure();
    final nonce = List<int>.generate(16, (_) => rng.nextInt(256));
    final input = utf8.encode(plainJson);
    final cipher = List<int>.generate(
      input.length,
      (i) => input[i] ^ key[i % key.length] ^ nonce[i % nonce.length],
    );
    return 'v1:${base64Encode([...nonce, ...cipher])}';
  }

  String _unsealPayload(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('{')) {
      // Tương thích ngược với file JSON cũ chưa mã hóa
      return trimmed;
    }
    if (!trimmed.startsWith('v1:')) {
      throw const FormatException('Định dạng phiên không hợp lệ');
    }
    final combined = base64Decode(trimmed.substring(3));
    if (combined.length <= 16) {
      throw const FormatException('Dữ liệu phiên bị hỏng');
    }
    final nonce = combined.sublist(0, 16);
    final cipher = combined.sublist(16);
    final key = _getOrCreateSessionKey();
    final plain = List<int>.generate(
      cipher.length,
      (i) => cipher[i] ^ key[i % key.length] ^ nonce[i % nonce.length],
    );
    return utf8.decode(plain);
  }

  void _ensureInitialized() {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      final file = _sessionFile;
      if (file.existsSync()) {
        final raw = file.readAsStringSync();
        if (raw.trim().isNotEmpty) {
          final content = _unsealPayload(raw);
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic>) {
            if (decoded['token'] != null) {
              final token = AuthTokenModel.fromJson(
                Map<String, dynamic>.from(decoded['token'] as Map),
              );
              if (!token.isExpired) {
                _cachedToken = token;
              }
            }
            if (decoded['user'] != null) {
              _cachedUser = UserModel.fromJson(
                Map<String, dynamic>.from(decoded['user'] as Map),
              );
            }
            _cachedIdentifier = decoded['last_identifier'] as String?;
          }
        }
      }
    } catch (_) {}
  }

  bool get _shouldUseKeystore =>
      useKeystoreOverride ?? (Platform.isAndroid && customDirectory == null);

  Future<String> _sealAsync(String plainJson) async {
    if (_shouldUseKeystore) {
      try {
        final encrypted = await _keystoreChannel.invokeMethod<String>(
          'encrypt',
          {'plain': plainJson},
        );
        if (encrypted != null && encrypted.startsWith('ks1:')) {
          return encrypted;
        }
      } catch (_) {}
    }
    return _sealPayload(plainJson);
  }

  Future<String> _unsealAsync(String raw) async {
    final trimmed = raw.trim();
    if (trimmed.startsWith('ks1:')) {
      final decrypted = await _keystoreChannel.invokeMethod<String>('decrypt', {
        'cipher': trimmed,
      });
      if (decrypted == null) {
        throw const FormatException('Không thể giải mã dữ liệu Keystore');
      }
      return decrypted;
    }
    return _unsealPayload(trimmed);
  }

  /// Giải mã sẵn dữ liệu Keystore vào RAM khi khởi động app
  Future<void> preload() async {
    _isInitialized = true;
    try {
      final file = _sessionFile;
      if (file.existsSync()) {
        final raw = file.readAsStringSync();
        if (raw.trim().isNotEmpty) {
          final content = await _unsealAsync(raw);
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic>) {
            if (decoded['token'] != null) {
              final token = AuthTokenModel.fromJson(
                Map<String, dynamic>.from(decoded['token'] as Map),
              );
              if (!token.isExpired) {
                _cachedToken = token;
              }
            }
            if (decoded['user'] != null) {
              _cachedUser = UserModel.fromJson(
                Map<String, dynamic>.from(decoded['user'] as Map),
              );
            }
            _cachedIdentifier = decoded['last_identifier'] as String?;
          }
        }
      }
    } catch (_) {}
    await getBiometricCredentials();
  }

  /// Lưu trữ toàn bộ thông tin phiên làm việc sau khi đăng nhập thành công
  Future<void> saveSession({
    AuthTokenModel? token,
    UserModel? user,
    String? identifier,
  }) async {
    if (token != null) _cachedToken = token;
    if (user != null) _cachedUser = user;
    if (identifier != null && identifier.isNotEmpty) {
      _cachedIdentifier = identifier;
    }
    _isInitialized = true;

    try {
      final file = _sessionFile;
      final sessionMap = <String, dynamic>{
        if (_cachedToken != null) 'token': _cachedToken!.toJson(),
        'saved_at': DateTime.now().toIso8601String(),
      };

      if (_cachedUser != null) {
        sessionMap['user'] = _cachedUser!.toJson();
      }
      if (_cachedIdentifier != null && _cachedIdentifier!.isNotEmpty) {
        sessionMap['last_identifier'] = _cachedIdentifier;
      }

      final sealed = await _sealAsync(jsonEncode(sessionMap));
      file.writeAsStringSync(sealed, flush: true);
    } catch (_) {}
  }

  /// Lấy Token hợp lệ đã lưu (trả về null nếu hết hạn hoặc chưa đăng nhập)
  Future<AuthTokenModel?> getSavedToken() async {
    return getSavedTokenSync();
  }

  /// Phiên bản đồng bộ giúp lấy token ngay lập tức trong 0ms (tránh treo widget test)
  AuthTokenModel? getSavedTokenSync() {
    _ensureInitialized();
    if (_cachedToken != null && _cachedToken!.isExpired) {
      _cachedToken = null;
    }
    return _cachedToken;
  }

  /// Lấy thông tin người dùng đã lưu
  Future<UserModel?> getSavedUser() async {
    return getSavedUserSync();
  }

  UserModel? getSavedUserSync() {
    _ensureInitialized();
    return _cachedUser;
  }

  /// Lấy tên tài khoản / Email đăng nhập gần nhất
  Future<String?> getLastIdentifier() async {
    return getLastIdentifierSync();
  }

  String? getLastIdentifierSync() {
    _ensureInitialized();
    return _cachedIdentifier;
  }

  /// Xóa sạch phiên (tùy chọn giữ lại bộ nhớ đệm trong phiên hiện tại khi không nhớ đăng nhập)
  Future<void> clearSession({bool keepMemoryCache = false}) async {
    if (!keepMemoryCache) {
      _cachedToken = null;
      _cachedUser = null;
      _cachedIdentifier = null;
    }
    _isInitialized = true;

    try {
      final file = _sessionFile;
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }

  /// Lưu thông tin liên kết đăng nhập sinh trắc học trên thiết bị (không bị xóa khi đăng xuất)
  Future<void> saveBiometricCredentials({
    required String identifier,
    required String password,
  }) async {
    if (identifier.trim().isEmpty || password.isEmpty) return;
    final cleanId = identifier.trim();
    _cachedBiometric = (identifier: cleanId, password: password);
    try {
      final payload = jsonEncode({'identifier': cleanId, 'password': password});
      final sealed = await _sealAsync(payload);
      _biometricFile.writeAsStringSync(sealed, flush: true);
    } catch (_) {}
  }

  ({String identifier, String password})? _parseBiometricJson(String jsonStr) {
    final decoded = jsonDecode(jsonStr);
    if (decoded is Map<String, dynamic>) {
      final identifier = (decoded['identifier'] ?? '').toString().trim();
      final password = (decoded['password'] ?? '').toString();
      if (identifier.isNotEmpty && password.isNotEmpty) {
        return (identifier: identifier, password: password);
      }
    }
    return null;
  }

  /// Lấy thông tin liên kết sinh trắc học đã lưu trên thiết bị (nếu có)
  Future<({String identifier, String password})?>
  getBiometricCredentials() async {
    if (_cachedBiometric != null) return _cachedBiometric;
    try {
      final file = _biometricFile;
      if (!file.existsSync()) return null;
      final raw = file.readAsStringSync().trim();
      if (raw.isEmpty) return null;
      final jsonStr = (raw.startsWith('ks1:') || raw.startsWith('v1:'))
          ? await _unsealAsync(raw)
          : utf8.decode(base64Decode(raw));
      _cachedBiometric = _parseBiometricJson(jsonStr);
      return _cachedBiometric;
    } catch (_) {}
    return null;
  }

  ({String identifier, String password})? getBiometricCredentialsSync() {
    if (_cachedBiometric != null) return _cachedBiometric;
    try {
      final file = _biometricFile;
      if (!file.existsSync()) return null;
      final raw = file.readAsStringSync().trim();
      if (raw.isEmpty || raw.startsWith('ks1:')) return null;
      final jsonStr = raw.startsWith('v1:')
          ? _unsealPayload(raw)
          : utf8.decode(base64Decode(raw));
      _cachedBiometric = _parseBiometricJson(jsonStr);
      return _cachedBiometric;
    } catch (_) {}
    return null;
  }

  /// Xóa thông tin liên kết sinh trắc học khi người dùng tắt tính năng hoặc đổi mật khẩu
  Future<void> clearBiometricCredentials() async {
    _cachedBiometric = null;
    try {
      final file = _biometricFile;
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }

  /// Lấy hoặc tạo mới mã định danh duy nhất cho thiết bị hiện tại (không bị xóa khi đăng xuất)
  String getOrCreateDeviceId() {
    try {
      final file = File('${_storageDir.path}/device_id.txt');
      if (file.existsSync()) {
        final existing = file.readAsStringSync().trim();
        if (existing.isNotEmpty) return existing;
      }
      final rng = Random.secure();
      final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
      final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      final generated =
          '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
      file.writeAsStringSync(generated, flush: true);
      return generated;
    } catch (_) {
      return 'default';
    }
  }
}
