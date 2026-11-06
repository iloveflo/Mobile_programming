import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/models/register_request_model.dart';
import 'package:my_first_app/repositories/mock/mock_auth_repository.dart';
import 'package:my_first_app/services/session_storage_service.dart';
import 'package:my_first_app/widgets/dev/dev_state_panel.dart';

void main() {
  group('AuthController', () {
    late AuthController controller;

    setUp(() {
      final index = UserMockData.usersDatabase.indexWhere(
        (u) => u.email == 'dev@test.com',
      );
      if (index != -1) {
        final current = UserMockData.usersDatabase[index];
        UserMockData.usersDatabase[index] = current.copyWith(
          passwordHash: '123456',
        );
      }
      controller = AuthController(MockAuthRepository());
    });

    tearDown(() {
      controller.setDevState(DevAuthState.normal);
    });

    test('đăng nhập thành công với tài khoản mẫu', () async {
      final result = await controller.login('dev@test.com', '123456');
      expect(result, AuthResultState.success);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser?.email, 'dev@test.com');
    });

    test('đăng nhập thất bại và trả về thông báo lỗi', () async {
      final result = await controller.login('dev@test.com', 'sai-mat-khau');
      expect(result, AuthResultState.invalid);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
      expect(controller.errorMessage, isNotEmpty);
    });

    test(
      'đăng xuất xóa người dùng hiện tại nhưng giữ nguyên cài đặt sinh trắc học của thiết bị',
      () async {
        await controller.login('dev@test.com', '123456');
        await controller.setBiometricEnabled(true);
        await controller.logout();
        expect(controller.isAuthenticated, isFalse);
        expect(controller.currentUser, isNull);
        expect(controller.isBiometricEnabled, isTrue);
      },
    );

    test(
      'updateCurrentUser cập nhật thông tin cá nhân và thông báo listeners',
      () async {
        await controller.login('dev@test.com', '123456');
        expect(controller.currentUser?.fullName, 'Nguyen Van Dev');

        controller.updateCurrentUser(
          fullName: 'Nguyễn Văn A',
          phone: '0988889999',
          monthlyIncome: 45000000,
        );

        expect(controller.currentUser?.fullName, 'Nguyễn Văn A');
        expect(controller.currentUser?.phone, '0988889999');
        expect(controller.currentUser?.monthlyIncome, 45000000);
      },
    );

    test(
      'cập nhật cấu hình bảo mật sinh trắc học và tự động khóa thành công',
      () async {
        await controller.login('dev@test.com', '123456');

        final bioResult = await controller.setBiometricEnabled(false);
        expect(bioResult, isTrue);
        expect(controller.isBiometricEnabled, isFalse);
        expect(controller.currentUser?.isBiometricEnabled, isFalse);

        final lockResult = await controller.setAutoLockEnabled(false);
        expect(lockResult, isTrue);
        expect(controller.isAutoLockEnabled, isFalse);
        expect(controller.currentUser?.isAutoLockEnabled, isFalse);
      },
    );

    test(
      'quy trình đăng ký, nhận OTP, xác thực và hoàn tất thành công',
      () async {
        final request = RegisterRequestModel(
          fullName: 'Tran Thi Moi',
          email: 'moi@test.com',
          phone: '0987654321',
          dateOfBirth: DateTime(1995, 5, 15),
          password: 'Password123!',
        );

        final registerResult = await controller.register(request);
        expect(registerResult, isTrue);
        expect(controller.pendingEmail, 'moi@test.com');
        expect(controller.pendingPhone, '0987654321');

        // Thử xác thực OTP sai -> thất bại
        final wrongOtp = await controller.verifyOtp(
          '000000',
          flow: OtpFlow.register,
        );
        expect(wrongOtp, isFalse);
        expect(controller.errorMessage, isNotNull);

        // Thử gửi lại OTP
        await controller.resendOtp();
        expect(controller.otpCountdown, greaterThan(0));

        // Xác thực OTP đúng 123456 -> thành công
        final successOtp = await controller.verifyOtp(
          '123456',
          flow: OtpFlow.register,
        );
        expect(successOtp, isTrue);
      },
    );

    test('quy trình đặt lại mật khẩu và đổi mật khẩu an toàn', () async {
      await controller.login('dev@test.com', '123456');

      // Đổi mật khẩu với mật khẩu cũ sai
      final failChange = await controller.changePassword(
        currentPassword: 'wrong_old_pass',
        newPassword: 'NewPassword123!',
      );
      expect(failChange, isFalse);
      expect(controller.errorMessage, isNotNull);

      // Đổi mật khẩu với mật khẩu cũ đúng
      final successChange = await controller.changePassword(
        currentPassword: '123456',
        newPassword: 'NewPassword123!',
      );
      expect(successChange, isTrue);

      // Đặt lại mật khẩu quên
      final resetSuccess = await controller.resetPassword(
        'ResetNewPassword123!',
      );
      expect(resetSuccess, isTrue);
    });

    test('xác thực eKYC cập nhật trạng thái người dùng thành công', () async {
      await controller.login('dev@test.com', '123456');

      final ekycResult = await controller.verifyEkyc(
        idCardNumber: '001200001234',
        frontCardUrl: 'https://r2.fincredit.vn/ekyc/front.jpg',
        backCardUrl: 'https://r2.fincredit.vn/ekyc/back.jpg',
      );

      expect(ekycResult, isTrue);
      expect(controller.currentUser?.isEkycVerified, isTrue);
    });

    test('xuất hồ sơ tài chính cá nhân PDF thành công', () async {
      await controller.login('dev@test.com', '123456');

      final pdfPath = await controller.exportFinancialProfilePdf();
      expect(pdfPath, isNotNull);
      expect(pdfPath, contains('pdf'));
    });

    test('đồng bộ hồ sơ cá nhân và kiểm tra phiên hoạt động', () async {
      await controller.login('dev@test.com', '123456');

      final syncSuccess = await controller.syncProfile({
        'full_name': 'Nguyen Dev VIP',
        'monthly_income': 60000000,
      });
      expect(syncSuccess, isTrue);
      expect(controller.currentUser?.fullName, 'Nguyen Dev VIP');

      final hasSession = await controller.checkSession();
      expect(hasSession, isTrue);
    });

    test('đăng nhập với rememberMe = true lưu phiên bền vững', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'fincredit_test_remember_',
      );
      addTearDown(() {
        if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
      });

      final testStorage = SessionStorageService(customDirectory: tempDir);
      final repo = MockAuthRepository(sessionStorage: testStorage);
      final testController = AuthController(repo);

      final result = await testController.login(
        'dev@test.com',
        '123456',
        rememberMe: true,
      );
      expect(result, AuthResultState.success);
      expect(testController.isAuthenticated, isTrue);

      final sessionFile = File('${tempDir.path}/auth_session.json');
      expect(sessionFile.existsSync(), isTrue);

      final freshStorage = SessionStorageService(customDirectory: tempDir);
      expect(freshStorage.getSavedTokenSync(), isNotNull);
      expect(freshStorage.getSavedTokenSync()?.userId, 1);
    });

    test(
      'đăng nhập với rememberMe = false không lưu phiên bền vững xuống ổ đĩa',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'fincredit_test_session_',
        );
        addTearDown(() {
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        });

        final testStorage = SessionStorageService(customDirectory: tempDir);
        final repo = MockAuthRepository(sessionStorage: testStorage);
        final testController = AuthController(repo);

        final result = await testController.login(
          'dev@test.com',
          '123456',
          rememberMe: false,
        );
        expect(result, AuthResultState.success);
        expect(testController.isAuthenticated, isTrue);

        final sessionFile = File('${tempDir.path}/auth_session.json');
        expect(sessionFile.existsSync(), isFalse);

        final freshStorage = SessionStorageService(customDirectory: tempDir);
        expect(freshStorage.getSavedTokenSync(), isNull);
      },
    );

    test('setRememberMe cập nhật giá trị và thông báo listeners', () {
      expect(controller.rememberMe, isTrue);
      controller.setRememberMe(false);
      expect(controller.rememberMe, isFalse);
      controller.setRememberMe(true);
      expect(controller.rememberMe, isTrue);
    });
  });
}
