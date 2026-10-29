import 'dart:async';
import 'dart:io';

import '../../core/network/api_client.dart';
import '../../models/credit_report_model.dart';
import '../interfaces/credit_report_repository.dart';

/// Triển khai Remote của CreditReportRepository kết nối tới Backend qua RESTful API
class ApiCreditReportRepository implements CreditReportRepository {
  final ApiClient client;

  ApiCreditReportRepository({required this.client});

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
          'Bạn không có quyền truy cập báo cáo tín dụng của tài khoản khác.',
        );
      }
      if (e.statusCode == 404) {
        throw Exception(
          'Không tìm thấy bản ghi báo cáo tín dụng trong hệ thống.',
        );
      }
      if (e.statusCode == 409) {
        throw Exception(
          'Kỳ báo cáo này đã được khởi tạo trước đó. Mỗi kỳ báo cáo chỉ lập một bản ghi ảnh chụp duy nhất.',
        );
      }
      if (e.statusCode == 400 || e.statusCode == 422) {
        throw Exception(
          'Dữ liệu tài chính chưa đủ điều kiện để khởi tạo báo cáo kỳ này.',
        );
      }
      if (e.statusCode >= 500) {
        throw Exception(
          'Sự cố cơ sở dữ liệu trên máy chủ khi xử lý báo cáo. Vui lòng thử lại sau.',
        );
      }
      throw Exception(e.message);
    } on SocketException catch (_) {
      throw Exception('Lỗi kết nối mạng. Vui lòng kiểm tra kết nối Internet.');
    } on TimeoutException catch (_) {
      throw Exception(
        'Yêu cầu xử lý báo cáo quá thời gian chờ. Vui lòng thử lại.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<List<CreditReportModel>> getCreditReports({int? userId}) async {
    return await _handleApiCall<List<CreditReportModel>>(() async {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['user_id'] = userId.toString();

      final res = await client.get('/credit-reports', queryParams: queryParams);
      if (res == null) return <CreditReportModel>[];

      if (res is List) {
        return res
            .map(
              (item) =>
                  CreditReportModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (res is Map<String, dynamic> && res['reports'] is List) {
        return (res['reports'] as List)
            .map(
              (item) =>
                  CreditReportModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return <CreditReportModel>[];
    });
  }

  @override
  Future<CreditReportModel?> getCreditReportDetail(
    int reportId, {
    int? userId,
  }) async {
    return await _handleApiCall<CreditReportModel?>(() async {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['user_id'] = userId.toString();

      final res = await client.get(
        '/credit-reports/$reportId',
        queryParams: queryParams,
      );
      if (res == null) return null;

      if (res is Map<String, dynamic>) {
        final data = res['data'] is Map<String, dynamic>
            ? res['data'] as Map<String, dynamic>
            : res;
        return CreditReportModel.fromJson(data);
      }
      return null;
    });
  }

  @override
  Future<CreditReportModel> generateReport({
    int? userId,
    required String reportPeriod,
  }) async {
    return await _handleApiCall<CreditReportModel>(() async {
      final body = <String, dynamic>{'report_period': reportPeriod};
      if (userId != null) body['user_id'] = userId;

      final res = await client.post('/credit-reports/generate', body: body);
      if (res is Map<String, dynamic>) {
        final data = res['data'] is Map<String, dynamic>
            ? res['data'] as Map<String, dynamic>
            : res;
        return CreditReportModel.fromJson(data);
      }
      throw Exception('Phản hồi dữ liệu báo cáo không đúng định dạng.');
    });
  }
}
