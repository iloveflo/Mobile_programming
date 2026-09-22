import '../models/payment_model.dart';

class PaymentMockData {
  static final List<PaymentModel> paymentsDatabase = [
    PaymentModel(
      id: 1,
      scheduleId: 1,
      paidAmount: 2708333.33,
      paidDate: DateTime(2026, 2, 8, 14, 30),
      paymentMethod: 'BANK_TRANSFER',
      transactionReference: 'MOCK-TXN-0001',
      note: 'Thanh toán kỳ đầu tiên.',
      createdAt: DateTime(2026, 2, 8, 14, 30),
    ),
    PaymentModel(
      id: 2,
      scheduleId: 2,
      paidAmount: 2682291.66,
      paidDate: DateTime(2026, 3, 8, 14, 25),
      paymentMethod: 'BANK_TRANSFER',
      transactionReference: 'MOCK-TXN-0002',
      createdAt: DateTime(2026, 3, 8, 14, 25),
    ),
  ];
}
