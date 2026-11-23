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

  factory PaymentScheduleModel.fromJson(Map<String, dynamic> rawJson) {
    final dynamic nested = rawJson['data'];
    final Map<String, dynamic> json = nested is Map<String, dynamic>
        ? nested
        : (nested is Map ? Map<String, dynamic>.from(nested) : rawJson);

    int parseInt(dynamic val, [int fallback = 0]) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    double parseDouble(dynamic val, [double fallback = 0.0]) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? fallback;
      return fallback;
    }

    DateTime parseDate(dynamic val) {
      if (val is DateTime) return val;
      if (val is String) {
        final parsed = DateTime.tryParse(val);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return PaymentScheduleModel(
      id: parseInt(json['schedule_id'] ?? json['id']),
      loanId: parseInt(json['loan_id'] ?? json['loanId']),
      installmentNumber: parseInt(
        json['installment_number'] ??
            json['period_number'] ??
            json['installmentNumber'],
        1,
      ),
      dueDate: parseDate(json['due_date'] ?? json['dueDate']),
      principalAmount: parseDouble(
        json['principal_amount'] ??
            json['principal_due'] ??
            json['principalAmount'],
      ),
      interestAmount: parseDouble(
        json['interest_amount'] ??
            json['interest_due'] ??
            json['interestAmount'],
      ),
      feeAmount: parseDouble(json['fee_amount'] ?? json['feeAmount']),
      totalAmount: parseDouble(
        json['total_amount'] ?? json['total_due'] ?? json['totalAmount'],
      ),
      remainingBalance: parseDouble(
        json['remaining_balance'] ?? json['remainingBalance'],
      ),
      status: (json['status'] ?? 'UNPAID').toString(),
      createdAt: parseNullableDate(json['created_at'] ?? json['createdAt']),
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

  PaymentScheduleModel copyWith({
    int? id,
    int? loanId,
    int? installmentNumber,
    DateTime? dueDate,
    double? principalAmount,
    double? interestAmount,
    double? feeAmount,
    double? totalAmount,
    double? remainingBalance,
    String? status,
    DateTime? createdAt,
  }) {
    return PaymentScheduleModel(
      id: id ?? this.id,
      loanId: loanId ?? this.loanId,
      installmentNumber: installmentNumber ?? this.installmentNumber,
      dueDate: dueDate ?? this.dueDate,
      principalAmount: principalAmount ?? this.principalAmount,
      interestAmount: interestAmount ?? this.interestAmount,
      feeAmount: feeAmount ?? this.feeAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
