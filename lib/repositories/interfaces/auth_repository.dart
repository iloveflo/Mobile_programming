import '../../models/auth_token_model.dart';
import '../../models/bank_account_model.dart';
import '../../models/session_model.dart';
import '../../models/user_model.dart';

// =========================================================================
// CÁC CUSTOM EXCEPTIONS ĐẶC THÙ NGHIỆP VỤ BẢO MẬT & XÁC THỰC FINCREDIT
// =========================================================================

/// Lỗi thông tin đăng nhập không hợp lệ (sai email hoặc mật khẩu)
class InvalidCredentialsException implements Exception {
  final String message;

  const InvalidCredentialsException([
    this.message = 'Thông tin đăng nhập không chính xác.',
  ]);

  @override
  String toString() => message;
}

/// Lỗi tài khoản bị khóa (do nhập sai quá 5 lần hoặc vi phạm chính sách bảo mật)
class AccountLockedException implements Exception {
  final String message;
  final DateTime? lockUntil;

  const AccountLockedException(this.message, {this.lockUntil});

  @override
  String toString() => message;
}

/// Lỗi tài khoản chưa qua bước xác thực mã kích hoạt OTP
class AccountUnverifiedException implements Exception {
  final String email;
  final String? phone;
  final String message;

  const AccountUnverifiedException(
    this.email, {
    this.phone,
    this.message = 'Tài khoản chưa được kích hoạt qua OTP.',
  });

  @override
  String toString() => message;
}

/// Lỗi liên quan đến mã xác thực OTP (mã không đúng, hết hạn hoặc quá số lần thử)
class OtpException implements Exception {
  final String message;
  final int? remainingAttempts;
  final bool isExpired;

  const OtpException(
    this.message, {
    this.remainingAttempts,
    this.isExpired = false,
  });

  @override
  String toString() => message;
}

/// Lỗi gián đoạn kết nối mạng, rớt mạng hoặc timeout khi gọi máy chủ xác thực
class NetworkAuthException implements Exception {
  final String message;

  const NetworkAuthException([
    this.message =
        'Không thể kết nối đến máy chủ bảo mật. Vui lòng kiểm tra mạng.',
  ]);

  @override
  String toString() => message;
}

// =========================================================================
// HỢP ĐỒNG GIAO DIỆN (ABSTRACT INTERFACE) CỦA AUTH REPOSITORY
// =========================================================================

abstract class AuthRepository {
  /// Kiểm tra tính hợp lệ của token và phiên làm việc hiện tại
  Future<AuthTokenModel?> checkSession();

  /// Đăng nhập tài khoản bằng Email/Mã CIC và mật khẩu
  Future<UserModel> login({
    required String identifier,
    required String password,
  });

  /// Tạo tài khoản mới, hệ thống chuyển sang trạng thái chờ xác thực OTP
  Future<void> register(Map<String, dynamic> registerData);

  /// Xác thực mã OTP (flowType: 'REGISTER' hoặc 'FORGOT_PASSWORD')
  Future<bool> verifyOtp({required String otp, required String flowType});

  /// Yêu cầu gửi lại mã OTP tới số điện thoại/email
  Future<void> resendOtp();

  /// Đặt mật khẩu mới sau khi đã xác thực OTP thành công (Quên mật khẩu)
  Future<void> resetPassword({required String newPassword});

  /// Đổi mật khẩu chủ động từ màn hình Cài đặt Bảo mật (M06)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Lấy danh sách các phiên thiết bị đang hoạt động cho màn hình M06
  Future<List<SessionModel>> getActiveSessions();

  /// Thu hồi phiên thiết bị từ xa
  Future<void> revokeSession(String sessionId);

  /// Lấy thông tin hồ sơ người dùng hiện tại
  Future<UserModel> getProfile();

  /// Cập nhật thông tin hồ sơ người dùng hiện tại
  Future<UserModel> updateProfile(Map<String, dynamic> profileData);

  /// Lấy danh sách tài khoản ngân hàng liên kết của người dùng
  Future<List<BankAccountModel>> getBankAccounts();

  /// Thêm mới tài khoản ngân hàng liên kết
  Future<BankAccountModel> addBankAccount(Map<String, dynamic> accountData);

  /// Xóa tài khoản ngân hàng liên kết theo mã định danh
  Future<void> deleteBankAccount(String accountId);

  /// Đăng xuất, hủy phiên làm việc hiện tại
  Future<void> logout();
}
