import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/credit_profile_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/models/loan_model.dart';
import 'package:my_first_app/repositories/interfaces/auth_repository.dart';
import 'package:my_first_app/repositories/interfaces/credit_profile_repository.dart';
import 'package:my_first_app/repositories/interfaces/loan_repository.dart';
import 'package:my_first_app/repositories/mock/mock_auth_repository.dart';
import 'package:my_first_app/repositories/mock/mock_credit_profile_repository.dart';
import 'package:my_first_app/screens/credit/credit_health_screen.dart';
import 'package:my_first_app/service_locator.dart';
import 'package:my_first_app/widgets/credit/credit_empty_state.dart';
import 'package:my_first_app/widgets/credit/credit_factor_sheet.dart';
import 'package:my_first_app/widgets/credit/credit_metric_card.dart';
import 'package:my_first_app/widgets/credit/credit_score_gauge.dart';

class FakeLoanRepository implements LoanRepository {
  List<LoanModel> stubbedLoans = [];

  @override
  Future<List<LoanModel>> getLoans({
    String? keyword,
    LoanStatus? status,
    String? lender,
  }) async {
    return List.from(stubbedLoans);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCreditProfileRepository mockCreditRepo;
  late FakeLoanRepository fakeLoanRepo;
  late CreditProfileController controller;

  final sampleLoans = [
    LoanModel(
      id: 1,
      userId: 1,
      loanTypeId: 1,
      name: 'Vay mua nhà',
      principalAmount: 200000000,
      outstandingAmount: 180000000,
      interestRate: 0.08,
      interestMethod: 'REDUCING_BALANCE',
      termMonths: 60,
      startDate: DateTime(2025, 1, 1),
      earlyPaymentFeeRate: 0.015,
      status: 'ACTIVE',
    ),
  ];

  setUp(() async {
    await resetServiceLocator(dispose: false);
    mockCreditRepo = MockCreditProfileRepository();
    fakeLoanRepo = FakeLoanRepository();
    fakeLoanRepo.stubbedLoans = List.from(sampleLoans);
    controller = CreditProfileController(mockCreditRepo, fakeLoanRepo);

    sl.registerLazySingleton<CreditProfileRepository>(() => mockCreditRepo);
    sl.registerLazySingleton<LoanRepository>(() => fakeLoanRepo);
    sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
    sl.registerLazySingleton<AuthController>(
      () => AuthController(sl<AuthRepository>()),
    );
    sl.registerLazySingleton<LoanController>(
      () => LoanController(fakeLoanRepo),
    );
    sl.registerLazySingleton<CreditProfileController>(() => controller);
  });

  tearDown(() async {
    await resetServiceLocator(dispose: false);
  });

  group('Luồng nghiệp vụ Sức khỏe tín dụng (CreditProfileController)', () {
    test('1. Tải hồ sơ tín dụng thành công (Mục 6)', () async {
      await controller.loadCreditProfile(userId: 1);

      expect(controller.isLoading, isFalse);
      expect(controller.creditProfile, isNotNull);
      expect(controller.creditProfile?.creditScore, isNotNull);
      expect(
        controller.creditProfile?.activeLoanCount,
        greaterThanOrEqualTo(1),
      );
      expect(controller.hasLoans, isTrue);
      expect(controller.isEmptyState, isFalse);
    });

    test('2. Yêu cầu tính toán lại hồ sơ (Mục 7: Recalculate)', () async {
      await controller.loadCreditProfile(userId: 1);
      final oldScore = controller.creditProfile?.creditScore;

      final success = await controller.recalculate(userId: 1);

      expect(success, isTrue);
      expect(controller.isRecalculating, isFalse);
      expect(controller.creditProfile?.updatedAt, isNotNull);
      expect(
        controller.creditProfile?.creditScore,
        greaterThanOrEqualTo(oldScore ?? 0),
      );
    });

    test(
      '3. Ngoại lệ EX-01: Chưa có dữ liệu khoản vay trên hệ thống',
      () async {
        fakeLoanRepo.stubbedLoans = [];
        await controller.loadCreditProfile(userId: 1);

        expect(controller.isEmptyState, isTrue);
        expect(controller.exceptionCode, equals('EX-01'));
      },
    );

    test('4. Ngoại lệ EX-02: Khuyết thiếu dữ liệu phục vụ chỉ số', () async {
      mockCreditRepo.shouldSimulateMissingData = true;

      await controller.loadCreditProfile(userId: 1);

      expect(controller.hasMissingData, isTrue);
      expect(controller.missingDataFactors.length, equals(3));
      expect(controller.creditProfile?.dtiRatio, isNull);
      expect(controller.creditProfile?.ltvRatio, isNull);
      expect(controller.creditProfile?.creditUtilization, isNull);
    });

    test(
      '5. Ngoại lệ EX-03: Dữ liệu không thuộc quyền truy cập (403 Forbidden)',
      () async {
        mockCreditRepo.shouldSimulateUnauthorized = true;

        await controller.loadCreditProfile(userId: 1);

        expect(controller.exceptionCode, equals('EX-03'));
        expect(controller.errorMessage, contains('quyền'));
      },
    );

    test(
      '6. Ngoại lệ EX-04: Lỗi tính toán hoặc sự cố cơ sở dữ liệu Backend',
      () async {
        mockCreditRepo.shouldSimulateDatabaseError = true;

        await controller.loadCreditProfile(userId: 1);

        expect(controller.exceptionCode, equals('EX-04'));
        expect(controller.errorMessage, contains('Database'));
      },
    );
  });

  group('Widget & UI Interaction Tests (CreditHealthScreen)', () {
    testWidgets('7. Hiển thị đầy đủ bảng điều khiển CreditHealthScreen', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: CreditHealthScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sức khỏe tín dụng'), findsOneWidget);
      expect(find.byType(CreditScoreGauge), findsOneWidget);
      expect(find.byType(CreditMetricCard), findsWidgets);
      expect(find.text('Tỷ lệ Nợ trên Thu nhập (DTI)'), findsOneWidget);
      expect(find.text('Tỷ lệ Vay trên Giá trị Tài sản (LTV)'), findsOneWidget);
      expect(find.text('Tỷ lệ sử dụng hạn mức tín dụng'), findsOneWidget);
      expect(find.text('Tỷ lệ thanh toán đúng hạn'), findsOneWidget);
      expect(find.text('Số khoản vay đang hoạt động'), findsOneWidget);
    });

    testWidgets('8. Bấm vào chỉ số mở BottomSheet giải thích cơ chế (Mục 8)', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: CreditHealthScreen()));
      await tester.pumpAndSettle();

      // Bấm vào card DTI
      final dtiCard = find.text('Tỷ lệ Nợ trên Thu nhập (DTI)');
      await tester.tap(dtiCard);
      await tester.pumpAndSettle();

      // Modal CreditFactorSheet xuất hiện
      expect(find.byType(CreditFactorSheet), findsOneWidget);
      expect(find.text('Cơ chế đánh giá & Thuật toán'), findsOneWidget);
      expect(find.text('Nguồn dữ liệu trích xuất'), findsOneWidget);

      // Đóng modal
      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();
      expect(find.byType(CreditFactorSheet), findsNothing);
    });

    testWidgets('9. Ngoại lệ EX-01 hiển thị CreditEmptyState trong UI', (
      tester,
    ) async {
      fakeLoanRepo.stubbedLoans = [];
      await controller.loadCreditProfile(userId: 1);

      await tester.pumpWidget(const MaterialApp(home: CreditHealthScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(CreditEmptyState), findsOneWidget);
      expect(find.text('Chưa có dữ liệu khoản vay'), findsOneWidget);
      expect(find.text('Thêm khoản vay đầu tiên'), findsOneWidget);
    });

    testWidgets('10. Ngoại lệ EX-02 hiển thị Banner cảnh báo thiếu dữ liệu', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      mockCreditRepo.shouldSimulateMissingData = true;
      await controller.loadCreditProfile(userId: 1);

      await tester.pumpWidget(const MaterialApp(home: CreditHealthScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Dữ liệu cần bổ sung'), findsOneWidget);
      expect(find.text('Chưa thể tính (Thiếu dữ liệu đầu vào)'), findsWidgets);
    });
  });
}
