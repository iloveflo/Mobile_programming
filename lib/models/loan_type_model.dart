class LoanTypeModel {
  final int id;
  final String name;
  final String? description;
  final DateTime? createdAt;

  const LoanTypeModel({
    required this.id,
    required this.name,
    this.description,
    this.createdAt,
  });

  factory LoanTypeModel.fromJson(Map<String, dynamic> json) {
    return LoanTypeModel(
      id: json['loan_type_id'] as int,
      name: json['type_name'] as String,
      description: json['description'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'loan_type_id': id,
    'type_name': name,
    'description': description,
    'created_at': createdAt?.toIso8601String(),
  };
}
