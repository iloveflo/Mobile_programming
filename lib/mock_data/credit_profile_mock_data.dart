import '../models/credit_profile_model.dart';

class CreditProfileMockData {
  static final List<CreditProfileModel> creditProfilesDatabase = [
    CreditProfileModel(
      id: 1,
      userId: 1,
      creditScore: 735,
      dtiRatio: 0.2850,
      ltvRatio: 0.0,
      creditUtilization: 0.32,
      onTimePaymentRate: 1.0,
      activeLoanCount: 1,
      riskLevel: 'LOW',
      updatedAt: DateTime(2026, 9, 1, 8),
    ),
  ];
}
