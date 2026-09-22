import '../models/credit_report_model.dart';

class CreditReportMockData {
  static final List<CreditReportModel> creditReportsDatabase = [
    CreditReportModel(
      id: 1,
      userId: 1,
      creditScore: 735,
      dtiRatio: 0.2850,
      ltvRatio: 0.0,
      creditUtilization: 0.32,
      onTimePaymentRate: 1.0,
      totalDebt: 43750000.0,
      overdueAmount: 0.0,
      riskLevel: 'LOW',
      reportPeriod: '2026-08',
      generatedAt: DateTime(2026, 9, 1, 8),
    ),
  ];
}
