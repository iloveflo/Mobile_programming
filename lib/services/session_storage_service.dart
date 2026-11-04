import 'dart:convert';
import 'dart:io';

import '../models/auth_token_model.dart';
import '../models/user_model.dart';

/// Dịch vụ lưu trữ phiên làm việc và mã xác thực cục bộ (Session & Token Storage)
/// Tích hợp bộ nhớ đệm (In-Memory Cache) và đọc/ghi tệp đồng bộ (Synchronous I/O)
/// Đảm bảo tính nhất quán tuyệt đối, không bị treo (timeout) trong FakeAsync Unit/Widget Tests
class SessionStorageService {
  final Directory? customDirectory;

  AuthTokenModel? _cachedToken;
  UserModel? _cachedUser;
  String? _cachedIdentifier;
  bool _isInitialized = false;

  SessionStorageService({this.customDirectory});

  File get _sessionFile {
    final dirPath =
        customDirectory?.path ??
        '${Directory.systemTemp.path}/fincredit_storage';
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return File('${dir.path}/auth_session.json');
  }

  void _ensureInitialized() {
    if (_isInitialized) return;
    _isInitialized = true;
    try {
      final file = _sessionFile;
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.trim().isNotEmpty) {
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

      file.writeAsStringSync(jsonEncode(sessionMap), flush: true);
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

  /// Xóa sạch phiên khi người dùng chủ động Đăng xuất (Logout)
  Future<void> clearSession() async {
    _cachedToken = null;
    _cachedUser = null;
    _isInitialized = true;

    try {
      final file = _sessionFile;
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }
}
