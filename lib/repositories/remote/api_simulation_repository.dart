import 'dart:async';
import 'dart:io';

import '../../core/network/api_client.dart';
import '../../models/simulation_model.dart';
import '../interfaces/simulation_repository.dart';

/// Triển khai Remote của SimulationRepository giao tiếp với Backend qua RESTful API
class ApiSimulationRepository implements SimulationRepository {
  final ApiClient client;

  ApiSimulationRepository({required this.client});

  Future<T> _handleApiCall<T>(Future<dynamic> Function() request) async {
    try {
      final response = await request();
      return response as T;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }
      if (e.statusCode == 404) {
        throw Exception('Không tìm thấy dữ liệu kịch bản mô phỏng.');
      }
      if (e.statusCode >= 500) {
        throw Exception(
          'Máy chủ tính toán mô phỏng đang bận. Vui lòng thử lại sau.',
        );
      }
      throw Exception(e.message);
    } on SocketException catch (_) {
      throw Exception('Lỗi kết nối mạng. Vui lòng kiểm tra Wifi/4G của bạn.');
    } on TimeoutException catch (_) {
      throw Exception('Yêu cầu mô phỏng quá thời gian chờ. Vui lòng thử lại.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<List<SimulationModel>> getSimulations({
    int? userId,
    int? loanId,
  }) async {
    return _handleApiCall<List<SimulationModel>>(() async {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['userId'] = userId.toString();
      if (loanId != null) queryParams['loanId'] = loanId.toString();

      final res = await client.get('/simulations', queryParams: queryParams);
      if (res is List) {
        return res
            .map(
              (item) => SimulationModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    });
  }

  @override
  Future<SimulationModel> saveSimulation(SimulationModel simulation) async {
    return _handleApiCall<SimulationModel>(() async {
      final res = await client.post('/simulations', body: simulation.toJson());
      return SimulationModel.fromJson(res as Map<String, dynamic>);
    });
  }

  @override
  Future<void> deleteSimulation(int simulationId) async {
    return _handleApiCall<void>(() async {
      await client.delete('/simulations/$simulationId');
    });
  }
}
