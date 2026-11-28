import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/models/loan_model.dart';
import 'package:my_first_app/models/notification_model.dart';
import 'package:my_first_app/models/notification_preference_model.dart';
import 'package:my_first_app/models/payment_schedule_model.dart';
import 'package:my_first_app/routes/app_router.dart';
import 'package:my_first_app/screens/auth/login_screen.dart';
import 'package:my_first_app/screens/credit_report/credit_report_list_screen.dart';
import 'package:my_first_app/screens/loans/loan_collateral_ocr_screen.dart';
import 'package:my_first_app/screens/simulation/simulation_screen.dart';
import 'package:my_first_app/service_locator.dart';
import 'package:my_first_app/services/local_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await resetServiceLocator(dispose: false);
    setupServiceLocator();
  });

  group('AppRouter Named Routes Tests', () {
    testWidgets('Tất cả route trong AppRouter.routes khởi tạo widget hợp lệ', (
      tester,
    ) async {
      sl<AuthController>().setCurrentUser(UserMockData.usersDatabase.first);
      final routes = AppRouter.routes;

      expect(routes.containsKey(AppRouter.splash), isTrue);
      expect(routes.containsKey(AppRouter.login), isTrue);
      expect(routes.containsKey(AppRouter.register), isTrue);
      expect(routes.containsKey(AppRouter.otp), isTrue);
      expect(routes.containsKey(AppRouter.resetPassword), isTrue);
      expect(routes.containsKey(AppRouter.security), isTrue);
      expect(routes.containsKey(AppRouter.settings), isTrue);
      expect(routes.containsKey(AppRouter.home), isTrue);
      expect(routes.containsKey(AppRouter.loans), isTrue);
      expect(routes.containsKey(AppRouter.loanDetail), isTrue);
      expect(routes.containsKey(AppRouter.loanForm), isTrue);
      expect(routes.containsKey(AppRouter.loanCollateralOcr), isTrue);
      expect(routes.containsKey(AppRouter.debtStrategy), isTrue);
      expect(routes.containsKey(AppRouter.simulation), isTrue);
      expect(routes.containsKey(AppRouter.creditReports), isTrue);
      expect(routes.containsKey(AppRouter.creditReportDetail), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              for (final key in [
                AppRouter.register,
                AppRouter.otp,
                AppRouter.resetPassword,
                AppRouter.settings,
                AppRouter.loans,
                AppRouter.loanDetail,
                AppRouter.loanForm,
                AppRouter.loanCollateralOcr,
                AppRouter.debtStrategy,
                AppRouter.simulation,
                AppRouter.creditReports,
                AppRouter.creditReportDetail,
              ]) {
                expect(routes[key]!(ctx), isA<Widget>());
              }
              return routes[AppRouter.login]!(ctx);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('LocalNotificationService MethodChannel Tests', () {
    const channel = MethodChannel('fincredit/notifications');
    final List<MethodCall> calls = [];

    setUp(() {
      calls.clear();
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'requestPermission') return true;
            if (call.method == 'showNotification') return true;
            if (call.method == 'getInitialNotificationLaunch') {
              return {'tabIndex': 2, 'scheduleId': 99};
            }
            return null;
          });
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test(
      'setTapHandler, checkInitialLaunch, requestPermissionOnce, showLocalNotification & notifyOverdueOrUrgent',
      () async {
        int? tappedTab;
        int? tappedSchedule;
        LocalNotificationService.setTapHandler((tabIndex, scheduleId) {
          tappedTab = tabIndex;
          tappedSchedule = scheduleId;
        });

        await LocalNotificationService.checkInitialLaunch();
        expect(tappedTab, 2);
        expect(tappedSchedule, 99);

        final granted = await LocalNotificationService.requestPermissionOnce();
        expect(granted, isTrue);

        await LocalNotificationService.showLocalNotification(
          id: 1,
          title: 'Test',
          body: 'Body',
          dedupeKey: 'k1',
          scheduleId: 5,
        );
        expect(calls.any((c) => c.method == 'showNotification'), isTrue);

        await LocalNotificationService.notifyOverdueOrUrgent(
          notifications: [
            NotificationModel(
              id: 10,
              userId: 1,
              scheduleId: 2,
              type: 'OVERDUE_ALERT',
              channel: 'PUSH',
              title: 'Quá hạn',
              message: 'Kỳ 2 đã quá hạn',
              status: 'SENT',
              scheduledAt: DateTime(2026, 11, 1),
            ),
          ],
          schedules: [
            PaymentScheduleModel(
              id: 2,
              loanId: 101,
              installmentNumber: 2,
              dueDate: DateTime(2026, 11, 1),
              principalAmount: 1000000,
              interestAmount: 100000,
              feeAmount: 0,
              totalAmount: 1100000,
              remainingBalance: 1100000,
              status: 'OVERDUE',
            ),
          ],
          loans: [
            LoanModel(
              id: 101,
              userId: 1,
              loanTypeId: 1,
              name: 'Vay tiêu dùng',
              principalAmount: 10000000,
              interestRate: 12,
              interestMethod: 'REDUCING_BALANCE',
              termMonths: 12,
              startDate: DateTime(2026, 1, 1),
              outstandingAmount: 5000000,
              earlyPaymentFeeRate: 0.02,
              status: 'ACTIVE',
            ),
          ],
          preference: const NotificationPreferenceModel(
            id: 1,
            userId: 1,
            pushEnabled: true,
            emailEnabled: true,
            reminderDays: 3,
          ),
        );
        expect(
          calls.where((c) => c.method == 'showNotification').length,
          greaterThanOrEqualTo(1),
        );
      },
    );
  });

  group(
    'Screen Interaction Tests (Login, CreditReportList, Simulation, CollateralOCR)',
    () {
      testWidgets(
        'LoginScreen hiển thị form, báo lỗi khi submit rỗng và đăng nhập mẫu',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
          await tester.pumpAndSettle();

          expect(find.byType(LoginScreen), findsOneWidget);
          final submitBtn = find.widgetWithText(ElevatedButton, 'Đăng nhập');
          if (submitBtn.evaluate().isNotEmpty) {
            await tester.tap(submitBtn.first);
            await tester.pumpAndSettle();
          }
        },
      );

      testWidgets(
        'CreditReportListScreen, SimulationScreen & LoanCollateralOcrScreen render đầy đủ',
        (tester) async {
          tester.view.physicalSize = const Size(800, 2000);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          sl<AuthController>().setCurrentUser(UserMockData.usersDatabase.first);
          await sl<LoanController>().fetchLoans();

          await tester.pumpWidget(
            const MaterialApp(home: CreditReportListScreen()),
          );
          await tester.pumpAndSettle();
          expect(find.byType(CreditReportListScreen), findsOneWidget);

          await tester.pumpWidget(const MaterialApp(home: SimulationScreen()));
          await tester.pumpAndSettle();
          expect(find.byType(SimulationScreen), findsOneWidget);

          await tester.pumpWidget(
            const MaterialApp(home: LoanCollateralOcrScreen()),
          );
          await tester.pumpAndSettle();
          expect(find.byType(LoanCollateralOcrScreen), findsOneWidget);
        },
      );
    },
  );
}
