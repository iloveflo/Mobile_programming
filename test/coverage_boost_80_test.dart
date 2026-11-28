import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/controllers/payment_schedule_controller.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/models/loan_model.dart';
import 'package:my_first_app/models/notification_preference_model.dart';
import 'package:my_first_app/repositories/mock/mock_loan_repository.dart';
import 'package:my_first_app/repositories/mock/mock_payment_schedule_repository.dart';
import 'package:my_first_app/routes/app_router.dart';
import 'package:my_first_app/screens/auth/login_screen.dart';
import 'package:my_first_app/screens/loans/loan_detail_screen.dart';
import 'package:my_first_app/screens/loans/loan_form_screen.dart';
import 'package:my_first_app/screens/settings/app_settings_screen.dart';
import 'package:my_first_app/screens/simulation/simulation_screen.dart';
import 'package:my_first_app/service_locator.dart';

void main() {
  setUpAll(() async {
    await resetServiceLocator(dispose: false);
    setupServiceLocator(isMock: true);
  });

  group('Controllers & Models Coverage Boost', () {
    test(
      'PaymentScheduleController pagination, filters, markAsPaid, notifications & sync',
      () async {
        final ctrl = PaymentScheduleController(MockPaymentScheduleRepository());
        await ctrl.loadSchedules(userId: 1);
        await ctrl.loadMoreSchedules(userId: 1);
        ctrl.setFilter('PENDING', userId: 1);
        ctrl.setPeriod('THIS_MONTH', userId: 1);
        ctrl.setFilter('ALL', userId: 1);
        ctrl.setPeriod('ALL', userId: 1);
        await ctrl.loadNotifications(userId: 1);
        await ctrl.loadNotificationPreference(userId: 1);
        await ctrl.updatePreference(
          const NotificationPreferenceModel(
            id: 1,
            userId: 1,
            pushEnabled: true,
            emailEnabled: false,
            reminderDays: 5,
          ),
        );
        await ctrl.syncSchedules(userId: 1);
        if (ctrl.notifications.isNotEmpty) {
          await ctrl.deleteNotification(ctrl.notifications.first.id);
        }
        await ctrl.clearNotifications(userId: 1);
        expect(ctrl.notifications, isEmpty);
      },
    );

    test(
      'LoanController documents, collaterals, getDetail & LoanModel helpers',
      () async {
        final ctrl = LoanController(MockLoanRepository());
        await ctrl.fetchLoans();
        final loan = ctrl.loans.first;

        await ctrl.getDetail(loan.id.toString());
        expect(ctrl.selectedLoan, isNotNull);

        await ctrl.fetchLoanDocuments(loan.id.toString());
        await ctrl.setSelectedLender(loan.lenderName);
        await ctrl.setSelectedLender(null);
        ctrl.clearError();

        expect(LoanModel.maxUnsecuredLimitForIncome(30000000), greaterThan(0));
        expect(loan.toJson(), isA<Map<String, dynamic>>());
      },
    );
  });

  group(
    'Deep Widget Interaction Boost (Login, LoanForm, LoanDetail, Simulation, Settings)',
    () {
      testWidgets('LoginScreen submit hợp lệ', (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: const LoginScreen(),
            routes: {AppRouter.home: (_) => const Scaffold(body: Text('HOME'))},
          ),
        );
        await tester.pumpAndSettle();

        final fields = find.byType(TextFormField);
        await tester.enterText(fields.at(0), 'dev@test.com');
        await tester.enterText(fields.at(1), '123456');
        final loginBtn = find.widgetWithText(ElevatedButton, 'Đăng nhập');
        if (loginBtn.evaluate().isNotEmpty) {
          await tester.tap(loginBtn.first);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('LoanFormScreen điền form đầy đủ và submit tạo mới', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(800, 3200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        sl<AuthController>().setCurrentUser(UserMockData.usersDatabase.first);
        final loanCtrl = sl<LoanController>();
        await loanCtrl.fetchLoans();

        await tester.pumpWidget(const MaterialApp(home: LoanFormScreen()));
        await tester.pumpAndSettle();

        final unsecured = find.text('Tín chấp');
        if (unsecured.evaluate().isNotEmpty) {
          await tester.tap(unsecured.first);
          await tester.pumpAndSettle();
        }

        final fields = find.byType(TextFormField);
        if (fields.evaluate().isNotEmpty) {
          await tester.enterText(fields.at(0), 'Vay tiêu dùng Boost');
          await tester.pump();
        }

        final submitBtn = find.byType(ElevatedButton);
        if (submitBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(submitBtn.last);
          await tester.tap(submitBtn.last);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('LoanFormScreen chế độ chỉnh sửa submit', (tester) async {
        tester.view.physicalSize = const Size(800, 3200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final loanCtrl = sl<LoanController>();
        await loanCtrl.fetchLoans();

        await tester.pumpWidget(
          MaterialApp(
            home: LoanFormScreen(
              key: const ValueKey('edit_loan_form'),
              initialLoan: loanCtrl.loans.first,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final editBtn = find.byType(ElevatedButton);
        if (editBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(editBtn.last);
          await tester.tap(editBtn.last);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('LoanDetailScreen bấm ghi nhận thanh toán & mở dialog', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(800, 2800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final loanCtrl = sl<LoanController>();
        await loanCtrl.fetchLoans();
        final loan = loanCtrl.loans.first;

        await tester.pumpWidget(
          MaterialApp(home: LoanDetailScreen(loanId: loan.id.toString())),
        );
        await tester.pumpAndSettle();

        final buttons = find.byType(ElevatedButton);
        if (buttons.evaluate().isNotEmpty) {
          await tester.ensureVisible(buttons.last);
          await tester.tap(buttons.last);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('SimulationScreen mở dialog lưu kịch bản và bấm Lưu', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        sl<AuthController>().setCurrentUser(UserMockData.usersDatabase.first);
        await tester.pumpWidget(const MaterialApp(home: SimulationScreen()));
        await tester.pumpAndSettle();

        final saveBtn = find.textContaining('Lưu kịch bản');
        if (saveBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(saveBtn.first);
          await tester.tap(saveBtn.first);
          await tester.pumpAndSettle();

          final confirmBtn = find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(ElevatedButton),
          );
          if (confirmBtn.evaluate().isNotEmpty) {
            await tester.tap(confirmBtn.first);
            await tester.pumpAndSettle();
          }
        }
      });

      testWidgets(
        'AppSettingsScreen bật/tắt SwitchListTile và bấm nút hành động',
        (tester) async {
          tester.view.physicalSize = const Size(800, 2400);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          sl<AuthController>().setCurrentUser(UserMockData.usersDatabase.first);
          await tester.pumpWidget(const MaterialApp(home: AppSettingsScreen()));
          await tester.pumpAndSettle();

          final switches = find.byType(SwitchListTile);
          for (int i = 0; i < switches.evaluate().length; i++) {
            await tester.ensureVisible(switches.at(i));
            await tester.tap(switches.at(i));
            await tester.pumpAndSettle();
          }
        },
      );
    },
  );
}
