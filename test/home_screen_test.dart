import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/controllers/payment_schedule_controller.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/screens/home/home_screen.dart';
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
    if (loanController.loans.isEmpty) {
      await loanController.fetchLoans();
    }
    final scheduleController = sl<PaymentScheduleController>();
    await scheduleController.loadSchedules(userId: 1);
    await scheduleController.loadNotifications(userId: 1);
  });

  Widget createHomeScreen() {
    return const MaterialApp(home: HomeScreen());
  }

  group('HomeScreen Widget Tests', () {
    testWidgets('1. Render đầy đủ 9 khối thành phần trên HomeScreen', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // 1. Header
      expect(find.textContaining('Chào buổi'), findsOneWidget);
      expect(find.text('Nguyen Van Dev'), findsOneWidget);
      expect(find.text('Đã xác thực CIC'), findsOneWidget);

      // 2. Hero Card
      expect(find.byType(HomeHeroCard), findsOneWidget);
      expect(find.text('TỔNG DƯ NỢ HIỆN TẠI'), findsOneWidget);

      // 3. Quick Action Grid
      expect(find.byType(HomeQuickActionGrid), findsOneWidget);
      expect(find.text('Thêm\nkhoản vay'), findsOneWidget);
      expect(find.text('Lịch trả\nnợ tới'), findsOneWidget);
      expect(find.text('Tra cứu\nCIC'), findsOneWidget);
      expect(find.text('Quét hợp\nđồng OCR'), findsOneWidget);
      expect(find.text('Máy tính\nlãi suất'), findsOneWidget);
      expect(find.text('Mô phỏng\ntrả nợ'), findsOneWidget);
      expect(find.text('Tối ưu\ntrả nợ'), findsOneWidget);
      expect(find.text('Báo cáo\nDTI'), findsOneWidget);

      // 4. Urgent Due Banner
      expect(find.byType(HomeUrgentDueBanner), findsOneWidget);

      // 5. Active Loans Slider
      expect(find.byType(HomeActiveLoansSlider), findsOneWidget);

      // 6. DTI Gauge Card
      expect(find.byType(HomeDtiGaugeCard), findsOneWidget);
      expect(find.text('Chỉ số gánh nặng nợ (DTI)'), findsOneWidget);

      // 7. Cashflow Projection Card
      expect(find.byType(HomeCashflowProjectionCard), findsOneWidget);
      expect(find.text('Dự phóng dòng tiền trả nợ (6 tháng)'), findsOneWidget);

      // 8. Education Carousel
      expect(find.byType(HomeEducationCarousel), findsOneWidget);
      expect(find.text('Cẩm nang tài chính & Tín dụng'), findsOneWidget);

      // 9. Security Footer
      expect(find.byType(HomeSecurityFooter), findsOneWidget);
      expect(find.text('FinCredit Security Standard'), findsOneWidget);
    });

    testWidgets('2. Tương tác ẩn / hiện số dư trên HomeHeroCard', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Ban đầu số dư hiển thị, không có chuỗi che số
      expect(find.text('•••••••• đ'), findsNothing);
      expect(find.text('Ẩn'), findsOneWidget);

      // Tap để ẩn số dư
      await tester.tap(find.text('Ẩn'));
      await tester.pumpAndSettle();

      // Kiểm tra số dư đã bị che
      expect(find.text('•••••••• đ'), findsOneWidget);
      expect(find.text('Hiện'), findsOneWidget);

      // Tap lại để hiện số dư
      await tester.tap(find.text('Hiện'));
      await tester.pumpAndSettle();

      // Số dư được hiện lại
      expect(find.text('•••••••• đ'), findsNothing);
      expect(find.text('Ẩn'), findsOneWidget);
    });

    testWidgets('3. Mở và đóng modal CSKH từ AppBar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      final supportIcon = find.byTooltip('Trợ giúp & CSKH');
      expect(supportIcon, findsOneWidget);
      await tester.tap(supportIcon);
      await tester.pumpAndSettle();

      // Kiểm tra modal hỗ trợ khách hàng xuất hiện
      expect(find.text('Hỗ trợ khách hàng 24/7'), findsOneWidget);
      expect(find.text('1900 6868 (Miễn phí)'), findsOneWidget);
      expect(find.text('support@fincredit.vn'), findsOneWidget);

      // Đóng modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Hỗ trợ khách hàng 24/7'), findsNothing);
    });

    testWidgets('4. Mở hộp thoại Tính lãi nhanh từ QuickActionGrid', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Máy tính\nlãi suất'));
      await tester.pumpAndSettle();

      expect(find.text('Máy tính lãi suất nhanh'), findsOneWidget);
      expect(find.text('Ước tính trả hàng tháng:'), findsOneWidget);

      // Đóng dialog
      await tester.tap(find.text('Đóng'));
      await tester.pumpAndSettle();
      expect(find.text('Máy tính lãi suất nhanh'), findsNothing);
    });

    testWidgets('5. Mở Báo cáo DTI từ QuickActionGrid và từ HomeDtiGaugeCard', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createHomeScreen());
      await tester.pumpAndSettle();

      // Mở từ phím tắt Báo cáo DTI
      await tester.tap(find.text('Báo cáo\nDTI'));
      await tester.pumpAndSettle();

      expect(find.text('Báo cáo Tỷ lệ Gánh nặng Nợ (DTI)'), findsOneWidget);
      expect(
        find.text('Cân đối Thu nhập & Nghĩa vụ Hàng tháng'),
        findsOneWidget,
      );

      // Đóng modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Báo cáo Tỷ lệ Gánh nặng Nợ (DTI)'), findsNothing);
    });

    testWidgets(
      '6. Mở Lập kế hoạch trả nợ và Dòng tiền chi tiết từ HomeHeroCard',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Tap Lập kế hoạch trả
        await tester.tap(find.text('Lập kế hoạch trả'));
        await tester.pumpAndSettle();

        expect(find.text('Kế hoạch & Tối ưu Trả nợ'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Tap Thống kê dòng tiền
        await tester.tap(find.text('Thống kê dòng tiền'));
        await tester.pumpAndSettle();

        expect(find.text('Thống kê & Dự phóng Dòng tiền'), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      },
    );
  });
}
