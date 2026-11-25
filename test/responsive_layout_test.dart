import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/controllers/payment_schedule_controller.dart';
import 'package:my_first_app/layout/responsive_layout.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/models/notification_preference_model.dart';
import 'package:my_first_app/models/payment_schedule_model.dart';
import 'package:my_first_app/models/simulation_model.dart';
import 'package:my_first_app/screens/auth/login_screen.dart';
import 'package:my_first_app/screens/auth/otp_verification_screen.dart';
import 'package:my_first_app/screens/auth/register_screen.dart';
import 'package:my_first_app/screens/auth/reset_password_screen.dart';
import 'package:my_first_app/screens/auth/reset_success_dialog.dart';
import 'package:my_first_app/screens/credit/credit_health_screen.dart';
import 'package:my_first_app/screens/credit_report/credit_report_detail_screen.dart';
import 'package:my_first_app/screens/credit_report/credit_report_list_screen.dart';
import 'package:my_first_app/screens/debt/debt_strategy_screen.dart';
import 'package:my_first_app/screens/home/home_screen.dart';
import 'package:my_first_app/screens/loans/loan_collateral_ocr_screen.dart';
import 'package:my_first_app/screens/loans/loan_detail_screen.dart';
import 'package:my_first_app/screens/loans/loan_form_screen.dart';
import 'package:my_first_app/screens/loans/loan_list_screen.dart';
import 'package:my_first_app/screens/main_shell_screen.dart';
import 'package:my_first_app/widgets/common/connection_error_view.dart';
import 'package:my_first_app/widgets/credit_report/credit_report_empty_state.dart';
import 'package:my_first_app/widgets/schedule/schedule_empty_state.dart';
import 'package:my_first_app/screens/profile/profile_screen.dart';
import 'package:my_first_app/screens/schedule/payment_schedule_screen.dart';
import 'package:my_first_app/screens/settings/app_settings_screen.dart';
import 'package:my_first_app/screens/simulation/simulation_screen.dart';
import 'package:my_first_app/service_locator.dart';
import 'package:my_first_app/services/image_upload_service.dart';
import 'package:my_first_app/widgets/common/custom_bottom_nav_bar.dart';
import 'package:my_first_app/widgets/credit/credit_factor_sheet.dart';
import 'package:my_first_app/widgets/home/article_detail_modal.dart';
import 'package:my_first_app/widgets/home/customer_support_modal.dart';
import 'package:my_first_app/widgets/home/debt_planning_sheet.dart';
import 'package:my_first_app/widgets/loans/early_payoff_modal.dart';
import 'package:my_first_app/widgets/schedule/notification_preference_sheet.dart';
import 'package:my_first_app/widgets/schedule/schedule_detail_sheet.dart';
import 'package:my_first_app/widgets/simulation/simulation_scenario_selector.dart';

class _ScreenProfile {
  final String name;
  final Size size;
  final double textScale;

  const _ScreenProfile(this.name, this.size, this.textScale);
}

const List<_ScreenProfile> _profiles = [
  _ScreenProfile('320x568 + scale 1.25', Size(320, 568), 1.25),
  _ScreenProfile('390x844 + scale 1.0', Size(390, 844), 1.0),
  _ScreenProfile('768x1024 + scale 1.15', Size(768, 1024), 1.15),
  _ScreenProfile('844x390 landscape + scale 1.0', Size(844, 390), 1.0),
  _ScreenProfile('568x320 landscape + scale 1.15', Size(568, 320), 1.15),
];

const List<_ScreenProfile> _landscapeProfiles = [
  _ScreenProfile('844x390 landscape + scale 1.0', Size(844, 390), 1.0),
  _ScreenProfile('568x320 landscape + scale 1.15', Size(568, 320), 1.15),
];

Future<void> _pumpAtProfile(
  WidgetTester tester,
  _ScreenProfile profile,
  Widget child,
) async {
  tester.view.physicalSize = profile.size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final List<String> capturedErrors = [];
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    final text = details.toString();
    final match = RegExp(
      r'file:///home/iloveflo/Documents/Mobile_Programming/(my_first_app/lib/[^\s]+)',
    ).firstMatch(text);
    capturedErrors.add(
      '${details.exceptionAsString()} @ ${match?.group(1) ?? "unknown"}',
    );
    previousOnError?.call(details);
  };
  addTearDown(() => FlutterError.onError = previousOnError);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, innerChild) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            profile.textScale,
          ).clamp(minScaleFactor: 0.9, maxScaleFactor: 1.25),
        ),
        child: innerChild ?? const SizedBox.shrink(),
      ),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
  if (capturedErrors.isNotEmpty) {
    debugPrint('OVERFLOWS [${profile.name}]: ${capturedErrors.join(" | ")}');
  }
}

void main() {
  setUpAll(() {
    setupServiceLocator();
  });

  setUp(() async {
    sl<AuthController>().setCurrentUser(UserMockData.usersDatabase.first);
    final loanController = sl<LoanController>();
    if (loanController.loans.isEmpty) {
      await loanController.fetchLoans();
    }
    final scheduleController = sl<PaymentScheduleController>();
    await scheduleController.loadSchedules(userId: 1);
    await scheduleController.loadNotifications(userId: 1);
  });

  group('Responsive Layout Helpers Tests', () {
    testWidgets(
      'ResponsiveTwoColumnGrid chuyển từ 2 cột sang 1 cột khi hẹp hơn breakpoint',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 280,
                child: ResponsiveTwoColumnGrid(
                  singleColumnBreakpoint: 310,
                  children: [Text('Ô 1'), Text('Ô 2')],
                ),
              ),
            ),
          ),
        );

        final pos1 = tester.getTopLeft(find.text('Ô 1'));
        final pos2 = tester.getTopLeft(find.text('Ô 2'));
        expect(pos2.dy, greaterThan(pos1.dy));
      },
    );

    testWidgets(
      'ResponsiveContentConstraint giới hạn chiều rộng tối đa trên màn hình lớn',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 900,
                child: ResponsiveContentConstraint(
                  maxWidth: 600,
                  child: SizedBox(
                    key: Key('content'),
                    width: double.infinity,
                    height: 40,
                  ),
                ),
              ),
            ),
          ),
        );

        final size = tester.getSize(find.byKey(const Key('content')));
        expect(size.width, equals(600));
      },
    );

    testWidgets('ResponsiveTextScaler.clamp giữ tỷ lệ chữ trong [0.9, 1.25]', (
      tester,
    ) async {
      late TextScaler clampedHigh;
      late TextScaler clampedLow;

      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
                child: Builder(
                  builder: (ctx) {
                    clampedHigh = ResponsiveTextScaler.clamp(ctx);
                    return const SizedBox.shrink();
                  },
                ),
              ),
              MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
                child: Builder(
                  builder: (ctx) {
                    clampedLow = ResponsiveTextScaler.clamp(ctx);
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(clampedHigh.scale(10), equals(12.5));
      expect(clampedLow.scale(10), equals(9.0));
    });
  });

  group('Multi-Device Responsive Overflow Matrix', () {
    for (final profile in _profiles) {
      testWidgets(
        'CustomBottomNavBar & SimulationScenarioSelector [${profile.name}]',
        (tester) async {
          await _pumpAtProfile(
            tester,
            profile,
            Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: SimulationScenarioSelector(
                  selectedScenario: SimulationScenarioType.changeInterestRate,
                  onScenarioChanged: (_) {},
                ),
              ),
              bottomNavigationBar: CustomBottomNavBar(
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('HomeScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const HomeScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('LoanListScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const LoanListScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('PaymentScheduleScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const PaymentScheduleScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('CreditHealthScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const CreditHealthScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('CreditReportListScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const CreditReportListScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('SimulationScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const SimulationScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('DebtStrategyScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const DebtStrategyScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('ProfileScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const ProfileScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('AppSettingsScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const AppSettingsScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('LoginScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const LoginScreen());
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Landscape Modals & BottomSheets Overflow Matrix', () {
    for (final profile in _landscapeProfiles) {
      testWidgets('CreditFactorSheet [${profile.name}]', (tester) async {
        await _pumpAtProfile(
          tester,
          profile,
          const Scaffold(
            body: CreditFactorSheet(
              title: 'Tỷ lệ Vay / Tài sản (LTV)',
              currentValue: '80.0%',
              formulaExplanation:
                  'Tỷ lệ giữa tổng số tiền vay thế chấp so với giá trị định giá của tài sản bảo đảm.\n• Dưới 70%: Mức đòn bẩy an toàn.\n• 70% - 85%: Cần theo dõi.\n• Trên 85%: Nguy cơ thiếu hụt.',
              sourceDescription:
                  'Tổng hợp từ số dư nợ của các khoản vay có thế chấp và chứng thư định giá tài sản bảo đảm được ghi nhận.',
              icon: Icons.apartment_rounded,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('CustomerSupportModal [${profile.name}]', (tester) async {
        await _pumpAtProfile(
          tester,
          profile,
          const Scaffold(body: CustomerSupportModal()),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('DebtPlanningSheet [${profile.name}]', (tester) async {
        await _pumpAtProfile(
          tester,
          profile,
          const Scaffold(body: DebtPlanningSheet()),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('ArticleDetailModal [${profile.name}]', (tester) async {
        await _pumpAtProfile(
          tester,
          profile,
          const Scaffold(
            body: ArticleDetailModal(
              title: 'Cách tối ưu tỷ lệ DTI an toàn dưới 40%',
              summary:
                  'Duy trì tỷ lệ nghĩa vụ trả nợ trên thu nhập hàng tháng ở mức hợp lý giúp bảo vệ điểm tín dụng và khả năng vay vốn trong tương lai.',
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('EarlyPayoffModal [${profile.name}]', (tester) async {
        final loanController = sl<LoanController>();
        final loan = loanController.loans.first;
        await _pumpAtProfile(
          tester,
          profile,
          Scaffold(
            body: EarlyPayoffModal(loan: loan, loanController: loanController),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('ScheduleDetailSheet [${profile.name}]', (tester) async {
        final schedule = PaymentScheduleModel(
          id: 1,
          loanId: 1,
          installmentNumber: 4,
          dueDate: DateTime(2026, 12, 10),
          principalAmount: 2000000,
          interestAmount: 630208,
          feeAmount: 0,
          totalAmount: 2630208,
          remainingBalance: 50000000,
          status: 'UPCOMING',
        );
        await _pumpAtProfile(
          tester,
          profile,
          Scaffold(
            body: ScheduleDetailSheet(
              schedule: schedule,
              loanName: 'Vay mua xe VinFast VF8',
              onPay: () {},
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('NotificationPreferenceSheet [${profile.name}]', (
        tester,
      ) async {
        const pref = NotificationPreferenceModel(
          id: 1,
          userId: 1,
          pushEnabled: true,
          emailEnabled: true,
          reminderDays: 3,
        );
        await _pumpAtProfile(
          tester,
          profile,
          Scaffold(
            body: NotificationPreferenceSheet(
              currentPreference: pref,
              userEmail: 'test@fincredit.vn',
              onSave: (_) async => true,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('ResetSuccessDialog [${profile.name}]', (tester) async {
        await _pumpAtProfile(
          tester,
          profile,
          const Scaffold(body: ResetSuccessDialog()),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('ImageUploadService.showSourceSelector [${profile.name}]', (
        tester,
      ) async {
        await _pumpAtProfile(
          tester,
          profile,
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => sl<ImageUploadService>().showSourceSelector(
                    context,
                    title: 'Chụp / Chọn Giấy tờ pháp lý tài sản',
                  ),
                  child: const Text('Mở chọn ảnh'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Mở chọn ảnh'));
        await tester.pumpAndSettle();
        expect(find.text('Chụp ảnh trực tiếp bằng Camera'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Remaining Screens Responsive Matrix', () {
    const extremeProfiles = [
      _ScreenProfile('320x568 + scale 1.25', Size(320, 568), 1.25),
      _ScreenProfile('568x320 landscape + scale 1.15', Size(568, 320), 1.15),
    ];

    for (final profile in extremeProfiles) {
      testWidgets('OtpVerificationScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(
          tester,
          profile,
          const OtpVerificationScreen(email: 'user@fincredit.vn'),
        );
        expect(tester.takeException(), isNull);
        sl<AuthController>().cancelOtpTimer();
        await tester.pumpWidget(const SizedBox.shrink());
      });

      testWidgets('RegisterScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const RegisterScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('ResetPasswordScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const ResetPasswordScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('CreditReportDetailScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(
          tester,
          profile,
          const CreditReportDetailScreen(reportId: 3),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('LoanCollateralOcrScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const LoanCollateralOcrScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('LoanDetailScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(
          tester,
          profile,
          const LoanDetailScreen(loanId: '1'),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('LoanFormScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const LoanFormScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('MainShellScreen [${profile.name}]', (tester) async {
        await _pumpAtProfile(tester, profile, const MainShellScreen());
        expect(tester.takeException(), isNull);
      });

      testWidgets('ScheduleEmptyState [${profile.name}]', (tester) async {
        await _pumpAtProfile(
          tester,
          profile,
          Scaffold(body: ScheduleEmptyState(onAddLoan: () {})),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('CreditReportEmptyState [${profile.name}]', (tester) async {
        await _pumpAtProfile(
          tester,
          profile,
          Scaffold(body: CreditReportEmptyState(onGenerateFirstReport: () {})),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('ConnectionErrorView [${profile.name}]', (tester) async {
        await _pumpAtProfile(
          tester,
          profile,
          Scaffold(body: ConnectionErrorView(onRetry: () {})),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
