import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/credit_report_controller.dart';
import 'package:my_first_app/mock_data/credit_report_mock_data.dart';
import 'package:my_first_app/models/credit_report_model.dart';
import 'package:my_first_app/repositories/interfaces/auth_repository.dart';
import 'package:my_first_app/repositories/interfaces/credit_report_repository.dart';
import 'package:my_first_app/repositories/mock/mock_auth_repository.dart';
import 'package:my_first_app/repositories/mock/mock_credit_report_repository.dart';
import 'package:my_first_app/screens/credit_report/credit_report_detail_screen.dart';
import 'package:my_first_app/screens/credit_report/credit_report_list_screen.dart';
import 'package:my_first_app/service_locator.dart';
import 'package:my_first_app/widgets/widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCreditReportRepository mockReportRepo;
  late CreditReportController controller;

  setUp(() async {
    await resetServiceLocator(dispose: false);

    // Đặt lại dữ liệu mock về trạng thái chuẩn
    CreditReportMockData.creditReportsDatabase.clear();
    CreditReportMockData.creditReportsDatabase.addAll([
      CreditReportModel(
        id: 3,
        userId: 1,
        creditScore: 745,
        dtiRatio: 0.2850,
        ltvRatio: 0.0,
        creditUtilization: 0.32,
        onTimePaymentRate: 1.0,
        totalDebt: 43750000.0,
        overdueAmount: 0.0,
        riskLevel: 'LOW',
        reportPeriod: '2026-08',
        generatedAt: DateTime(2026, 9, 1, 8, 0),
      ),
      CreditReportModel(
        id: 2,
        userId: 1,
        creditScore: 730,
        dtiRatio: 0.3120,
        ltvRatio: 0.0,
        creditUtilization: 0.38,
        onTimePaymentRate: 1.0,
        totalDebt: 50000000.0,
        overdueAmount: 0.0,
        riskLevel: 'LOW',
        reportPeriod: '2026-07',
        generatedAt: DateTime(2026, 8, 1, 8, 0),
      ),
      CreditReportModel(
        id: 1,
        userId: 1,
        creditScore: 710,
        dtiRatio: 0.3550,
        ltvRatio: 0.0,
        creditUtilization: 0.45,
        onTimePaymentRate: 0.95,
        totalDebt: 58000000.0,
        overdueAmount: 0.0,
        riskLevel: 'MEDIUM',
        reportPeriod: '2026-06',
        generatedAt: DateTime(2026, 7, 1, 8, 0),
      ),
    ]);

    mockReportRepo = MockCreditReportRepository();
    controller = CreditReportController(mockReportRepo);

    sl.registerLazySingleton<CreditReportRepository>(() => mockReportRepo);
    sl.registerLazySingleton<CreditReportController>(() => controller);
    sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
    sl.registerLazySingleton<AuthController>(
      () => AuthController(sl<AuthRepository>()),
    );
  });

  tearDown(() async {
    await resetServiceLocator(dispose: false);
  });

  group('Tài liệu Đặc tả Luồng Nghiệp vụ: Báo cáo Tín dụng', () {
    test(
      '1. Luồng 2: Lấy danh sách báo cáo tín dụng định kỳ sắp xếp mới nhất',
      () async {
        await controller.loadReports(userId: 1);

        expect(controller.isLoading, isFalse);
        expect(controller.reports.length, equals(3));
        expect(controller.reports.first.reportPeriod, equals('2026-08'));
        expect(controller.reports.last.reportPeriod, equals('2026-06'));
        expect(controller.isEmptyState, isFalse);
      },
    );

    test('2. Luồng 3: Xem chi tiết bản ghi ảnh chụp (Snapshot)', () async {
      final success = await controller.selectReport(3, userId: 1);

      expect(success, isTrue);
      expect(controller.selectedReport, isNotNull);
      expect(controller.selectedReport?.id, equals(3));
      expect(controller.selectedReport?.creditScore, equals(745));
      expect(controller.selectedReport?.reportPeriod, equals('2026-08'));
      expect(controller.selectedReport?.totalDebt, equals(43750000.0));
      expect(controller.selectedReport?.riskLevel, equals('LOW'));
    });

    test('3. Luồng 1: Khởi tạo báo cáo tín dụng mới cho kỳ 2026-09', () async {
      await controller.loadReports(userId: 1);
      final initialCount = controller.reports.length;

      final success = await controller.generateNewReport(
        userId: 1,
        reportPeriod: '2026-09',
      );

      expect(success, isTrue);
      expect(controller.reports.length, equals(initialCount + 1));
      expect(controller.reports.first.reportPeriod, equals('2026-09'));
      expect(controller.selectedReport?.reportPeriod, equals('2026-09'));
    });

    test(
      '3b. Ngăn chặn spam trùng kỳ: Không cho phép tạo báo cáo cho kỳ đã tồn tại',
      () async {
        await controller.loadReports(userId: 1);

        // Kỳ 2026-08 đã tồn tại
        final success = await controller.generateNewReport(
          userId: 1,
          reportPeriod: '2026-08',
        );

        expect(success, isFalse);
        expect(controller.errorMessage, contains('đã tồn tại'));
      },
    );

    test('3c. Chặn lập khống báo cáo cho kỳ tương lai', () async {
      await controller.loadReports(userId: 1);

      // Kỳ 2099-12 thuộc tương lai
      final success = await controller.generateNewReport(
        userId: 1,
        reportPeriod: '2099-12',
      );

      expect(success, isFalse);
      expect(controller.errorMessage, contains('tương lai'));
    });

    test(
      '4. Luồng 4: Tính toán chuỗi xu hướng và biến động qua các kỳ',
      () async {
        await controller.loadReports(userId: 1);

        final trends = controller.trendReports;
        expect(trends.length, equals(3));
        // Sắp xếp thời gian tăng dần cho biểu đồ (06 -> 07 -> 08)
        expect(trends.first.reportPeriod, equals('2026-06'));
        expect(trends.last.reportPeriod, equals('2026-08'));

        // Biến động điểm giữa kỳ 08 (745) và kỳ 07 (730) là +15 điểm
        expect(controller.scoreDelta, equals(15));

        // Biến động dư nợ giữa kỳ 08 và kỳ 07: 43.750.000 - 50.000.000 = -6.250.000 (giảm nợ)
        expect(controller.debtDelta, equals(-6250000.0));
      },
    );

    test('5. Ngoại lệ EX-01: Chưa có báo cáo nào (Empty state)', () async {
      CreditReportMockData.creditReportsDatabase.clear();

      await controller.loadReports(userId: 1);

      expect(controller.reports.isEmpty, isTrue);
      expect(controller.isEmptyState, isTrue);
      expect(controller.exceptionCode, equals('EX-01'));
    });

    test(
      '6. Ngoại lệ EX-02: Không tìm thấy bản ghi báo cáo yêu cầu (404 Not Found)',
      () async {
        final success = await controller.selectReport(9999, userId: 1);

        expect(success, isFalse);
        expect(controller.selectedReport, isNull);
        expect(controller.exceptionCode, equals('EX-02'));
        expect(controller.errorMessage, contains('Không tìm thấy'));
      },
    );

    test(
      '7. Ngoại lệ EX-03: Báo cáo không thuộc người dùng (403 Forbidden)',
      () async {
        // Báo cáo id=3 thuộc userId=1, yêu cầu với userId=99
        final success = await controller.selectReport(3, userId: 99);

        expect(success, isFalse);
        expect(controller.selectedReport, isNull);
        expect(controller.exceptionCode, equals('EX-03'));
        expect(controller.errorMessage, contains('quyền'));
      },
    );

    test('8. Ngoại lệ EX-04: Thiếu dữ liệu nền tảng khi lập báo cáo', () async {
      mockReportRepo.shouldSimulateMissingData = true;

      final success = await controller.generateNewReport(
        userId: 1,
        reportPeriod: '2026-09',
      );

      expect(success, isFalse);
      expect(controller.exceptionCode, equals('EX-04'));
      expect(controller.errorMessage, contains('chưa đầy đủ'));
    });

    test('9. Ngoại lệ EX-05: Sự cố kết nối hoặc lỗi cơ sở dữ liệu', () async {
      mockReportRepo.shouldSimulateDatabaseError = true;

      await controller.loadReports(userId: 1);

      expect(controller.exceptionCode, equals('EX-05'));
      expect(controller.errorMessage, contains('cơ sở dữ liệu'));
    });
  });

  group('Kiểm thử giao diện Widget Báo cáo Tín dụng', () {
    testWidgets(
      'Hiển thị thẻ tóm tắt CreditReportCard đầy đủ các trường dữ liệu',
      (tester) async {
        final sample = CreditReportMockData.creditReportsDatabase.first;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CreditReportCard(report: sample, onTap: () {}),
            ),
          ),
        );

        expect(find.text('Kỳ Tháng 08/2026'), findsOneWidget);
        expect(find.text('745'), findsOneWidget);
        expect(find.text('/ 850'), findsOneWidget);
        expect(find.text('43.750.000 đ'), findsOneWidget);
        expect(find.text('Rủi ro thấp'), findsOneWidget);
      },
    );

    testWidgets('Hiển thị biểu đồ chuỗi thời gian CreditReportTrendCard', (
      tester,
    ) async {
      final trends = CreditReportMockData.creditReportsDatabase;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreditReportTrendCard(trendReports: trends.reversed.toList()),
          ),
        ),
      );

      expect(find.text('XU HƯỚNG TÍN DỤNG'), findsOneWidget);
      expect(find.text('+35 điểm'), findsOneWidget);
    });

    testWidgets('Hiển thị trạng thái trống CreditReportEmptyState khi EX-01', (
      tester,
    ) async {
      bool buttonClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreditReportEmptyState(
              onGenerateFirstReport: () => buttonClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Chưa có báo cáo tín dụng'), findsOneWidget);
      expect(find.text('Lập báo cáo kỳ hiện tại'), findsOneWidget);

      await tester.tap(find.text('Lập báo cáo kỳ hiện tại'));
      expect(buttonClicked, isTrue);
    });

    testWidgets(
      'Hiển thị chi tiết CreditReportDetailView đúng cam kết ảnh chụp lịch sử',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final sample = CreditReportMockData.creditReportsDatabase.first;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: CreditReportDetailView(report: sample)),
          ),
        );

        expect(find.text('Kỳ Tháng 08/2026'), findsOneWidget);
        expect(find.text('745'), findsOneWidget);
        expect(find.text('Tỷ lệ Nợ trên Thu nhập (DTI)'), findsOneWidget);
        expect(find.text('28.5%'), findsOneWidget);
        expect(find.text('32.0%'), findsOneWidget);
        expect(find.text('100.0%'), findsOneWidget);
        expect(find.text('43.750.000 đ'), findsOneWidget);
        expect(find.text('0 đ'), findsOneWidget);
        expect(find.textContaining('Dữ liệu ảnh chụp cố định'), findsOneWidget);
      },
    );

    testWidgets(
      'Màn hình danh sách CreditReportListScreen tải và hiển thị danh sách',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          const MaterialApp(home: CreditReportListScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Báo cáo tín dụng định kỳ'), findsOneWidget);
        expect(find.text('LỊCH SỬ CÁC KỲ BÁO CÁO ĐÃ LẬP'), findsOneWidget);
        expect(find.text('Kỳ Tháng 08/2026'), findsOneWidget);
        expect(find.text('Kỳ Tháng 07/2026'), findsOneWidget);
        expect(find.text('Kỳ Tháng 06/2026'), findsOneWidget);
      },
    );

    testWidgets(
      'Màn hình chi tiết CreditReportDetailScreen hiển thị báo cáo đã chọn',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: CreditReportDetailScreen(reportId: 3)),
        );
        await tester.pumpAndSettle();

        expect(find.text('Chi tiết báo cáo tín dụng'), findsOneWidget);
        expect(find.text('Kỳ Tháng 08/2026'), findsOneWidget);
        expect(find.text('745'), findsOneWidget);
      },
    );
  });
}
