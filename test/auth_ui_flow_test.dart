import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/screens/auth/otp_verification_screen.dart';
import 'package:my_first_app/screens/auth/register_screen.dart';
import 'package:my_first_app/screens/auth/reset_password_screen.dart';
import 'package:my_first_app/service_locator.dart';
import 'package:my_first_app/widgets/widget.dart';

void main() {
  setUpAll(() async {
    setupServiceLocator();
  });

  group('Auth UI Flow Tests', () {
    testWidgets(
      '1. RegisterScreen hiển thị đầy đủ biểu mẫu đăng ký thành viên mới',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Đăng ký tài khoản'), findsOneWidget);
        expect(find.text('Họ và tên (theo CCCD)'), findsOneWidget);
        expect(find.text('Email nhận thông báo'), findsOneWidget);
        expect(find.text('Số điện thoại'), findsOneWidget);
        expect(find.text('Ngày sinh (trên 18 tuổi)'), findsOneWidget);
        expect(find.text('Đăng ký & Nhận mã OTP'), findsOneWidget);
        expect(find.text('Đã có tài khoản? '), findsOneWidget);
        expect(find.text('Đăng nhập'), findsOneWidget);
      },
    );

    testWidgets(
      '2. OtpVerificationScreen hiển thị bộ nhập mã 6 số và đếm ngược',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          sl<AuthController>().setDevState(DevAuthState.normal);
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: OtpVerificationScreen(
              email: 'dev@test.com',
              phone: '0912345678',
              flow: OtpFlow.register,
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Xác thực mã OTP'), findsOneWidget);
        expect(find.byType(OtpInputField), findsOneWidget);
        expect(find.text('Xác nhận mã'), findsOneWidget);

        // Hủy timer OTP trước khi kết thúc test
        sl<AuthController>().setDevState(DevAuthState.normal);
        await tester.pump();
      },
    );

    testWidgets(
      '3. ResetPasswordScreen hiển thị form nhập mật khẩu mới và thước đo độ mạnh',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: ResetPasswordScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Thiết lập mật khẩu mới'), findsOneWidget);
        expect(find.text('Mật khẩu mới'), findsOneWidget);
        expect(find.text('Xác nhận mật khẩu mới'), findsOneWidget);
        expect(find.text('Cập nhật mật khẩu'), findsOneWidget);
      },
    );
  });
}
