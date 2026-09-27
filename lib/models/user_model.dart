class UserModel {
  final int userId;
  final String fullName;
  final String email;
  final String? phone;
  final String passwordHash;
  final double? monthlyIncome;
  final DateTime? dateOfBirth;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? token;

  const UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    required this.passwordHash,
    this.monthlyIncome,
    this.dateOfBirth,
    this.createdAt,
    this.updatedAt,
    this.token,
  });

  int get id => userId;

  String get name => fullName;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawUserId = json['user_id'] ?? json['id'];
    final parsedUserId = rawUserId is num
        ? rawUserId.toInt()
        : int.tryParse('$rawUserId') ?? 0;

    DateTime? parseDate(String key) =>
        json[key] == null ? null : DateTime.parse(json[key] as String);

    return UserModel(
      userId: parsedUserId,
      fullName: json['full_name'] as String? ?? json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      passwordHash: json['password_hash'] as String? ?? '',
      monthlyIncome: (json['monthly_income'] as num?)?.toDouble(),
      dateOfBirth: parseDate('date_of_birth'),
      createdAt: parseDate('created_at'),
      updatedAt: parseDate('updated_at'),
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'password_hash': passwordHash,
    'monthly_income': monthlyIncome,
    'date_of_birth': dateOfBirth?.toIso8601String(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'token': token,
  };
}
