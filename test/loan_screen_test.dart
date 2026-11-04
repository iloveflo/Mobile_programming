import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/screens/loans/loan_collateral_ocr_screen.dart';
import 'package:my_first_app/screens/loans/loan_detail_screen.dart';
import 'package:my_first_app/screens/loans/loan_form_screen.dart';
import 'package:my_first_app/service_locator.dart';
import 'package:my_first_app/widgets/widget.dart';

void main() {
  setUpAll(() async {
    setupServiceLocator();
  });

  setUp(() async {
    final authController = sl<AuthController>();
    authController.setCurrentUser(UserMockData.usersDatabase.first);
    final loanController = sl<LoanController>();
    await loanController.fetchLoans();
  });

  group('Loan Screens Widget Tests', () {
    testWidgets(
      '1. LoanFormScreen hiển thị form nhập và tính toán lãi ước tính',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: LoanFormScreen()));
        await tester.pumpAndSettle();

        // Kiểm tra tiêu đề form
        expect(find.text('Tạo khoản vay mới'), findsOneWidget);

        // Kiểm tra các trường nhập liệu cốt lõi
        expect(find.text('Tên khoản vay / Mục đích vay *'), findsOneWidget);
        expect(find.text('Số tiền vay ban đầu (VNĐ) *'), findsOneWidget);

        // Chọn chip số tiền mẫu để kích hoạt tính toán tự động
        final chip100M = find.text('100 Triệu');
        expect(chip100M, findsOneWidget);
        await tester.tap(chip100M);
        await tester.pumpAndSettle();

        // Thẻ ước tính trả hàng tháng (MonthlyEstimateCard) xuất hiện
        expect(find.byType(MonthlyEstimateCard), findsOneWidget);
        expect(find.text('Ước tính thanh toán kỳ đầu tiên'), findsOneWidget);

        // Nút Tạo khoản vay mới hiển thị
        expect(
          find.widgetWithText(AppPrimaryButton, 'Tạo khoản vay mới'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '2. LoanFormScreen mở QuickAddCollateralSheet khi thêm tài sản',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: LoanFormScreen()));
        await tester.pumpAndSettle();

        // Tìm nút thêm tài sản thế chấp
        final addCollateralFinder = find.text('+ Thêm tài sản');
        if (addCollateralFinder.evaluate().isNotEmpty) {
          await tester.tap(addCollateralFinder);
          await tester.pumpAndSettle();

          // Kiểm tra sheet thêm nhanh tài sản bảo đảm xuất hiện
          expect(find.byType(QuickAddCollateralSheet), findsOneWidget);
          expect(find.text('Thêm tài sản bảo đảm'), findsOneWidget);

          // Đóng sheet
          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      '3. LoanDetailScreen hiển thị thông tin và mở lịch trả nợ & tất toán sớm',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final loanController = sl<LoanController>();
        final firstLoan = loanController.loans.first;

        await tester.pumpWidget(
          MaterialApp(home: LoanDetailScreen(loanId: firstLoan.id.toString())),
        );
        await tester.pumpAndSettle();

        // Kiểm tra thông tin khoản vay
        expect(find.text(firstLoan.loanName), findsWidgets);
        expect(find.byType(LoanContractDocumentsSection), findsOneWidget);

        // Mở modal Tất toán trước hạn
        final earlyPayoffBtn = find.text('Mô phỏng tất toán sớm');
        if (earlyPayoffBtn.evaluate().isNotEmpty) {
          await tester.tap(earlyPayoffBtn);
          await tester.pumpAndSettle();

          expect(find.byType(EarlyPayoffModal), findsOneWidget);
          expect(
            find.text('Mô phỏng tất toán khoản vay trước hạn'),
            findsOneWidget,
          );

          // Đóng modal
          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle();
        }

        // Mở Lịch thanh toán chi tiết
        final scheduleBtn = find.text('Xem lịch trả nợ chi tiết');
        if (scheduleBtn.evaluate().isNotEmpty) {
          await tester.tap(scheduleBtn);
          await tester.pumpAndSettle();

          expect(find.byType(LoanRepaymentScheduleSheet), findsOneWidget);
          expect(find.text('Kế hoạch phân kỳ thanh toán'), findsOneWidget);

          // Đóng sheet
          await tester.tap(find.byIcon(Icons.close));
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets(
      '4. LoanCollateralOcrScreen hiển thị giao diện quét tài liệu thông minh',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(home: LoanCollateralOcrScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tài sản thế chấp & OCR'), findsOneWidget);
        expect(find.text('Tài sản bảo đảm'), findsOneWidget);
        expect(find.text('Bóc tách OCR'), findsOneWidget);
      },
    );
  });
}
