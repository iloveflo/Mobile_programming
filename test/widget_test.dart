import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/main.dart';
import 'package:my_first_app/screens/auth/login_screen.dart';
import 'package:my_first_app/screens/auth/splash_screen.dart';
import 'package:my_first_app/service_locator.dart';

void main() {
  setUpAll(setupServiceLocator);

  testWidgets('Ứng dụng khởi động tại màn hình SplashScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('FinCredit'), findsOneWidget);

    // Chờ splash delay kết thúc và chuyển tiếp màn hình, hoàn tất fetch dữ liệu ban đầu
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
  });

  testWidgets('Màn hình Đăng nhập hiển thị các trường nhập liệu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Đăng ký ngay'), findsOneWidget);
  });
}
