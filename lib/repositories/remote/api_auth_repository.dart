import 'dart:async';
import 'dart:io';

import '../../core/network/api_client.dart';
import '../../models/auth_token_model.dart';
import '../../models/bank_account_model.dart';
import '../../models/session_model.dart';
import '../../models/user_model.dart';
import '../interfaces/auth_repository.dart';

/// Triển khai thực tế của AuthRepository gọi tới Backend API thông qua ApiClient
class ApiAuthRepository implements AuthRepository {
  final ApiClient client;

  ApiAuthRepository({required this.client});

  /// Phương thức bọc cuộc gọi API để chuẩn hóa và chuyển đổi mã lỗi HTTP sang Custom Exceptions
  Future<T> _handleApiCall<T>(Future<dynamic> Function() request) async {
    try {
      final response = await request();
      return response as T;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw const InvalidCredentialsException(
          'Thông tin đăng nhập không hợp lệ hoặc phiên đã hết hạn.',
        );
      }
      if (e.statusCode == 403) {
        final msg = e.message.toLowerCase();
        if (msg.contains('unverified') || msg.contains('chưa kích hoạt')) {
          throw const AccountUnverifiedException(
            'user@fincredit.vn',
            message: 'Tài khoản chưa được kích hoạt qua OTP.',
          );
        }
        throw const AccountLockedException(
          'Tài khoản bị tạm khóa do vi phạm chính sách bảo mật.',
        );
      }
      if (e.statusCode == 429) {
        throw const OtpException(
          'Vượt quá giới hạn số lần yêu cầu hoặc nhập sai quá số lần quy định. Vui lòng chờ.',
          isExpired: false,
          remainingAttempts: 0,
        );
      }
      if (e.statusCode == 400 || e.statusCode == 422) {
        throw InvalidCredentialsException(e.message);
      }
      throw NetworkAuthException(e.message);
    } on SocketException catch (_) {
      throw const NetworkAuthException(
        'Mất kết nối mạng. Vui lòng kiểm tra Wifi/4G.',
      );
    } on TimeoutException catch (_) {
      throw const NetworkAuthException(
        'Yêu cầu đã quá thời gian phản hồi (Timeout). Vui lòng thử lại.',
      );
    } catch (e) {
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('401')) {
        throw const InvalidCredentialsException(
          'Thông tin đăng nhập không hợp lệ hoặc phiên đã hết hạn.',
        );
      }
      if (errorString.contains('403')) {
        if (errorString.contains('unverified') ||
            errorString.contains('chưa kích hoạt')) {
          throw const AccountUnverifiedException(
            'user@fincredit.vn',
            message: 'Tài khoản chưa được kích hoạt qua OTP.',
          );
        }
        throw const AccountLockedException(
          'Tài khoản bị tạm khóa do vi phạm chính sách bảo mật.',
        );
      }
      if (errorString.contains('429')) {
        throw const OtpException(
          'Vượt quá giới hạn số lần yêu cầu hoặc nhập sai quá số lần quy định. Vui lòng chờ.',
          isExpired: false,
          remainingAttempts: 0,
        );
      }
      if (errorString.contains('400') || errorString.contains('422')) {
        throw InvalidCredentialsException(
          e
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('UnimplementedError: ', ''),
        );
      }
      if (errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('socket')) {
        throw NetworkAuthException(e.toString());
      }

      rethrow;
    }
  }

  @override
  Future<AuthTokenModel?> checkSession() async {
    try {
      final response = await _handleApiCall<dynamic>(
        () => client.get('/api/auth/session'),
      );
      if (response == null) return null;
      final data = response is Map<String, dynamic>
          ? (response['data'] ?? response)
          : response;
      final session = AuthTokenModel.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
      if (session.accessToken.isNotEmpty) {
        client.setAuthToken(session.accessToken);
      }
      return session;
    } catch (e) {
      if (e is InvalidCredentialsException || e is NetworkAuthException) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<UserModel> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _handleApiCall<dynamic>(
      () => client.post(
        '/api/auth/login',
        body: {'identifier': identifier.trim(), 'password': password},
      ),
    );

    final raw = response is Map<String, dynamic>
        ? response
        : <String, dynamic>{};
    final data = raw['data'] is Map<String, dynamic>
        ? raw['data'] as Map<String, dynamic>
        : raw;

    // Trích xuất Token xác thực và lưu vào ApiClient
    final token =
        data['token'] ??
        data['accessToken'] ??
        data['access_token'] ??
        raw['token'] ??
        raw['accessToken'];
    if (token != null && token.toString().isNotEmpty) {
      client.setAuthToken(token.toString());
    }

    final userMap = data['user'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['user'] as Map)
        : Map<String, dynamic>.from(data);

    if (token != null && userMap['token'] == null) {
      userMap['token'] = token.toString();
    }

    return UserModel.fromJson(userMap);
  }

  @override
  Future<void> register(Map<String, dynamic> registerData) async {
    await _handleApiCall<dynamic>(
      () => client.post('/api/auth/register', body: registerData),
    );
  }

  @override
  Future<bool> verifyOtp({
    required String otp,
    required String flowType,
  }) async {
    final response = await _handleApiCall<dynamic>(
      () => client.post(
        '/api/auth/verify-otp',
        body: {'otp': otp, 'flow_type': flowType},
      ),
    );

    if (response is Map<String, dynamic>) {
      return (response['success'] ?? true) as bool;
    }
    return true;
  }

  @override
  Future<void> resendOtp() async {
    await _handleApiCall<dynamic>(() => client.post('/api/auth/resend-otp'));
  }

  @override
  Future<void> resetPassword({required String newPassword}) async {
    await _handleApiCall<dynamic>(
      () => client.post(
        '/api/auth/reset-password',
        body: {'new_password': newPassword},
      ),
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _handleApiCall<dynamic>(
      () => client.post(
        '/api/auth/change-password',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      ),
    );
  }

  @override
  Future<List<SessionModel>> getActiveSessions() async {
    final response = await _handleApiCall<dynamic>(
      () => client.get('/api/auth/sessions'),
    );

    final List<dynamic> list = response is List
        ? response
        : (response is Map<String, dynamic>
              ? (response['data'] as List? ?? [])
              : []);

    return list
        .map(
          (item) =>
              SessionModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    await _handleApiCall<dynamic>(
      () => client.delete('/api/auth/sessions/$sessionId'),
    );
  }

  @override
  Future<UserModel> getProfile() async {
    final response = await _handleApiCall<dynamic>(
      () => client.get('/api/user/profile'),
    );
    final raw = response is Map<String, dynamic>
        ? response
        : <String, dynamic>{};
    final data = raw['data'] is Map<String, dynamic>
        ? raw['data'] as Map<String, dynamic>
        : raw;
    return UserModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _handleApiCall<dynamic>(
      () => client.put('/api/user/profile', body: profileData),
    );
    final raw = response is Map<String, dynamic>
        ? response
        : <String, dynamic>{};
    final data = raw['data'] is Map<String, dynamic>
        ? raw['data'] as Map<String, dynamic>
        : raw;
    return UserModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<List<BankAccountModel>> getBankAccounts() async {
    final response = await _handleApiCall<dynamic>(
      () => client.get('/api/user/bank-accounts'),
    );
    final list = response is List
        ? response
        : (response is Map<String, dynamic>
              ? (response['data'] as List? ?? [])
              : []);
    return list
        .map(
          (item) =>
              BankAccountModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<BankAccountModel> addBankAccount(
    Map<String, dynamic> accountData,
  ) async {
    final response = await _handleApiCall<dynamic>(
      () => client.post('/api/user/bank-accounts', body: accountData),
    );
    final raw = response is Map<String, dynamic>
        ? response
        : <String, dynamic>{};
    final data = raw['data'] is Map<String, dynamic>
        ? raw['data'] as Map<String, dynamic>
        : raw;
    return BankAccountModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  @override
  Future<void> deleteBankAccount(String accountId) async {
    await _handleApiCall<dynamic>(
      () => client.delete('/api/user/bank-accounts/$accountId'),
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _handleApiCall<dynamic>(() => client.post('/api/auth/logout'));
    } finally {
      client.clearAuthToken();
    }
  }
}
