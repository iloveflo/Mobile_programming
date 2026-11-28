/// Mô hình đại diện cho cặp mã xác thực truy cập (Access Token & Refresh Token)
class AuthTokenModel {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final DateTime? expiresAt;
  final DateTime? accessExpiresAt;
  final int? userId;

  const AuthTokenModel({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresAt,
    this.accessExpiresAt,
    this.userId,
  });

  /// Mã token truy cập (alias chuẩn cho accessToken)
  String get token => accessToken;

  /// Kiểm tra xem access token đã hết hạn hay chưa
  bool get isAccessTokenExpired {
    if (accessExpiresAt == null) return false;
    return DateTime.now().isAfter(accessExpiresAt!);
  }

  /// Kiểm tra xem phiên (refresh token) đã hết hạn hay chưa
  bool get isExpired {
    if (expiresAt == null) {
      return false;
    }
    return DateTime.now().isAfter(expiresAt!);
  }

  AuthTokenModel copyWith({
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    DateTime? expiresAt,
    DateTime? accessExpiresAt,
    int? userId,
  }) {
    return AuthTokenModel(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresAt: expiresAt ?? this.expiresAt,
      accessExpiresAt: accessExpiresAt ?? this.accessExpiresAt,
      userId: userId ?? this.userId,
    );
  }

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) {
        return null;
      }
      if (val is DateTime) {
        return val;
      }
      return DateTime.tryParse(val.toString());
    }

    return AuthTokenModel(
      accessToken:
          (json['access_token'] ?? json['accessToken'] ?? json['token'] ?? '')
              as String,
      refreshToken: (json['refresh_token'] ?? json['refreshToken']) as String?,
      tokenType:
          (json['token_type'] ?? json['tokenType'] ?? 'Bearer') as String,
      expiresAt: parseDate(json['expires_at'] ?? json['expiresAt']),
      accessExpiresAt: parseDate(
        json['access_expires_at'] ?? json['accessExpiresAt'],
      ),
      userId: json['user_id'] is num
          ? (json['user_id'] as num).toInt()
          : int.tryParse(json['user_id']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'token_type': tokenType,
    'expires_at': expiresAt?.toIso8601String(),
    if (accessExpiresAt != null)
      'access_expires_at': accessExpiresAt!.toIso8601String(),
    'user_id': userId,
  };
}
