import '../../mock_data/simulation_mock_data.dart';
import '../../models/simulation_model.dart';
import '../interfaces/simulation_repository.dart';

/// Triển khai Mock của SimulationRepository xử lý In-Memory
class MockSimulationRepository implements SimulationRepository {
  /// Cờ giả lập lỗi cơ sở dữ liệu phục vụ kiểm thử ngoại lệ EX-05
  bool shouldSimulateDatabaseError = false;

  @override
  Future<List<SimulationModel>> getSimulations({
    int? userId,
    int? loanId,
  }) async {
    final list = SimulationMockData.simulationsDatabase;
    return list.where((s) {
      if (userId != null && s.userId != userId) return false;
      if (loanId != null && s.loanId != loanId) return false;
      return true;
    }).toList();
  }

  @override
  Future<SimulationModel> saveSimulation(SimulationModel simulation) async {
    if (shouldSimulateDatabaseError) {
      throw Exception(
        'Lỗi lưu trữ cơ sở dữ liệu: Không thể ghi bản ghi mô phỏng.',
      );
    }

    final newId = SimulationMockData.simulationsDatabase.isEmpty
        ? 1
        : SimulationMockData.simulationsDatabase
                  .map((e) => e.id)
                  .reduce((a, b) => a > b ? a : b) +
              1;

    final record = simulation.copyWith(
      id: newId,
      status: 'SIMULATION_REFERENCE',
      createdAt: DateTime.now(),
    );

    SimulationMockData.simulationsDatabase.add(record);
    return record;
  }

  @override
  Future<void> deleteSimulation(int simulationId) async {
    SimulationMockData.simulationsDatabase.removeWhere(
      (s) => s.id == simulationId,
    );
  }
}
