import 'dart:async';
import 'dart:io';

import '../../core/network/api_client.dart';
import '../../models/notification_model.dart';
import '../../models/notification_preference_model.dart';
import '../../models/payment_schedule_model.dart';
import '../interfaces/payment_schedule_repository.dart';

/// Triển khai Remote của PaymentScheduleRepository kết nối tới Backend qua RESTful API
class ApiPaymentScheduleRepository implements PaymentScheduleRepository {
  final ApiClient client;

  ApiPaymentScheduleRepository({required this.client});

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
          'Bạn không có quyền truy cập thông tin lịch thanh toán của tài khoản khác.',
        );
      }
      if (e.statusCode == 404) {
        throw Exception('Không tìm thấy bản ghi kỳ thanh toán trong hệ thống.');
      }
      if (e.statusCode == 400 || e.statusCode == 422) {
        throw Exception(e.message);
      }
      if (e.statusCode >= 500) {
        throw Exception(
          'Sự cố kết nối hệ thống khi xử lý lịch thanh toán. Vui lòng thử lại sau.',
        );
      }
      throw Exception(e.message);
    } on SocketException catch (_) {
      throw Exception('Lỗi kết nối mạng. Vui lòng kiểm tra kết nối Internet.');
    } on TimeoutException catch (_) {
      throw Exception(
        'Yêu cầu xử lý quá thời gian chờ (Timeout). Vui lòng thử lại.',
      );
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<List<PaymentScheduleModel>> getPaymentSchedules({
    int? userId,
    int? loanId,
  }) async {
    return await _handleApiCall<List<PaymentScheduleModel>>(() async {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['user_id'] = userId.toString();
      if (loanId != null) queryParams['loan_id'] = loanId.toString();

      final res = await client.get(
        '/payment-schedules',
        queryParams: queryParams,
      );
      if (res == null) return <PaymentScheduleModel>[];

      if (res is List) {
        return res
            .map(
              (item) =>
                  PaymentScheduleModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (res is Map<String, dynamic> && res['schedules'] is List) {
        return (res['schedules'] as List)
            .map(
              (item) =>
                  PaymentScheduleModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return <PaymentScheduleModel>[];
    });
  }

  @override
  Future<PaymentScheduleModel?> getScheduleDetail(
    int scheduleId, {
    int? userId,
  }) async {
    return await _handleApiCall<PaymentScheduleModel?>(() async {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['user_id'] = userId.toString();

      final res = await client.get(
        '/payment-schedules/$scheduleId',
        queryParams: queryParams,
      );
      if (res == null) return null;

      if (res is Map<String, dynamic>) {
        final data = res['data'] is Map<String, dynamic>
            ? res['data'] as Map<String, dynamic>
            : res;
        return PaymentScheduleModel.fromJson(data);
      }
      return null;
    });
  }

  @override
  Future<PaymentScheduleModel> markScheduleAsPaid(
    int scheduleId, {
    int? userId,
  }) async {
    return await _handleApiCall<PaymentScheduleModel>(() async {
      final body = <String, dynamic>{};
      if (userId != null) body['user_id'] = userId;

      final res = await client.post(
        '/payment-schedules/$scheduleId/pay',
        body: body,
      );
      if (res is Map<String, dynamic>) {
        final data = res['data'] is Map<String, dynamic>
            ? res['data'] as Map<String, dynamic>
            : res;
        return PaymentScheduleModel.fromJson(data);
      }
      throw Exception('Phản hồi dữ liệu thanh toán không hợp lệ.');
    });
  }

  @override
  Future<NotificationPreferenceModel> getNotificationPreference({
    int? userId,
  }) async {
    return await _handleApiCall<NotificationPreferenceModel>(() async {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['user_id'] = userId.toString();

      final res = await client.get(
        '/notifications/preference',
        queryParams: queryParams,
      );
      if (res is Map<String, dynamic>) {
        final data = res['data'] is Map<String, dynamic>
            ? res['data'] as Map<String, dynamic>
            : res;
        return NotificationPreferenceModel.fromJson(data);
      }
      // Trả cấu hình mặc định nếu chưa khởi tạo
      return NotificationPreferenceModel(
        id: 1,
        userId: userId ?? 1,
        pushEnabled: true,
        emailEnabled: true,
        smsEnabled: false,
        reminderDays: 3,
        updatedAt: DateTime.now(),
      );
    });
  }

  @override
  Future<NotificationPreferenceModel> updateNotificationPreference(
    NotificationPreferenceModel preference, {
    String? userEmail,
    String? userPhone,
  }) async {
    return await _handleApiCall<NotificationPreferenceModel>(() async {
      // EX-04: Client validation trước khi gửi
      if (preference.emailEnabled &&
          (userEmail == null || userEmail.trim().isEmpty)) {
        throw Exception(
          'Kênh Email đang bật nhưng hồ sơ của bạn chưa có địa chỉ email. Vui lòng cập nhật email trong hồ sơ cá nhân.',
        );
      }
      if (preference.smsEnabled &&
          (userPhone == null || userPhone.trim().isEmpty)) {
        throw Exception(
          'Kênh SMS đang bật nhưng hồ sơ của bạn chưa có số điện thoại. Vui lòng cập nhật số điện thoại trong hồ sơ cá nhân.',
        );
      }

      final res = await client.put(
        '/notifications/preference',
        body: preference.toJson(),
      );
      if (res is Map<String, dynamic>) {
        final data = res['data'] is Map<String, dynamic>
            ? res['data'] as Map<String, dynamic>
            : res;
        return NotificationPreferenceModel.fromJson(data);
      }
      return preference;
    });
  }

  @override
  Future<List<NotificationModel>> getNotifications({int? userId}) async {
    return await _handleApiCall<List<NotificationModel>>(() async {
      final queryParams = <String, String>{};
      if (userId != null) queryParams['user_id'] = userId.toString();

      final res = await client.get('/notifications', queryParams: queryParams);
      if (res == null) return <NotificationModel>[];

      if (res is List) {
        return res
            .map(
              (item) =>
                  NotificationModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (res is Map<String, dynamic> && res['notifications'] is List) {
        return (res['notifications'] as List)
            .map(
              (item) =>
                  NotificationModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }
      return <NotificationModel>[];
    });
  }

  @override
  Future<int> syncSchedulesAndNotifications({int? userId}) async {
    return await _handleApiCall<int>(() async {
      final body = <String, dynamic>{};
      if (userId != null) body['user_id'] = userId;

      final res = await client.post('/payment-schedules/sync', body: body);
      if (res is Map<String, dynamic> && res['cancelled_count'] is int) {
        return res['cancelled_count'] as int;
      }
      return 0;
    });
  }
}
