import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/controllers/payment_schedule_controller.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/models/loan_model.dart';
import 'package:my_first_app/models/user_model.dart';
import 'package:my_first_app/repositories/mock/mock_loan_repository.dart';
import 'package:my_first_app/screens/credit/credit_health_screen.dart';
import 'package:my_first_app/screens/home/home_screen.dart';
import 'package:my_first_app/screens/loans/loan_form_screen.dart';
import 'package:my_first_app/screens/loans/loan_list_screen.dart';
import 'package:my_first_app/screens/main_shell_screen.dart';
import 'package:my_first_app/screens/schedule/payment_schedule_screen.dart';
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

    testWidgets(
      '7. Không hiển thị thông báo hoàn tất hồ sơ khi người dùng đã đủ CCCD và thu nhập',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.byType(ProfileCompletionNotice), findsNothing);
        expect(find.text('Chưa đủ điều kiện tạo khoản vay'), findsNothing);
      },
    );

    testWidgets(
      '8. Hiển thị màn hình Yêu cầu hoàn tất hồ sơ toàn trang trên Trang chủ khi thiếu eKYC CCCD',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final incompleteUser = UserModel(
          userId: 2,
          fullName: 'Nguyen Van Moi',
          email: 'moi@test.com',
          phone: '0900000002',
          passwordHash: '123456',
          monthlyIncome: 20000000.0,
          dateOfBirth: DateTime(1999, 1, 1),
          idCardNumber: null,
          address: 'Hà Nội',
          isEkycVerified: false,
        );
        sl<AuthController>().setCurrentUser(incompleteUser);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.byType(ProfileCompletionScaffold), findsOneWidget);
        expect(find.byType(HomeHeroCard), findsNothing);
        expect(find.text('Yêu cầu hoàn tất hồ sơ'), findsOneWidget);
        expect(find.text('Chưa đủ điều kiện tạo khoản vay'), findsOneWidget);
        expect(
          find.text('Xác thực định danh eKYC (chụp 2 mặt CCCD gắn chip)'),
          findsOneWidget,
        );
        expect(find.text('Số CCCD gắn chip (12 chữ số)'), findsOneWidget);
        expect(find.text('Đi tới Hồ sơ cá nhân'), findsOneWidget);
      },
    );

    testWidgets(
      '9. Hiển thị thông báo và tự ẩn khi người dùng bổ sung thu nhập hàng tháng',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final missingIncomeUser = UserMockData.usersDatabase.first.copyWith(
          monthlyIncome: 0,
        );
        sl<AuthController>().setCurrentUser(missingIncomeUser);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.byType(ProfileCompletionScaffold), findsOneWidget);
        expect(find.byType(HomeHeroCard), findsNothing);
        expect(find.text('Thu nhập ròng hàng tháng'), findsOneWidget);

        // Cập nhật đủ thu nhập -> thông báo tự động biến mất và hiện lại HomeHeroCard
        sl<AuthController>().setCurrentUser(UserMockData.usersDatabase.first);
        await tester.pumpAndSettle();

        expect(find.byType(ProfileCompletionScaffold), findsNothing);
        expect(find.byType(HomeHeroCard), findsOneWidget);
      },
    );

    testWidgets(
      '10. Cả 4 tab chính (Trang chủ, Khoản vay, Lịch trả nợ, Tín dụng) đều hiển thị thông báo khi thiếu hồ sơ và nút Đi tới Hồ sơ cá nhân chuyển sang tab 4',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final missingIncomeUser = UserMockData.usersDatabase.first.copyWith(
          monthlyIncome: 0,
        );
        sl<AuthController>().setCurrentUser(missingIncomeUser);

        // Kiểm tra từng màn hình riêng lẻ đều hiển thị ProfileCompletionScaffold
        await tester.pumpWidget(
          const MaterialApp(home: LoanListScreen(isTab: true)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProfileCompletionScaffold), findsOneWidget);

        await tester.pumpWidget(
          const MaterialApp(home: PaymentScheduleScreen()),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ProfileCompletionScaffold), findsOneWidget);

        await tester.pumpWidget(const MaterialApp(home: CreditHealthScreen()));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileCompletionScaffold), findsOneWidget);

        // Kiểm tra trong MainShellScreen: bấm nút trên Trang chủ chuyển sang tab Hồ sơ (index 4)
        await tester.pumpWidget(const MaterialApp(home: MainShellScreen()));
        await tester.pumpAndSettle();

        expect(
          find.byType(ProfileCompletionScaffold, skipOffstage: false),
          findsNWidgets(4),
        );
        expect(find.byType(ProfileCompletionScaffold), findsOneWidget);
        await tester.tap(find.text('Đi tới Hồ sơ cá nhân'));
        await tester.pumpAndSettle();

        final IndexedStack stack = tester.widget(find.byType(IndexedStack));
        expect(stack.index, equals(4));
      },
    );

    testWidgets(
      '11. LoanFormScreen vẫn hiển thị ProfileCompletionNotice khi thiếu thu nhập',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final missingIncomeUser = UserMockData.usersDatabase.first.copyWith(
          monthlyIncome: 0,
        );
        sl<AuthController>().setCurrentUser(missingIncomeUser);

        await tester.pumpWidget(const MaterialApp(home: LoanFormScreen()));
        await tester.pumpAndSettle();

        expect(find.byType(ProfileCompletionNotice), findsOneWidget);
        expect(find.text('Yêu cầu hoàn tất hồ sơ'), findsOneWidget);
        expect(find.text('Thu nhập ròng hàng tháng'), findsOneWidget);
      },
    );

    testWidgets('12. HomeUrgentDueBanner ẩn khi tất cả khoản vay đã tất toán', (
      WidgetTester tester,
    ) async {
      final settledOnlyController = LoanController(_AllSettledLoanRepo());
      await settledOnlyController.fetchLoans();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeUrgentDueBanner(loanController: settledOnlyController),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thanh toán'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });
  });
}

class _AllSettledLoanRepo extends MockLoanRepository {
  @override
  Future<List<LoanModel>> getLoans({
    String? keyword,
    LoanStatus? status,
    String? lender,
  }) async {
    return [
      LoanModel(
        id: 107,
        userId: 1,
        loanTypeId: 2,
        name: 'Mua nhà',
        lender: 'BIDV',
        principalAmount: 50000000,
        interestRate: 0.1,
        interestMethod: 'REDUCING_BALANCE',
        termMonths: 12,
        startDate: DateTime(2026, 1, 1),
        outstandingAmount: 0,
        earlyPaymentFeeRate: 0.02,
        status: 'SETTLED',
      ),
    ];
  }
}
