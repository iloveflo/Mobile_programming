import '../models/loan_model.dart';

class LoanMockData {
  static final List<LoanModel> loansDatabase = [
    LoanModel(
      id: 1,
      userId: 1,
      loanTypeId: 1,
      name: 'Vay tiêu dùng cá nhân',
      principalAmount: 50000000.0,
      interestRate: 0.15,
      interestMethod: 'REDUCING_BALANCE',
      termMonths: 24,
      startDate: DateTime(2026, 1, 10),
      endDate: DateTime(2027, 12, 10),
      outstandingAmount: 43750000.0,
      earlyPaymentFeeRate: 0.02,
      status: 'ACTIVE',
      createdAt: DateTime(2026, 1, 10, 9),
      updatedAt: DateTime(2026, 9, 1, 9),
    ),
  ];
}
