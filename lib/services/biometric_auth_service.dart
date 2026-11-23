import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';

/// Trạng thái khả dụng của cảm biến vân tay trên thiết bị Android
enum FingerprintAvailability { available, notSupported, notEnrolled }

/// Kết quả xác thực vân tay
class FingerprintAuthResult {
  final bool isSuccess;
  final String? errorMessage;

  const FingerprintAuthResult._({required this.isSuccess, this.errorMessage});

  const FingerprintAuthResult.success() : this._(isSuccess: true);

  const FingerprintAuthResult.failure(String message)
    : this._(isSuccess: false, errorMessage: message);
}

/// Giao diện trừu tượng hóa LocalAuthentication để dễ kiểm thử Unit Test
abstract class BiometricAuthDriver {
  Future<bool> isDeviceSupported();
  Future<bool> canCheckBiometrics();
  Future<List<BiometricType>> getAvailableBiometrics();
  Future<bool> authenticate({required String localizedReason});
}

class LocalAuthBiometricDriver implements BiometricAuthDriver {
  final LocalAuthentication _localAuth;

  LocalAuthBiometricDriver({LocalAuthentication? localAuth})
    : _localAuth = localAuth ?? LocalAuthentication();

  @override
  Future<bool> isDeviceSupported() => _localAuth.isDeviceSupported();

  @override
  Future<bool> canCheckBiometrics() => _localAuth.canCheckBiometrics;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() =>
      _localAuth.getAvailableBiometrics();

  @override
  Future<bool> authenticate({required String localizedReason}) {
    return _localAuth.authenticate(
      localizedReason: localizedReason,
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
        useErrorDialogs: true,
      ),
    );
  }
}

/// Dịch vụ xác thực Sinh trắc học (chỉ tập trung vào Vân tay Android)
class BiometricAuthService {
  final BiometricAuthDriver _driver;

  BiometricAuthService({BiometricAuthDriver? driver})
    : _driver = driver ?? LocalAuthBiometricDriver();

  /// Kiểm tra thiết bị có hỗ trợ cảm biến vân tay và đã đăng ký vân tay chưa
  Future<FingerprintAvailability> checkFingerprintAvailability() async {
    try {
      final isSupported = await _driver.isDeviceSupported();
      final canCheck = await _driver.canCheckBiometrics();
      if (!isSupported || !canCheck) {
        return FingerprintAvailability.notSupported;
      }

      final biometrics = await _driver.getAvailableBiometrics();
      final hasFingerprint =
          biometrics.contains(BiometricType.fingerprint) ||
          biometrics.contains(BiometricType.strong);
      if (!hasFingerprint) {
        return FingerprintAvailability.notEnrolled;
      }
      return FingerprintAvailability.available;
    } on PlatformException catch (e) {
      if (e.code == auth_error.notEnrolled) {
        return FingerprintAvailability.notEnrolled;
      }
      return FingerprintAvailability.notSupported;
    } on MissingPluginException {
      return FingerprintAvailability.notSupported;
    } catch (_) {
      return FingerprintAvailability.notSupported;
    }
  }

  /// Kích hoạt hộp thoại quét vân tay phần cứng Android (BiometricPrompt)
  Future<FingerprintAuthResult> authenticateFingerprint({
    required String reason,
  }) async {
    final availability = await checkFingerprintAvailability();
    if (availability == FingerprintAvailability.notSupported) {
      return const FingerprintAuthResult.failure(
        'Thiết bị này không hỗ trợ cảm biến vân tay.',
      );
    }
    if (availability == FingerprintAvailability.notEnrolled) {
      return const FingerprintAuthResult.failure(
        'Thiết bị chưa đăng ký vân tay. Vui lòng thêm vân tay trong Cài đặt Android.',
      );
    }

    try {
      final authenticated = await _driver.authenticate(localizedReason: reason);
      if (authenticated) {
        return const FingerprintAuthResult.success();
      }
      return const FingerprintAuthResult.failure(
        'Xác thực vân tay đã bị hủy hoặc không khớp.',
      );
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notAvailable:
          return const FingerprintAuthResult.failure(
            'Cảm biến vân tay hiện không khả dụng.',
          );
        case auth_error.notEnrolled:
          return const FingerprintAuthResult.failure(
            'Chưa có vân tay nào được đăng ký trên thiết bị.',
          );
        case auth_error.lockedOut:
          return const FingerprintAuthResult.failure(
            'Thử sai vân tay quá nhiều lần. Vui lòng thử lại sau ít phút.',
          );
        case auth_error.permanentlyLockedOut:
          return const FingerprintAuthResult.failure(
            'Cảm biến vân tay đã bị khóa tạm thời bởi hệ thống. Vui lòng mở khóa thiết bị bằng mã PIN/mật khẩu.',
          );
        default:
          return FingerprintAuthResult.failure(
            e.message ?? 'Không thể xác thực vân tay. Vui lòng thử lại.',
          );
      }
    } on MissingPluginException {
      return const FingerprintAuthResult.failure(
        'Tính năng vân tay chỉ hỗ trợ trên thiết bị Android thật/Emulator có vân tay.',
      );
    } catch (_) {
      return const FingerprintAuthResult.failure(
        'Đã xảy ra lỗi khi xác thực vân tay.',
      );
    }
  }
}
