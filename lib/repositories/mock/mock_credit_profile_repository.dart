import '../../mock_data/credit_profile_mock_data.dart';
import '../../models/credit_profile_model.dart';
import '../interfaces/credit_profile_repository.dart';

/// Triển khai Mock của CreditProfileRepository lưu trữ và xử lý trực tiếp In-Memory
class MockCreditProfileRepository implements CreditProfileRepository {
  /// Cờ giả lập lỗi ngoại lệ EX-04 (Sự cố Database hoặc tính toán Backend)
  bool shouldSimulateDatabaseError = false;

  /// Cờ giả lập lỗi ngoại lệ EX-03 (Từ chối phân quyền truy cập hồ sơ)
  bool shouldSimulateUnauthorized = false;

  /// Cờ giả lập ngoại lệ EX-02 (Thiếu dữ liệu phục vụ chỉ số)
  bool shouldSimulateMissingData = false;

  @override
  Future<CreditProfileModel?> getCreditProfile({int? userId}) async {
    if (shouldSimulateUnauthorized) {
      throw Exception('Dữ liệu không thuộc quyền truy cập của người dùng.');
    }
    if (shouldSimulateDatabaseError) {
      throw Exception(
        'Lỗi tính toán hoặc sự cố kết nối Database khi truy xuất CreditProfile.',
      );
    }

    final targetId = userId ?? 1;
    final match = CreditProfileMockData.creditProfilesDatabase
        .cast<CreditProfileModel?>()
        .firstWhere((p) => p?.userId == targetId, orElse: () => null);

    if (match != null && shouldSimulateMissingData) {
      return match.copyWith(
        clearDti: true,
        clearLtv: true,
        clearUtilization: true,
      );
    }

    return match;
  }

  @override
  Future<CreditProfileModel> recalculateCreditProfile({int? userId}) async {
    if (shouldSimulateUnauthorized) {
      throw Exception('Dữ liệu không thuộc quyền truy cập của người dùng.');
    }
    if (shouldSimulateDatabaseError) {
      throw Exception(
        'Lỗi tính toán hoặc sự cố Database khi cập nhật CreditProfile.',
      );
    }

    final targetId = userId ?? 1;
    final index = CreditProfileMockData.creditProfilesDatabase.indexWhere(
      (p) => p.userId == targetId,
    );

    if (shouldSimulateMissingData) {
      final updated = CreditProfileModel(
        id: index >= 0
            ? CreditProfileMockData.creditProfilesDatabase[index].id
            : 1,
        userId: targetId,
        creditScore: 720,
        dtiRatio: null,
        ltvRatio: null,
        creditUtilization: null,
        onTimePaymentRate: 0.95,
        activeLoanCount: 1,
        riskLevel: 'LOW',
        updatedAt: DateTime.now(),
      );
      if (index >= 0) {
        CreditProfileMockData.creditProfilesDatabase[index] = updated;
      } else {
        CreditProfileMockData.creditProfilesDatabase.add(updated);
      }
      return updated;
    }

    final now = DateTime.now();
    if (index >= 0) {
      final old = CreditProfileMockData.creditProfilesDatabase[index];
      final updated = old.copyWith(
        creditScore: old.creditScore ?? 745,
        updatedAt: now,
      );
      CreditProfileMockData.creditProfilesDatabase[index] = updated;
      return updated;
    } else {
      final newProfile = CreditProfileModel(
        id: CreditProfileMockData.creditProfilesDatabase.isEmpty
            ? 1
            : CreditProfileMockData.creditProfilesDatabase
                      .map((e) => e.id)
                      .reduce((a, b) => a > b ? a : b) +
                  1,
        userId: targetId,
        creditScore: 740,
        dtiRatio: 0.285,
        ltvRatio: 0.65,
        creditUtilization: 0.30,
        onTimePaymentRate: 1.0,
        activeLoanCount: 1,
        riskLevel: 'LOW',
        updatedAt: now,
      );
      CreditProfileMockData.creditProfilesDatabase.add(newProfile);
      return newProfile;
    }
  }
}
