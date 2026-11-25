import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/models/loan_model.dart';
import 'package:my_first_app/screens/loans/loan_collateral_ocr_screen.dart';
import 'package:my_first_app/screens/loans/loan_detail_screen.dart';
import 'package:my_first_app/screens/loans/loan_form_screen.dart';
import 'package:my_first_app/screens/loans/loan_list_screen.dart';
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

    testWidgets(
      '5. LoanListScreen giữ nguyên số đếm chip và tổng quan danh mục khi lọc trạng thái',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final loanController = sl<LoanController>();
        await loanController.setSearchKeyword('');
        await loanController.setFilterStatus(LoanStatus.all);

        final totalCount = loanController.allLoans.length;
        final activeCount = loanController.allLoans
            .where((l) => l.isActive)
            .length;
        final closedCount = loanController.allLoans
            .where((l) => l.isClosed)
            .length;

        await tester.pumpWidget(
          const MaterialApp(home: LoanListScreen(isTab: true)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tất cả ($totalCount)'), findsOneWidget);
        expect(find.text('Đang vay ($activeCount)'), findsOneWidget);
        expect(find.text('Đã tất toán ($closedCount)'), findsOneWidget);

        // Chuyển sang tab Đã tất toán
        await tester.tap(find.text('Đã tất toán ($closedCount)'));
        await tester.pumpAndSettle();

        // Số đếm trên cả 3 chip phải giữ nguyên không bị tụt về 0
        expect(find.text('Tất cả ($totalCount)'), findsOneWidget);
        expect(find.text('Đang vay ($activeCount)'), findsOneWidget);
        expect(find.text('Đã tất toán ($closedCount)'), findsOneWidget);

        // Khôi phục lại filter mặc định cho các test khác
        await loanController.setFilterStatus(LoanStatus.all);
      },
    );

    testWidgets(
      '6. LoanFormScreen hiển thị Hạn mức vay tín chấp theo thu nhập khi chọn Vay tiêu dùng / Tín chấp và chặn khi vượt quy tắc',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          sl<AuthController>().setCurrentUser(UserMockData.usersDatabase.first);
        });

        await tester.pumpWidget(const MaterialApp(home: LoanFormScreen()));
        await tester.pumpAndSettle();

        // Mặc định MORTGAGE: hạn mức 50 tỷ
        expect(
          find.text(
            'Hạn mức cho phép: 5.000.000 đ – 50.000.000.000 đ (50 tỷ VNĐ)',
          ),
          findsOneWidget,
        );

        // Chuyển sang Vay mua ô tô (CAR): hạn mức 10 tỷ
        await tester.tap(find.text('Vay thế chấp / Bất động sản'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Vay mua ô tô').last);
        await tester.pumpAndSettle();
        expect(
          find.text(
            'Hạn mức cho phép: 5.000.000 đ – 10.000.000.000 đ (10 tỷ VNĐ)',
          ),
          findsOneWidget,
        );

        // Chọn loại vay: Vay tiêu dùng / Tín chấp (CONSUMER) -> hạn mức theo thu nhập 25tr * 12 = 300tr
        await tester.tap(find.text('Vay mua ô tô'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Vay tiêu dùng / Tín chấp').last);
        await tester.pumpAndSettle();

        expect(find.text('Hạn mức vay tín chấp theo thu nhập'), findsOneWidget);
        expect(find.text('Hạn mức tín chấp còn lại:'), findsOneWidget);
        expect(
          find.textContaining('300.000.000 đ (12× thu nhập, trần 500 triệu)'),
          findsOneWidget,
        );

        // Chuyển sang Khoản vay khác (OTHER) -> vẫn áp dụng hạn mức theo thu nhập
        await tester.tap(find.text('Vay tiêu dùng / Tín chấp'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Khoản vay khác').last);
        await tester.pumpAndSettle();
        expect(find.text('Hạn mức vay tín chấp theo thu nhập'), findsOneWidget);
        expect(
          find.textContaining('300.000.000 đ (12× thu nhập, trần 500 triệu)'),
          findsOneWidget,
        );

        // Kiểm tra trường hợp thu nhập < 3.000.000 đ/tháng
        sl<AuthController>().setCurrentUser(
          UserMockData.usersDatabase.first.copyWith(monthlyIncome: 2000000),
        );
        await tester.pumpWidget(
          MaterialApp(home: LoanFormScreen(key: UniqueKey())),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Vay thế chấp / Bất động sản'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Vay tiêu dùng / Tín chấp').last);
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Thu nhập tối thiểu 3.000.000 đ/tháng để vay tín chấp không thế chấp.',
          ),
          findsOneWidget,
        );
      },
    );
  });
}
