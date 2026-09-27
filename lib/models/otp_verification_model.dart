class OtpVerificationModel {
  final int id;
  final int userId;
  final String code;
  final String purpose;
  final DateTime expiresAt;
  final DateTime? verifiedAt;
  final String status;
  final DateTime? createdAt;

  const OtpVerificationModel({
    required this.id,
    required this.userId,
    required this.code,
    required this.purpose,
    required this.expiresAt,
    this.verifiedAt,
    required this.status,
    this.createdAt,
  });

  factory OtpVerificationModel.fromJson(Map<String, dynamic> json) {
    return OtpVerificationModel(
      id: json['otp_id'] as int,
      userId: json['user_id'] as int,
      code: json['otp_code'] as String,
      purpose: json['purpose'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      verifiedAt: json['verified_at'] == null
          ? null
          : DateTime.parse(json['verified_at'] as String),
      status: json['status'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'otp_id': id,
    'user_id': userId,
    'otp_code': code,
    'purpose': purpose,
    'expires_at': expiresAt.toIso8601String(),
    'verified_at': verifiedAt?.toIso8601String(),
    'status': status,
    'created_at': createdAt?.toIso8601String(),
  };
}
