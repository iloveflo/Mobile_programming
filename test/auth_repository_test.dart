import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/repositories/interfaces/auth_repository.dart';
import 'package:my_first_app/repositories/mock/mock_auth_repository.dart';

void main() {
  group('MockAuthRepository Unit Tests', () {
    late MockAuthRepository repo;

    setUp(() {
      repo = MockAuthRepository();
    });

    test('Đăng nhập thành công với thông tin đúng từ mock data', () async {
      final user = await repo.login(
        identifier: 'dev@test.com',
        password: '123456',
      );
      expect(user.email, 'dev@test.com');
      expect(user.token, isNotNull);
    });

    test('Đăng nhập với email locked ném AccountLockedException', () async {
      expect(
        () => repo.login(identifier: 'locked@fincredit.vn', password: '123'),
        throwsA(isA<AccountLockedException>()),
      );
    });

    test(
      'Đăng nhập với email unverified ném AccountUnverifiedException',
      () async {
        expect(
          () => repo.login(
            identifier: 'unverified@fincredit.vn',
            password: '123',
          ),
          throwsA(isA<AccountUnverifiedException>()),
        );
      },
    );

    test(
      'Đăng nhập sai mật khẩu 5 lần kích hoạt AccountLockedException',
      () async {
        for (int i = 0; i < 4; i++) {
          await expectLater(
            repo.login(identifier: 'dev@test.com', password: 'wrong_password'),
            throwsA(isA<InvalidCredentialsException>()),
          );
        }

        // Lần thứ 5 sẽ bị khóa
        await expectLater(
          repo.login(identifier: 'dev@test.com', password: 'wrong_password'),
          throwsA(isA<AccountLockedException>()),
        );
      },
    );

    test('Xác thực OTP 123456 thành công', () async {
      final isOk = await repo.verifyOtp(otp: '123456', flowType: 'REGISTER');
      expect(isOk, isTrue);
    });

    test(
      'Xác thực OTP 000000 ném OtpException với cờ isExpired == true',
      () async {
        try {
          await repo.verifyOtp(otp: '000000', flowType: 'REGISTER');
          fail('Should throw OtpException');
        } on OtpException catch (e) {
          expect(e.isExpired, isTrue);
          expect(e.message, contains('hết hạn'));
        }
      },
    );

    test('Xác thực OTP sai ném OtpException với số lượt còn lại', () async {
      try {
        await repo.verifyOtp(otp: '999999', flowType: 'REGISTER');
        fail('Should throw OtpException');
      } on OtpException catch (e) {
        expect(e.isExpired, isFalse);
        expect(e.remainingAttempts, 4);
      }
    });

    test(
      'getActiveSessions trả về danh sách phiên và revokeSession xóa phiên thành công',
      () async {
        final initialSessions = await repo.getActiveSessions();
        expect(initialSessions.length, 3);

        await repo.revokeSession('sess_macbook');
        final updatedSessions = await repo.getActiveSessions();
        expect(updatedSessions.length, 2);
        expect(updatedSessions.any((s) => s.id == 'sess_macbook'), isFalse);
      },
    );

    test('simulateNetworkError kích hoạt ném NetworkAuthException', () async {
      repo.simulateNetworkError = true;
      expect(
        () => repo.login(identifier: 'dev@test.com', password: '123456'),
        throwsA(isA<NetworkAuthException>()),
      );
    });

    test(
      'Đăng ký tài khoản mới chỉ có duy nhất 1 phiên thiết bị hiện tại',
      () async {
        final email =
            'newuser_${DateTime.now().millisecondsSinceEpoch}@fincredit.vn';
        await repo.register({
          'full_name': 'Người Dùng Mới',
          'email': email,
          'phone': '0987654321',
          'password': 'password123',
        });

        final sessions = await repo.getActiveSessions();
        expect(sessions.length, 1);
        expect(sessions.first.isCurrent, isTrue);
      },
    );
  });
}
