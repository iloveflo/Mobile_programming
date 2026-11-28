import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/controllers/payment_schedule_controller.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/repositories/interfaces/auth_repository.dart';
import 'package:my_first_app/repositories/interfaces/loan_repository.dart';
import 'package:my_first_app/repositories/remote/api_auth_repository.dart';
import 'package:my_first_app/repositories/remote/api_loan_repository.dart';
import 'package:my_first_app/screens/credit_report/credit_report_list_screen.dart';
import 'package:my_first_app/screens/debt/debt_strategy_screen.dart';
import 'package:my_first_app/screens/main_shell_screen.dart';
import 'package:my_first_app/screens/schedule/payment_schedule_screen.dart';
import 'package:my_first_app/screens/simulation/simulation_screen.dart';
import 'package:my_first_app/service_locator.dart';

void main() {
  group('ServiceLocator Remote & Mock Modes', () {
    test(
      'setupServiceLocator(isMock: false) đăng ký đầy đủ Remote Repositories và reset lại Mock',
      () async {
        await resetServiceLocator(dispose: false);
        setupServiceLocator(isMock: false);

        expect(sl<AuthRepository>(), isA<ApiAuthRepository>());
        expect(sl<LoanRepository>(), isA<ApiLoanRepository>());

        await resetServiceLocator(dispose: false);
        setupServiceLocator(isMock: true);
        expect(sl<AuthRepository>(), isNot(isA<ApiAuthRepository>()));
      },
    );
  });

  group('Deep Screen Interaction Tests', () {
    setUpAll(() async {
      await resetServiceLocator(dispose: false);
      setupServiceLocator(isMock: true);
    });

    setUp(() async {
      sl<AuthController>().setCurrentUser(UserMockData.usersDatabase.first);
      await sl<LoanController>().fetchLoans();
      await sl<PaymentScheduleController>().loadSchedules(userId: 1);
      await sl<PaymentScheduleController>().loadNotifications(userId: 1);
    });

    testWidgets('MainShellScreen chuyển đổi qua lại các tab', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));
      await tester.pumpAndSettle();

      for (final label in [
        'Khoản vay',
        'Lịch trả',
        'Sức khỏe',
        'Cá nhân',
        'Trang chủ',
      ]) {
        final tab = find.text(label);
        if (tab.evaluate().isNotEmpty) {
          await tester.tap(tab.first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('DebtStrategyScreen chuyển chiến lược & chế độ đối sánh', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: DebtStrategyScreen()));
      await tester.pumpAndSettle();

      for (final label in ['Snowball', 'So sánh', 'Avalanche']) {
        final btn = find.textContaining(label);
        if (btn.evaluate().isNotEmpty) {
          await tester.tap(btn.first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('SimulationScreen đổi kịch bản & mở lịch sử mô phỏng', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: SimulationScreen()));
      await tester.pumpAndSettle();

      for (final label in [
        'Đổi tiền trả mỗi kỳ',
        'Thay đổi lãi suất',
        'Trả trước hạn',
        'Trả thêm một khoản',
      ]) {
        final chip = find.text(label);
        if (chip.evaluate().isNotEmpty) {
          await tester.tap(chip.first);
          await tester.pumpAndSettle();
        }
      }

      final historyIcon = find.byIcon(Icons.history);
      if (historyIcon.evaluate().isNotEmpty) {
        await tester.tap(historyIcon.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('PaymentScheduleScreen chuyển bộ lọc & mở cài đặt thông báo', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: PaymentScheduleScreen()));
      await tester.pumpAndSettle();

      for (final label in ['Chờ trả', 'Quá hạn', 'Đã trả', 'Tất cả']) {
        final chip = find.text(label);
        if (chip.evaluate().isNotEmpty) {
          await tester.tap(chip.first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('CreditReportListScreen mở hộp thoại tạo báo cáo mới', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: CreditReportListScreen()),
      );
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab.first);
        await tester.pumpAndSettle();
      }
    });
  });
}
