import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:my_first_app/services/biometric_auth_service.dart';

class _FakeBiometricDriver implements BiometricAuthDriver {
  bool supported;
  bool canCheck;
  List<BiometricType> enrolled;
  bool authResult;
  PlatformException? authError;

  _FakeBiometricDriver({
    this.supported = true,
    this.canCheck = true,
    this.enrolled = const [BiometricType.fingerprint],
    this.authResult = true,
    this.authError,
  });

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> canCheckBiometrics() async => canCheck;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => enrolled;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    if (authError != null) throw authError!;
    return authResult;
  }
}

void main() {
  group('BiometricAuthService (Android Fingerprint Only)', () {
    test(
      'Trả về notSupported khi thiết bị không hỗ trợ sinh trắc học',
      () async {
        final service = BiometricAuthService(
          driver: _FakeBiometricDriver(supported: false),
        );
        expect(
          await service.checkFingerprintAvailability(),
          FingerprintAvailability.notSupported,
        );

        final serviceNoCheck = BiometricAuthService(
          driver: _FakeBiometricDriver(canCheck: false),
        );
        expect(
          await serviceNoCheck.checkFingerprintAvailability(),
          FingerprintAvailability.notSupported,
        );
      },
    );

    test(
      'Bỏ qua FaceID - trả về notEnrolled nếu chỉ có BiometricType.face',
      () async {
        final service = BiometricAuthService(
          driver: _FakeBiometricDriver(enrolled: [BiometricType.face]),
        );
        expect(
          await service.checkFingerprintAvailability(),
          FingerprintAvailability.notEnrolled,
        );

        final result = await service.authenticateFingerprint(
          reason: 'Xác thực thử',
        );
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('chưa đăng ký vân tay'));
      },
    );

    test('Xác thực vân tay thành công với BiometricType.fingerprint', () async {
      final service = BiometricAuthService(
        driver: _FakeBiometricDriver(
          enrolled: [BiometricType.fingerprint],
          authResult: true,
        ),
      );
      expect(
        await service.checkFingerprintAvailability(),
        FingerprintAvailability.available,
      );

      final result = await service.authenticateFingerprint(
        reason: 'Đăng nhập FinCredit',
      );
      expect(result.isSuccess, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('Xử lý khi người dùng hủy quét vân tay', () async {
      final service = BiometricAuthService(
        driver: _FakeBiometricDriver(authResult: false),
      );
      final result = await service.authenticateFingerprint(
        reason: 'Đăng nhập FinCredit',
      );
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('hủy hoặc không khớp'));
    });

    test('Xử lý lỗi LockedOut từ Android BiometricPrompt', () async {
      final service = BiometricAuthService(
        driver: _FakeBiometricDriver(
          authError: PlatformException(code: auth_error.lockedOut),
        ),
      );
      final result = await service.authenticateFingerprint(
        reason: 'Đăng nhập FinCredit',
      );
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('quá nhiều lần'));
    });
  });
}
