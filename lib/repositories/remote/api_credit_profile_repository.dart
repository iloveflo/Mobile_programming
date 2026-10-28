import 'dart:async';
import 'dart:io';

import '../../core/network/api_client.dart';
import '../../models/credit_profile_model.dart';
import '../interfaces/credit_profile_repository.dart';

/// Triển khai Remote của CreditProfileRepository kết nối tới Backend Node.js qua RESTful API
class ApiCreditProfileRepository implements CreditProfileRepository {
  final ApiClient client;

  ApiCreditProfileRepository({required this.client});

  Future<T> _handleApiCall<T>(Future<dynamic> Function() request) async {
    try {
      final response = await request();
      return response as T;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw Exception('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
      }
      if (e.statusCode == 403) {
        throw Exception(
          'Bạn không có quyền truy cập hồ sơ tín dụng của tài khoản khác.',
        );
      }
      if (e.statusCode == 404) {
        // Trả về null cho caller xử lý EX-01
        rethrow;
      }
      if (e.statusCode >= 500) {
        throw Exception(
          'Lỗi tính toán hoặc sự cố cơ sở dữ liệu trên máy chủ. Vui lòng thử lại.',
        );
      }
      throw Exception(e.message);
    } on SocketException catch (_) {
      throw Exception('Lỗi kết nối mạng. Vui lòng kiểm tra kết nối Internet.');
    } on TimeoutException catch (_) {
      throw Exception(
        'Yêu cầu xử lý hồ sơ quá thời gian chờ (Timeout). Vui lòng thử lại.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<CreditProfileModel?> getCreditProfile({int? userId}) async {
    try {
      return await _handleApiCall<CreditProfileModel?>(() async {
        final queryParams = <String, String>{};
        if (userId != null) queryParams['user_id'] = userId.toString();

        final res = await client.get(
          '/credit-profile',
          queryParams: queryParams,
        );
        if (res == null) return null;
        return CreditProfileModel.fromJson(res as Map<String, dynamic>);
      });
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<CreditProfileModel> recalculateCreditProfile({int? userId}) async {
    return _handleApiCall<CreditProfileModel>(() async {
      final payload = <String, dynamic>{};
      if (userId != null) payload['user_id'] = userId;

      final res = await client.post(
        '/credit-profile/recalculate',
        body: payload,
      );
      return CreditProfileModel.fromJson(res as Map<String, dynamic>);
    });
  }
}
