import '../../mock_data/debt_strategy_mock_data.dart';
import '../../models/debt_strategy_model.dart';
import '../interfaces/debt_strategy_repository.dart';

/// Triển khai Mock của DebtStrategyRepository lưu trữ và xử lý trực tiếp In-Memory
class MockDebtStrategyRepository implements DebtStrategyRepository {
  /// Cờ giả lập lỗi Database phục vụ kiểm thử ngoại lệ EX-05
  bool shouldSimulateDatabaseError = false;

  @override
  Future<List<DebtStrategyModel>> getStrategies({int? userId}) async {
    final list = DebtStrategyMockData.debtStrategiesDatabase;
    if (userId != null) {
      return list.where((s) => s.userId == userId).toList();
    }
    return List.from(list);
  }

  @override
  Future<DebtStrategyModel?> getActiveStrategy({int? userId}) async {
    final list = await getStrategies(userId: userId);
    for (final s in list.reversed) {
      if (s.isActive) return s;
    }
    return null;
  }

  @override
  Future<DebtStrategyModel> applyStrategy({
    required int userId,
    required String strategyType,
    required double extraPayment,
    double? estimatedInterestSaved,
    int? estimatedMonthsSaved,
  }) async {
    if (shouldSimulateDatabaseError) {
      throw Exception(
        'Lỗi hệ cơ sở dữ liệu: Không thể ghi nhận bản ghi kế hoạch tối ưu.',
      );
    }

    // Đóng toàn bộ kế hoạch cũ đang ACTIVE theo đúng nguyên tắc mục 13
    for (
      int i = 0;
      i < DebtStrategyMockData.debtStrategiesDatabase.length;
      i++
    ) {
      final s = DebtStrategyMockData.debtStrategiesDatabase[i];
      if (s.userId == userId && s.isActive) {
        DebtStrategyMockData.debtStrategiesDatabase[i] = s.copyWith(
          status: 'INACTIVE',
        );
      }
    }

    final newId = DebtStrategyMockData.debtStrategiesDatabase.isEmpty
        ? 1
        : DebtStrategyMockData.debtStrategiesDatabase
                  .map((e) => e.id)
                  .reduce((a, b) => a > b ? a : b) +
              1;

    final newStrategy = DebtStrategyModel(
      id: newId,
      userId: userId,
      strategyType: strategyType,
      extraPayment: extraPayment,
      estimatedInterestSaved: estimatedInterestSaved,
      estimatedMonthsSaved: estimatedMonthsSaved,
      status: 'ACTIVE',
      createdAt: DateTime.now(),
    );

    DebtStrategyMockData.debtStrategiesDatabase.add(newStrategy);
    return newStrategy;
  }

  @override
  Future<void> cancelStrategy(int strategyId) async {
    for (
      int i = 0;
      i < DebtStrategyMockData.debtStrategiesDatabase.length;
      i++
    ) {
      final s = DebtStrategyMockData.debtStrategiesDatabase[i];
      if (s.id == strategyId) {
        DebtStrategyMockData.debtStrategiesDatabase[i] = s.copyWith(
          status: 'CANCELLED',
        );
        break;
      }
    }
  }
}
