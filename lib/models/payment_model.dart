class PaymentModel {
  final int id;
  final int scheduleId;
  final double paidAmount;
  final DateTime paidDate;
  final String paymentMethod;
  final String? transactionReference;
  final String? note;
  final DateTime? createdAt;

  const PaymentModel({
    required this.id,
    required this.scheduleId,
    required this.paidAmount,
    required this.paidDate,
    required this.paymentMethod,
    this.transactionReference,
    this.note,
    this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['payment_id'] as int,
      scheduleId: json['schedule_id'] as int,
      paidAmount: (json['paid_amount'] as num).toDouble(),
      paidDate: DateTime.parse(json['paid_date'] as String),
      paymentMethod: json['payment_method'] as String,
      transactionReference: json['transaction_reference'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'payment_id': id,
    'schedule_id': scheduleId,
    'paid_amount': paidAmount,
    'paid_date': paidDate.toIso8601String(),
    'payment_method': paymentMethod,
    'transaction_reference': transactionReference,
    'note': note,
    'created_at': createdAt?.toIso8601String(),
  };
}
