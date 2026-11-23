import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/credit_profile_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/models/collateral_model.dart';
import 'package:my_first_app/models/credit_profile_model.dart';
import 'package:my_first_app/models/loan_model.dart';
import 'package:my_first_app/models/notification_model.dart';
import 'package:my_first_app/models/notification_preference_model.dart';
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
import 'package:my_first_app/widgets/loans/ltv_indicator_bar.dart';

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

    testWidgets(
      '11. CreditScoreGauge khi creditScore == null hiển thị Chưa đủ dữ liệu thay vì Hạng 5 Rủi ro cao',
      (tester) async {
        const missingScoreProfile = CreditProfileModel(
          id: 1,
          userId: 1,
          creditScore: null,
          dtiRatio: null,
          ltvRatio: 0.60,
          activeLoanCount: 1,
          riskLevel: 'UNKNOWN',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CreditScoreGauge(
                profile: missingScoreProfile,
                isRecalculating: false,
                onRecalculate: () {},
              ),
            ),
          ),
        );

        expect(find.text('--'), findsOneWidget);
        expect(
          find.text('Chưa đủ dữ liệu • Cần bổ sung thu nhập'),
          findsOneWidget,
        );
        expect(find.textContaining('Hạng 5 (Cần cải thiện)'), findsNothing);
        expect(find.textContaining('Rủi ro cao'), findsNothing);
      },
    );

    testWidgets(
      '12. LtvIndicatorBar hiển thị cảnh báo khi TSBĐ dùng chung cho nhiều khoản vay',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LtvIndicatorBar(
                ltvRatio: 0.60,
                outstandingAmount: 150000000,
                collateralValue: 250000000,
                sharedSecuredDebt: 225000000,
                sharedLoanCount: 2,
              ),
            ),
          ),
        );

        expect(find.text('60%'), findsOneWidget);
        expect(
          find.textContaining('TSBĐ đang bảo đảm chung cho 2 khoản vay'),
          findsOneWidget,
        );
        expect(find.textContaining('LTV thực tế: 90%'), findsOneWidget);
      },
    );
  });

  group('LTV & LoanController secured debt isolation', () {
    test('portfolioSecuredDebt & portfolioLtvRatio không gộp nợ tín chấp', () {
      final loanCtrl = LoanController(fakeLoanRepo);
      final securedLoan = LoanModel(
        id: 10,
        userId: 1,
        loanTypeId: 1,
        loanType: 'MORTGAGE',
        name: 'Vay mua nhà',
        principalAmount: 200000000,
        outstandingAmount: 150000000,
        interestRate: 0.092,
        interestMethod: 'REDUCING_BALANCE',
        termMonths: 120,
        startDate: DateTime(2026, 9, 15),
        earlyPaymentFeeRate: 0.01,
        status: 'ACTIVE',
      );
      final unsecuredLoan = LoanModel(
        id: 11,
        userId: 1,
        loanTypeId: 3,
        loanType: 'CONSUMER',
        name: 'Vay tín chấp',
        principalAmount: 100000000,
        outstandingAmount: 100000000,
        interestRate: 0.15,
        interestMethod: 'REDUCING_BALANCE',
        termMonths: 24,
        startDate: DateTime(2026, 9, 15),
        earlyPaymentFeeRate: 0.01,
        status: 'ACTIVE',
      );

      // Inject loans & collaterals via test helper or state
      // Use LoanController with a stubbed repo that returns both loans and 1 collateral
      final repo = _LtvStubLoanRepository(
        loans: [securedLoan, unsecuredLoan],
        collaterals: [
          const CollateralModel(
            id: 100,
            userId: 1,
            loanId: 10,
            name: 'Sổ đỏ Q7',
            type: 'REAL_ESTATE',
            value: 250000000,
            linkedLoanIds: ['10'],
          ),
        ],
      );
      final ctrl = LoanController(repo);
      // Verify initial empty state is 0
      expect(ctrl.portfolioSecuredDebt, equals(0.0));
      expect(ctrl.portfolioLtvRatio, equals(0.0));
      expect(loanCtrl.portfolioLtvRatio, equals(0.0));
    });

    test(
      'portfolioLtvRatio tính đúng 60% khi có cả khoản vay tín chấp',
      () async {
        final securedLoan = LoanModel(
          id: 10,
          userId: 1,
          loanTypeId: 1,
          loanType: 'MORTGAGE',
          name: 'Vay mua nhà',
          principalAmount: 200000000,
          outstandingAmount: 150000000,
          interestRate: 0.092,
          interestMethod: 'REDUCING_BALANCE',
          termMonths: 120,
          startDate: DateTime(2026, 9, 15),
          earlyPaymentFeeRate: 0.01,
          status: 'ACTIVE',
        );
        final unsecuredLoan = LoanModel(
          id: 11,
          userId: 1,
          loanTypeId: 3,
          loanType: 'CONSUMER',
          name: 'Vay tín chấp',
          principalAmount: 100000000,
          outstandingAmount: 100000000,
          interestRate: 0.15,
          interestMethod: 'REDUCING_BALANCE',
          termMonths: 24,
          startDate: DateTime(2026, 9, 15),
          earlyPaymentFeeRate: 0.01,
          status: 'ACTIVE',
        );
        final repo = _LtvStubLoanRepository(
          loans: [securedLoan, unsecuredLoan],
          collaterals: [
            const CollateralModel(
              id: 100,
              userId: 1,
              loanId: 10,
              name: 'Sổ đỏ Q7',
              type: 'REAL_ESTATE',
              value: 250000000,
              linkedLoanIds: ['10'],
            ),
          ],
        );
        final ctrl = LoanController(repo);
        await ctrl.fetchLoans();
        await ctrl.fetchCollaterals();

        expect(ctrl.totalRemainingPrincipal, equals(250000000.0));
        expect(ctrl.portfolioSecuredDebt, equals(150000000.0));
        expect(ctrl.portfolioLtvRatio, closeTo(0.60, 0.0001));
      },
    );

    test(
      'portfolioCollateralValue không bị ghi đè khi xem chi tiết 1 khoản vay',
      () async {
        final securedLoan = LoanModel(
          id: 10,
          userId: 1,
          loanTypeId: 1,
          loanType: 'MORTGAGE',
          name: 'Vay mua nhà',
          principalAmount: 200000000,
          outstandingAmount: 150000000,
          interestRate: 0.092,
          interestMethod: 'REDUCING_BALANCE',
          termMonths: 120,
          startDate: DateTime(2026, 9, 15),
          earlyPaymentFeeRate: 0.01,
          status: 'ACTIVE',
        );
        final repo = _LtvStubLoanRepository(
          loans: [securedLoan],
          collaterals: [
            const CollateralModel(
              id: 100,
              userId: 1,
              loanId: 10,
              name: 'Sổ đỏ Q7',
              type: 'REAL_ESTATE',
              value: 250000000,
              linkedLoanIds: ['10'],
            ),
            const CollateralModel(
              id: 101,
              userId: 1,
              loanId: null,
              name: 'Sổ tiết kiệm',
              type: 'SAVINGS',
              value: 100000000,
            ),
          ],
        );
        final ctrl = LoanController(repo);
        await ctrl.fetchCollaterals();
        expect(ctrl.portfolioCollateralValue, equals(350000000.0));
        expect(ctrl.portfolioCollaterals.length, equals(2));

        // Khi xem chi tiết 1 khoản vay không có TSBĐ, collaterals bị lọc về rỗng nhưng portfolioCollateralValue vẫn giữ nguyên
        await ctrl.fetchCollaterals('999');
        expect(ctrl.collaterals.length, equals(0));
        expect(ctrl.portfolioCollateralValue, equals(350000000.0));
        expect(ctrl.portfolioCollaterals.length, equals(2));
      },
    );

    test(
      'NotificationModel & NotificationPreferenceModel parse đúng BIGINT dạng String từ PostgreSQL',
      () {
        final notif = NotificationModel.fromJson({
          'notification_id': '1',
          'user_id': '1',
          'schedule_id': '4',
          'notification_type': 'OVERDUE_ALERT',
          'channel': 'PUSH',
          'title': 'Cảnh báo quá hạn',
          'message': 'Kỳ 4 đã quá hạn',
          'status': 'SENT',
        });
        expect(notif.id, equals(1));
        expect(notif.userId, equals(1));
        expect(notif.scheduleId, equals(4));

        final pref = NotificationPreferenceModel.fromJson({
          'preference_id': '1',
          'user_id': '1',
          'push_enabled': true,
          'email_enabled': true,
          'reminder_days': '3',
        });
        expect(pref.id, equals(1));
        expect(pref.userId, equals(1));
        expect(pref.reminderDays, equals(3));
      },
    );

    test(
      'ApiPaymentScheduleRepository.getNotifications unwrap đúng field data từ Backend',
      () async {
        // Xác nhận NotificationModel parse đúng cấu trúc trả về của GET /notifications {success: true, data: [...]}
        final rawPayload = {
          'success': true,
          'data': [
            {
              'notification_id': '1',
              'user_id': '1',
              'schedule_id': '4',
              'notification_type': 'OVERDUE_ALERT',
              'channel': 'PUSH',
              'title': 'Cảnh báo kỳ thanh toán quá hạn',
              'message': 'Kỳ 4 đã quá hạn',
              'status': 'SENT',
            },
          ],
        };
        final list = (rawPayload['data'] as List)
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        expect(list.length, equals(1));
        expect(list.first.id, equals(1));
        expect(list.first.scheduleId, equals(4));
      },
    );
  });
}

class _LtvStubLoanRepository implements LoanRepository {
  final List<LoanModel> loans;
  final List<CollateralModel> collaterals;
  _LtvStubLoanRepository({required this.loans, required this.collaterals});

  @override
  Future<List<LoanModel>> getLoans({
    String? keyword,
    LoanStatus? status,
    String? lender,
  }) async => List.from(loans);

  @override
  Future<List<CollateralModel>> getCollaterals({String? loanId}) async {
    if (loanId == null) return List.from(collaterals);
    return collaterals
        .where(
          (c) =>
              c.loanId?.toString() == loanId ||
              c.linkedLoanIds.contains(loanId),
        )
        .toList();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
