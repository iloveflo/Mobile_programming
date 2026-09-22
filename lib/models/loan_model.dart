class LoanModel {
  final int id;
  final int userId;
  final int loanTypeId;
  final String name;
  final double principalAmount;
  final double interestRate;
  final String interestMethod;
  final int termMonths;
  final DateTime startDate;
  final DateTime? endDate;
  final double outstandingAmount;
  final double earlyPaymentFeeRate;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LoanModel({
    required this.id,
    required this.userId,
    required this.loanTypeId,
    required this.name,
    required this.principalAmount,
    required this.interestRate,
    required this.interestMethod,
    required this.termMonths,
    required this.startDate,
    this.endDate,
    required this.outstandingAmount,
    required this.earlyPaymentFeeRate,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    return LoanModel(
      id: json['loan_id'] as int,
      userId: json['user_id'] as int,
      loanTypeId: json['loan_type_id'] as int,
      name: json['loan_name'] as String,
      principalAmount: (json['principal_amount'] as num).toDouble(),
      interestRate: (json['interest_rate'] as num).toDouble(),
      interestMethod: json['interest_method'] as String,
      termMonths: json['term_months'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.parse(json['end_date'] as String),
      outstandingAmount: (json['outstanding_amount'] as num).toDouble(),
      earlyPaymentFeeRate:
          (json['early_payment_fee_rate'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'loan_id': id,
        'user_id': userId,
        'loan_type_id': loanTypeId,
        'loan_name': name,
        'principal_amount': principalAmount,
        'interest_rate': interestRate,
        'interest_method': interestMethod,
        'term_months': termMonths,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'outstanding_amount': outstandingAmount,
        'early_payment_fee_rate': earlyPaymentFeeRate,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
