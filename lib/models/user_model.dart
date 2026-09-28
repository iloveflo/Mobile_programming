import 'bank_account_model.dart';

class UserModel {
  final int userId;
  final String fullName;
  final String email;
  final String? phone;
  final String passwordHash;
  final double? monthlyIncome;
  final DateTime? dateOfBirth;
  final String? idCardNumber;
  final String? address;
  final String? occupation;
  final String? workplace;
  final String? contractType;
  final bool isEkycVerified;
  final String? ekycTier;
  final String membershipTier;
  final int? cicScore;
  final List<BankAccountModel> bankAccounts;
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
    this.idCardNumber,
    this.address,
    this.occupation,
    this.workplace,
    this.contractType,
    this.isEkycVerified = false,
    this.ekycTier,
    this.membershipTier = 'STANDARD',
    this.cicScore,
    this.bankAccounts = const [],
    this.createdAt,
    this.updatedAt,
    this.token,
  });

  int get id => userId;

  String get name => fullName;

  UserModel copyWith({
    int? userId,
    String? fullName,
    String? email,
    String? phone,
    String? passwordHash,
    double? monthlyIncome,
    DateTime? dateOfBirth,
    String? idCardNumber,
    String? address,
    String? occupation,
    String? workplace,
    String? contractType,
    bool? isEkycVerified,
    String? ekycTier,
    String? membershipTier,
    int? cicScore,
    List<BankAccountModel>? bankAccounts,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? token,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      idCardNumber: idCardNumber ?? this.idCardNumber,
      address: address ?? this.address,
      occupation: occupation ?? this.occupation,
      workplace: workplace ?? this.workplace,
      contractType: contractType ?? this.contractType,
      isEkycVerified: isEkycVerified ?? this.isEkycVerified,
      ekycTier: ekycTier ?? this.ekycTier,
      membershipTier: membershipTier ?? this.membershipTier,
      cicScore: cicScore ?? this.cicScore,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      token: token ?? this.token,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawUserId = json['user_id'] ?? json['id'];
    final parsedUserId = rawUserId is num
        ? rawUserId.toInt()
        : int.tryParse('$rawUserId') ?? 0;

    DateTime? parseDate(String key) =>
        json[key] == null ? null : DateTime.tryParse(json[key] as String);

    List<BankAccountModel> parseBankAccounts(dynamic rawList) {
      if (rawList is List) {
        return rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => BankAccountModel.fromJson(item))
            .toList();
      }
      return const [];
    }

    return UserModel(
      userId: parsedUserId,
      fullName: json['full_name'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      passwordHash: json['password_hash'] as String? ?? '',
      monthlyIncome: (json['monthly_income'] as num?)?.toDouble(),
      dateOfBirth: parseDate('date_of_birth'),
      idCardNumber:
          json['id_card_number'] as String? ?? json['idCardNumber'] as String?,
      address: json['address'] as String?,
      occupation: json['occupation'] as String?,
      workplace: json['workplace'] as String?,
      contractType:
          json['contract_type'] as String? ?? json['contractType'] as String?,
      isEkycVerified:
          (json['is_ekyc_verified'] ?? json['isEkycVerified']) as bool? ??
          false,
      ekycTier: json['ekyc_tier'] as String? ?? json['ekycTier'] as String?,
      membershipTier:
          json['membership_tier'] as String? ??
          json['membershipTier'] as String? ??
          'STANDARD',
      cicScore: (json['cic_score'] ?? json['cicScore']) as int?,
      bankAccounts: parseBankAccounts(
        json['bank_accounts'] ?? json['bankAccounts'],
      ),
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
    'id_card_number': idCardNumber,
    'address': address,
    'occupation': occupation,
    'workplace': workplace,
    'contract_type': contractType,
    'is_ekyc_verified': isEkycVerified,
    'ekyc_tier': ekycTier,
    'membership_tier': membershipTier,
    'cic_score': cicScore,
    'bank_accounts': bankAccounts.map((a) => a.toJson()).toList(),
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'token': token,
  };
}
