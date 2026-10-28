import '../models/credit_report_model.dart';

/// Cơ sở dữ liệu mẫu cho Báo cáo tín dụng (Credit Reports Database)
/// Lưu trữ các ảnh chụp (snapshots) định kỳ theo tháng/quý của người dùng.
class CreditReportMockData {
  static final List<CreditReportModel> creditReportsDatabase = [
    CreditReportModel(
      id: 3,
      userId: 1,
      creditScore: 745,
      dtiRatio: 0.2850,
      ltvRatio: 0.0,
      creditUtilization: 0.32,
      onTimePaymentRate: 1.0,
      totalDebt: 43750000.0,
      overdueAmount: 0.0,
      riskLevel: 'LOW',
      reportPeriod: '2026-08',
      generatedAt: DateTime(2026, 9, 1, 8, 0),
    ),
    CreditReportModel(
      id: 2,
      userId: 1,
      creditScore: 730,
      dtiRatio: 0.3120,
      ltvRatio: 0.0,
      creditUtilization: 0.38,
      onTimePaymentRate: 1.0,
      totalDebt: 50000000.0,
      overdueAmount: 0.0,
      riskLevel: 'LOW',
      reportPeriod: '2026-07',
      generatedAt: DateTime(2026, 8, 1, 8, 0),
    ),
    CreditReportModel(
      id: 1,
      userId: 1,
      creditScore: 710,
      dtiRatio: 0.3550,
      ltvRatio: 0.0,
      creditUtilization: 0.45,
      onTimePaymentRate: 0.95,
      totalDebt: 58000000.0,
      overdueAmount: 0.0,
      riskLevel: 'MEDIUM',
      reportPeriod: '2026-06',
      generatedAt: DateTime(2026, 7, 1, 8, 0),
    ),
  ];
}
