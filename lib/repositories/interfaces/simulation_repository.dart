import '../../models/simulation_model.dart';

/// Hợp đồng giao diện cho Kho lưu trữ Kịch bản Mô phỏng Trả nợ (SimulationRepository)
abstract class SimulationRepository {
  /// Lấy danh sách các kịch bản mô phỏng đã lưu để tham khảo
  Future<List<SimulationModel>> getSimulations({int? userId, int? loanId});

  /// Lưu lại kịch bản mô phỏng tham khảo (Mục 12: SIMULATION_REFERENCE)
  Future<SimulationModel> saveSimulation(SimulationModel simulation);

  /// Xóa bản ghi kịch bản mô phỏng tham khảo
  Future<void> deleteSimulation(int simulationId);
}
