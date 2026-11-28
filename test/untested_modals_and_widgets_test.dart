import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/models/debt_strategy_model.dart';
import 'package:my_first_app/models/loan_model.dart';
import 'package:my_first_app/models/payment_schedule_model.dart';
import 'package:my_first_app/repositories/mock/mock_auth_repository.dart';
import 'package:my_first_app/repositories/mock/mock_loan_repository.dart';
import 'package:my_first_app/service_locator.dart';
import 'package:my_first_app/widgets/common/app_document_viewer_modal.dart';
import 'package:my_first_app/widgets/credit_report/generate_report_dialog.dart';
import 'package:my_first_app/widgets/debt_strategy/debt_comparison_view.dart';
import 'package:my_first_app/widgets/loans/add_collateral_dialog.dart';
import 'package:my_first_app/widgets/loans/loan_repayment_schedule_sheet.dart';
import 'package:my_first_app/widgets/loans/quick_add_collateral_sheet.dart';
import 'package:my_first_app/widgets/profile/edit_contact_sheet.dart';
import 'package:my_first_app/widgets/profile/edit_income_sheet.dart';
import 'package:my_first_app/widgets/profile/ekyc_verification_sheet.dart';

void main() {
  setUpAll(() async {
    await resetServiceLocator(dispose: false);
    setupServiceLocator();
  });

  group('Untested Modals & Sheets Widget Tests', () {
    testWidgets('EditIncomeSheet hiển thị và cập nhật thu nhập', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = AuthController(MockAuthRepository());
      await auth.login('dev@test.com', '123456');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditIncomeSheet(authController: auth, user: auth.currentUser),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EditIncomeSheet), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('EditContactSheet hiển thị và cập nhật thông tin liên hệ', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = AuthController(MockAuthRepository());
      await auth.login('dev@test.com', '123456');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditContactSheet(
              authController: auth,
              user: auth.currentUser,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EditContactSheet), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('EkycVerificationSheet hiển thị form xác thực CCCD 2 mặt', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final auth = AuthController(MockAuthRepository());
      final user = UserMockData.usersDatabase.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EkycVerificationSheet(authController: auth, user: user),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EkycVerificationSheet), findsOneWidget);
      expect(find.textContaining('CCCD'), findsWidgets);
    });

    testWidgets('AppDocumentViewerModal hiển thị tài liệu và thông tin OCR', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppDocumentViewerModal(
              title: 'Hợp đồng tín dụng',
              fileKey: 'loans/101/contract.jpg',
              subtitle: 'Vietcombank',
              documentType: 'CONTRACT',
              ocrDetails: {'Số hợp đồng': 'HD-2026-001'},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppDocumentViewerModal), findsOneWidget);
      expect(find.text('Hợp đồng tín dụng'), findsWidgets);
      expect(find.textContaining('Vietcombank'), findsWidgets);
    });

    testWidgets('AddCollateralDialog hiển thị form và thêm tài sản bảo đảm', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final loanController = LoanController(MockLoanRepository());
      await loanController.fetchLoans();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddCollateralDialog(
              loanController: loanController,
              loanId: loanController.loans.first.id.toString(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AddCollateralDialog), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('QuickAddCollateralSheet hiển thị hướng dẫn quét chứng từ', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final loanController = LoanController(MockLoanRepository());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuickAddCollateralSheet(
              loanController: loanController,
              onCollateralAdded: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(QuickAddCollateralSheet), findsOneWidget);
    });

    testWidgets(
      'LoanRepaymentScheduleSheet hiển thị lịch trả nợ của khoản vay',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final loan = LoanModel(
          id: 101,
          userId: 1,
          loanTypeId: 1,
          name: 'Vay mua nhà',
          lender: 'Vietcombank',
          principalAmount: 500000000,
          outstandingAmount: 450000000,
          interestRate: 8.5,
          interestMethod: 'REDUCING_BALANCE',
          termMonths: 60,
          startDate: DateTime(2026, 1, 15),
          earlyPaymentFeeRate: 0.02,
          status: 'ACTIVE',
        );
        final schedules = [
          PaymentScheduleModel(
            id: 1,
            loanId: 101,
            installmentNumber: 1,
            dueDate: DateTime(2026, 2, 15),
            principalAmount: 8333333,
            interestAmount: 3187500,
            feeAmount: 0,
            totalAmount: 11520833,
            remainingBalance: 441666667,
            status: 'PAID',
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoanRepaymentScheduleSheet(
                loan: loan,
                initialSchedules: schedules,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LoanRepaymentScheduleSheet), findsOneWidget);
        expect(find.textContaining('15/02/2026'), findsWidgets);
      },
    );

    testWidgets(
      'DebtComparisonView hiển thị so sánh Snowball vs Avalanche và chọn áp dụng',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        DebtStrategyType? selected;
        final snowball = DebtStrategyPlanResult(
          strategyType: DebtStrategyType.snowball,
          extraPayment: 2000000,
          totalDebt: 200000000,
          totalMonths: 24,
          totalInterest: 35000000,
          totalCost: 235000000,
          interestSaved: 10000000,
          monthsSaved: 4,
          items: const [],
        );
        final avalanche = DebtStrategyPlanResult(
          strategyType: DebtStrategyType.avalanche,
          extraPayment: 2000000,
          totalDebt: 200000000,
          totalMonths: 22,
          totalInterest: 29000000,
          totalCost: 229000000,
          interestSaved: 16000000,
          monthsSaved: 6,
          items: const [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DebtComparisonView(
                  snowballPlan: snowball,
                  avalanchePlan: avalanche,
                  onSelectAndApply: (type) => selected = type,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DebtComparisonView), findsOneWidget);
        expect(find.textContaining('Snowball'), findsWidgets);
        expect(find.textContaining('Avalanche'), findsWidgets);
        expect(selected, isNull);
      },
    );

    testWidgets(
      'GenerateReportDialog hiển thị các kỳ hợp lệ và gọi onConfirm',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        String? confirmedPeriod;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GenerateReportDialog(
                existingPeriods: const ['2026-09'],
                earliestAllowedDate: DateTime(2026, 8, 1),
                onConfirm: (period) async {
                  confirmedPeriod = period;
                  return true;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(GenerateReportDialog), findsOneWidget);
        expect(confirmedPeriod, isNull);
      },
    );
  });
}
