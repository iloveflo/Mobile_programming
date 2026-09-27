class PaymentScheduleModel {
  final int id;
  final int loanId;
  final int installmentNumber;
  final DateTime dueDate;
  final double principalAmount;
  final double interestAmount;
  final double feeAmount;
  final double totalAmount;
  final double remainingBalance;
  final String status;
  final DateTime? createdAt;

  const PaymentScheduleModel({
    required this.id,
    required this.loanId,
    required this.installmentNumber,
    required this.dueDate,
    required this.principalAmount,
    required this.interestAmount,
    required this.feeAmount,
    required this.totalAmount,
    required this.remainingBalance,
    required this.status,
    this.createdAt,
  });

  factory PaymentScheduleModel.fromJson(Map<String, dynamic> json) {
    return PaymentScheduleModel(
      id: json['schedule_id'] as int,
      loanId: json['loan_id'] as int,
      installmentNumber: json['installment_number'] as int,
      dueDate: DateTime.parse(json['due_date'] as String),
      principalAmount: (json['principal_amount'] as num).toDouble(),
      interestAmount: (json['interest_amount'] as num).toDouble(),
      feeAmount: (json['fee_amount'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      remainingBalance: (json['remaining_balance'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'schedule_id': id,
    'loan_id': loanId,
    'installment_number': installmentNumber,
    'due_date': dueDate.toIso8601String(),
    'principal_amount': principalAmount,
    'interest_amount': interestAmount,
    'fee_amount': feeAmount,
    'total_amount': totalAmount,
    'remaining_balance': remainingBalance,
    'status': status,
    'created_at': createdAt?.toIso8601String(),
  };
}
