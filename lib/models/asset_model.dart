class AssetModel {
  final int id;
  final int userId;
  final int? loanId;
  final String name;
  final String type;
  final double value;
  final DateTime? valuationDate;
  final String? description;
  final DateTime? createdAt;

  const AssetModel({
    required this.id,
    required this.userId,
    this.loanId,
    required this.name,
    required this.type,
    required this.value,
    this.valuationDate,
    this.description,
    this.createdAt,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['asset_id'] as int,
      userId: json['user_id'] as int,
      loanId: json['loan_id'] as int?,
      name: json['asset_name'] as String,
      type: json['asset_type'] as String,
      value: (json['asset_value'] as num).toDouble(),
      valuationDate: json['valuation_date'] == null
          ? null
          : DateTime.parse(json['valuation_date'] as String),
      description: json['description'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'asset_id': id,
    'user_id': userId,
    'loan_id': loanId,
    'asset_name': name,
    'asset_type': type,
    'asset_value': value,
    'valuation_date': valuationDate?.toIso8601String(),
    'description': description,
    'created_at': createdAt?.toIso8601String(),
  };
}
