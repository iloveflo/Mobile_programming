import 'dart:async';
import 'dart:io';

import '../../core/network/api_client.dart';
import '../../models/debt_strategy_model.dart';
import '../interfaces/debt_strategy_repository.dart';

/// Triển khai Remote của DebtStrategyRepository giao tiếp với Backend qua RESTful API
class ApiDebtStrategyRepository implements DebtStrategyRepository {
  final ApiClient client;

  ApiDebtStrategyRepository({required this.client});

  Future<T> _handleApiCall<T>(Future<dynamic> Function() request) async {
    try {
      final response = await request();
      return response as T;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }
      if (e.statusCode == 404) {
        throw Exception('Không tìm thấy thông tin kế hoạch tối ưu nợ.');
      }
      if (e.statusCode >= 500) {
        throw Exception(
          'Máy chủ xử lý tối ưu nợ đang bận. Vui lòng thử lại sau.',
        );
      }
      throw Exception(e.message);
    } on SocketException catch (_) {
      throw Exception('Lỗi kết nối mạng. Vui lòng kiểm tra Wifi/4G của bạn.');
    } on TimeoutException catch (_) {
      throw Exception(
        'Yêu cầu tính toán quá thời gian chờ (Timeout). Vui lòng thử lại.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<List<DebtStrategyModel>> getStrategies({int? userId}) async {
    return _handleApiCall<List<DebtStrategyModel>>(() async {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['userId'] = userId.toString();

      final res = await client.get(
        '/debt-strategies',
        queryParams: queryParams,
      );
      if (res is List) {
        return res
            .map(
              (item) =>
                  DebtStrategyModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    });
  }

  @override
  Future<DebtStrategyModel?> getActiveStrategy({int? userId}) async {
    return _handleApiCall<DebtStrategyModel?>(() async {
      try {
        final queryParams = <String, String>{};
        if (userId != null) queryParams['userId'] = userId.toString();

        final res = await client.get(
          '/debt-strategies/active',
          queryParams: queryParams,
        );
        if (res is Map<String, dynamic>) {
          return DebtStrategyModel.fromJson(res);
        }
      } on Exception {
        return null;
      }
      return null;
    });
  }

  @override
  Future<DebtStrategyModel> applyStrategy({
    required int userId,
    required String strategyType,
    required double extraPayment,
    double? estimatedInterestSaved,
    int? estimatedMonthsSaved,
  }) async {
    return _handleApiCall<DebtStrategyModel>(() async {
      final payload = <String, dynamic>{
        'user_id': userId,
        'strategy_type': strategyType,
        'extra_payment': extraPayment,
      };
      if (estimatedInterestSaved != null) {
        payload['estimated_interest_saved'] = estimatedInterestSaved;
      }
      if (estimatedMonthsSaved != null) {
        payload['estimated_months_saved'] = estimatedMonthsSaved;
      }

      final res = await client.post('/debt-strategies/apply', body: payload);
      return DebtStrategyModel.fromJson(res as Map<String, dynamic>);
    });
  }

  @override
  Future<void> cancelStrategy(int strategyId) async {
    return _handleApiCall<void>(() async {
      await client.patch('/debt-strategies/$strategyId/cancel');
    });
  }
}
