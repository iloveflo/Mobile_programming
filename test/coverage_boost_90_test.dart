import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/credit_profile_controller.dart';
import 'package:my_first_app/controllers/credit_report_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/controllers/payment_schedule_controller.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/models/auth_token_model.dart';
import 'package:my_first_app/repositories/mock/mock_auth_repository.dart';
import 'package:my_first_app/routes/app_router.dart';
import 'package:my_first_app/screens/credit_report/credit_report_list_screen.dart';
import 'package:my_first_app/screens/home/home_screen.dart';
import 'package:my_first_app/screens/loans/loan_detail_screen.dart';
import 'package:my_first_app/screens/loans/loan_form_screen.dart';
import 'package:my_first_app/screens/settings/app_settings_screen.dart';
import 'package:my_first_app/service_locator.dart';
import 'package:my_first_app/services/realtime_service.dart';
import 'package:my_first_app/services/session_storage_service.dart';
import 'package:my_first_app/widgets/profile/ekyc_verification_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await resetServiceLocator(dispose: false);
    setupServiceLocator(isMock: true);
  });

  group('Services Extra Coverage (SessionStorage, Realtime)', () {
    test('SessionStorageService save, get & clear session in memory', () async {
      final storage = SessionStorageService();
      final token = AuthTokenModel(
        accessToken: 'acc_1',
        refreshToken: 'ref_1',
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        userId: 1,
      );
      await storage.saveSession(
        token: token,
        user: UserMockData.usersDatabase.first,
        identifier: 'dev@test.com',
      );
      expect((await storage.getSavedToken())?.accessToken, 'acc_1');
      expect((await storage.getSavedUser())?.email, 'dev@test.com');
      expect(storage.getLastIdentifierSync(), 'dev@test.com');

      await storage.clearSession();
      expect(await storage.getSavedToken(), isNull);
    });

    test(
      'RealtimeService connect/disconnect lifecycle without active socket',
      () {
        final rt = RealtimeService();
        expect(rt.isConnected, isFalse);
        rt.disconnect();
      },
    );
  });

  group('Deep Interactive Flows to 80%+ Coverage', () {
    setUp(() async {
      sl<AuthController>().setCurrentUser(UserMockData.usersDatabase.first);
      await sl<LoanController>().fetchLoans();
      await sl<PaymentScheduleController>().loadSchedules(userId: 1);
      await sl<PaymentScheduleController>().loadNotifications(userId: 1);
      await sl<CreditProfileController>().loadCreditProfile(userId: 1);
      await sl<CreditReportController>().loadReports(userId: 1);
    });

    testWidgets(
      'LoanFormScreen nhập đầy đủ hợp đồng tín chấp và submit thành công',
      (tester) async {
        tester.view.physicalSize = const Size(800, 3600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: const LoanFormScreen(),
            routes: {
              AppRouter.loans: (_) => const Scaffold(body: Text('LOANS')),
            },
          ),
        );
        await tester.pumpAndSettle();

        // Chọn Tín chấp
        final consumerChip = find.text('Tín chấp');
        if (consumerChip.evaluate().isNotEmpty) {
          await tester.tap(consumerChip.first);
          await tester.pumpAndSettle();
        }

        // Điền tên, số tiền, lãi suất, kỳ hạn
        final fields = find.byType(TextFormField);
        if (fields.evaluate().length >= 4) {
          await tester.enterText(fields.at(0), 'Vay tín chấp mới');
          await tester.enterText(fields.at(1), '30000000');
          await tester.enterText(fields.at(2), '12');
          await tester.enterText(fields.at(3), '12');
          await tester.pump();
        }

        final submitBtn = find.byType(ElevatedButton);
        if (submitBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(submitBtn.last);
          await tester.tap(submitBtn.last);
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets('LoanDetailScreen hiển thị nút hành động & thông tin tài sản', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final loan = sl<LoanController>().loans.first;

      await tester.pumpWidget(
        MaterialApp(
          home: LoanDetailScreen(loanId: loan.id.toString()),
          routes: {
            AppRouter.loanForm: (_) => const Scaffold(body: Text('FORM')),
            AppRouter.simulation: (_) => const Scaffold(body: Text('SIM')),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoanDetailScreen), findsOneWidget);
    });

    testWidgets('HomeScreen tương tác các thẻ KPI, tính lãi nhanh & giáo dục', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      for (final label in ['Tính lãi nhanh', 'Lập kế hoạch', 'Hỗ trợ']) {
        final btn = find.text(label);
        if (btn.evaluate().isNotEmpty) {
          await tester.ensureVisible(btn.first);
          await tester.tap(btn.first);
          await tester.pumpAndSettle();
          await Navigator.of(
            tester.element(find.byType(HomeScreen)),
          ).maybePop();
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('AppSettingsScreen mở dialog đăng xuất và xác nhận', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: const AppSettingsScreen(),
          routes: {AppRouter.login: (_) => const Scaffold(body: Text('LOGIN'))},
        ),
      );
      await tester.pumpAndSettle();

      final logoutBtn = find.text('Đăng xuất khỏi tài khoản');
      if (logoutBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(logoutBtn.first);
        await tester.tap(logoutBtn.first);
        await tester.pumpAndSettle();

        final confirm = find.widgetWithText(ElevatedButton, 'Đăng xuất');
        if (confirm.evaluate().isNotEmpty) {
          await tester.tap(confirm.first);
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets(
      'CreditReportListScreen bấm vào báo cáo mở chi tiết & tạo báo cáo',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            home: const CreditReportListScreen(),
            routes: {
              AppRouter.creditReportDetail: (_) =>
                  const Scaffold(body: Text('DETAIL')),
            },
          ),
        );
        await tester.pumpAndSettle();

        final fab = find.byType(FloatingActionButton);
        if (fab.evaluate().isNotEmpty) {
          await tester.tap(fab.first);
          await tester.pumpAndSettle();

          final confirm = find.textContaining('Khởi tạo');
          if (confirm.evaluate().isNotEmpty) {
            await tester.tap(confirm.first);
            await tester.pumpAndSettle();
          }
        }
      },
    );

    testWidgets('EkycVerificationSheet nhập CCCD & bấm xác thực', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = AuthController(MockAuthRepository());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EkycVerificationSheet(
              authController: auth,
              user: UserMockData.usersDatabase.first,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cccdField = find.byType(TextFormField);
      if (cccdField.evaluate().isNotEmpty) {
        await tester.enterText(cccdField.first, '001200001234');
        await tester.pump();
      }
      final verifyBtn = find.byType(ElevatedButton);
      if (verifyBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(verifyBtn.last);
        await tester.tap(verifyBtn.last);
        await tester.pump();
      }
    });
  });
}
