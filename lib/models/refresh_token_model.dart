class RefreshTokenModel {
  final int id;
  final int userId;
  final String token;
  final DateTime expiresAt;
  final DateTime? revokedAt;
  final DateTime? createdAt;

  const RefreshTokenModel({
    required this.id,
    required this.userId,
    required this.token,
    required this.expiresAt,
    this.revokedAt,
    this.createdAt,
  });

  factory RefreshTokenModel.fromJson(Map<String, dynamic> json) {
    return RefreshTokenModel(
      id: json['token_id'] as int,
      userId: json['user_id'] as int,
      token: json['token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      revokedAt: json['revoked_at'] == null
          ? null
          : DateTime.parse(json['revoked_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'token_id': id,
    'user_id': userId,
    'token': token,
    'expires_at': expiresAt.toIso8601String(),
    'revoked_at': revokedAt?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
  };
}
