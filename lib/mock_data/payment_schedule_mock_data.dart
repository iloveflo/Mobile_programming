import '../models/payment_schedule_model.dart';

class PaymentScheduleMockData {
  static final List<PaymentScheduleModel> paymentSchedulesDatabase = [
    PaymentScheduleModel(
      id: 1,
      loanId: 1,
      installmentNumber: 1,
      dueDate: DateTime(2026, 2, 10),
      principalAmount: 2083333.33,
      interestAmount: 625000.0,
      feeAmount: 0.0,
      totalAmount: 2708333.33,
      remainingBalance: 47916666.67,
      status: 'PAID',
      createdAt: DateTime(2026, 1, 10, 10, 10),
    ),
    PaymentScheduleModel(
      id: 2,
      loanId: 1,
      installmentNumber: 2,
      dueDate: DateTime(2026, 3, 10),
      principalAmount: 2083333.33,
      interestAmount: 598958.33,
      feeAmount: 0.0,
      totalAmount: 2682291.66,
      remainingBalance: 45833333.34,
      status: 'PAID',
      createdAt: DateTime(2026, 1, 10, 10, 10),
    ),
  ];
}
