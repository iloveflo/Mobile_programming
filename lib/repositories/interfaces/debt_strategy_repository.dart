import '../../models/debt_strategy_model.dart';

/// Hợp đồng giao diện cho Kho lưu trữ Kế hoạch Tối ưu Trả nợ (DebtStrategyRepository)
abstract class DebtStrategyRepository {
  /// Lấy toàn bộ danh sách lịch sử chiến lược của người dùng
  Future<List<DebtStrategyModel>> getStrategies({int? userId});

  /// Lấy kế hoạch chiến lược đang ở trạng thái ACTIVE hiện thời
  Future<DebtStrategyModel?> getActiveStrategy({int? userId});

  /// Áp dụng hoặc kích hoạt mới một kế hoạch chiến lược tối ưu trả nợ
  Future<DebtStrategyModel> applyStrategy({
    required int userId,
    required String strategyType,
    required double extraPayment,
    double? estimatedInterestSaved,
    int? estimatedMonthsSaved,
  });

  /// Hủy kích hoạt hoặc đóng kế hoạch đang thực thi
  Future<void> cancelStrategy(int strategyId);
}
