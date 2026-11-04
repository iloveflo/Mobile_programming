import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/screens/settings/app_settings_screen.dart';
import 'package:my_first_app/service_locator.dart';

void main() {
  setUpAll(() async {
    setupServiceLocator();
  });

  setUp(() async {
    final authController = sl<AuthController>();
    authController.setCurrentUser(UserMockData.usersDatabase.first);
    await authController.loadSessions();
  });

  group('AppSettingsScreen Widget Tests', () {
    testWidgets('1. Render đầy đủ các nhóm thiết lập hệ thống', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: AppSettingsScreen()));
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề AppBar
      expect(find.text('Cài đặt & Bảo mật'), findsOneWidget);

      // Thẻ điểm sức khỏe bảo mật
      expect(find.text('Sức khỏe bảo mật tài khoản'), findsOneWidget);

      // Các Section headers
      expect(find.text('Phương thức xác thực'), findsOneWidget);
      expect(find.text('Thông báo & Nhắc nợ'), findsOneWidget);
      expect(find.text('Dữ liệu & Bộ nhớ tạm'), findsOneWidget);
      expect(find.text('Thông tin ứng dụng'), findsOneWidget);

      // Nút Xóa cache & Đăng xuất
      expect(find.text('Xóa cache'), findsOneWidget);
      expect(find.text('Đăng xuất tài khoản'), findsOneWidget);
    });

    testWidgets('2. Mở dialog xác nhận đăng xuất tài khoản', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: AppSettingsScreen()));
      await tester.pumpAndSettle();

      // Tap nút Đăng xuất
      await tester.tap(find.text('Đăng xuất tài khoản'));
      await tester.pumpAndSettle();

      // Kiểm tra AlertDialog đăng xuất hiển thị
      expect(
        find.text('Bạn có chắc chắn muốn kết thúc phiên đăng nhập?'),
        findsOneWidget,
      );
      expect(find.text('Không'), findsOneWidget);
      expect(find.text('Đăng xuất'), findsOneWidget);

      // Đóng dialog bằng nút Không
      await tester.tap(find.text('Không'));
      await tester.pumpAndSettle();
      expect(
        find.text('Bạn có chắc chắn muốn kết thúc phiên đăng nhập?'),
        findsNothing,
      );
    });

    testWidgets('3. Mở dialog xác nhận thu hồi phiên đăng nhập thiết bị', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: AppSettingsScreen()));
      await tester.pumpAndSettle();

      // Tìm nút icon thu hồi phiên (close / remove) nếu có session phụ
      final revokeIcon = find.byIcon(Icons.remove_circle_outline_rounded);
      if (revokeIcon.evaluate().isNotEmpty) {
        await tester.tap(revokeIcon.first);
        await tester.pumpAndSettle();

        expect(find.text('Thu hồi phiên đăng nhập?'), findsOneWidget);
        expect(find.text('Hủy'), findsOneWidget);
        expect(find.text('Thu hồi'), findsOneWidget);

        // Hủy bỏ
        await tester.tap(find.text('Hủy'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('4. Tương tác bật/tắt thiết lập thông báo', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: AppSettingsScreen()));
      await tester.pumpAndSettle();

      final switchFinder = find.widgetWithText(
        SwitchListTile,
        'Thông báo biến động dư nợ',
      );
      expect(switchFinder, findsOneWidget);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
    });
  });
}
