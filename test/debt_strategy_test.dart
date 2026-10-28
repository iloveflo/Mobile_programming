import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/debt_strategy_controller.dart';
import 'package:my_first_app/mock_data/debt_strategy_mock_data.dart';
import 'package:my_first_app/models/debt_strategy_model.dart';
import 'package:my_first_app/models/loan_model.dart';
import 'package:my_first_app/repositories/interfaces/loan_repository.dart';
import 'package:my_first_app/repositories/mock/mock_debt_strategy_repository.dart';

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

  late MockDebtStrategyRepository mockDebtRepo;
  late FakeLoanRepository fakeLoanRepo;
  late DebtStrategyController controller;

  final sampleLoans = [
    LoanModel(
      id: 1,
      userId: 1,
      loanTypeId: 1,
      name: 'Khoản A - Vay mua nhà',
      principalAmount: 100000000,
      outstandingAmount: 100000000,
      interestRate: 0.08, // 8%
      interestMethod: 'REDUCING_BALANCE',
      termMonths: 48,
      startDate: DateTime(2025, 1, 1),
      earlyPaymentFeeRate: 0.01,
      status: 'ACTIVE',
    ),
    LoanModel(
      id: 2,
      userId: 1,
      loanTypeId: 2,
      name: 'Khoản B - Tiêu dùng',
      principalAmount: 50000000,
      outstandingAmount: 50000000,
      interestRate: 0.15, // 15%
      interestMethod: 'REDUCING_BALANCE',
      termMonths: 24,
      startDate: DateTime(2025, 1, 1),
      earlyPaymentFeeRate: 0.01,
      status: 'ACTIVE',
    ),
    LoanModel(
      id: 3,
      userId: 1,
      loanTypeId: 3,
      name: 'Khoản C - Thẻ tín dụng',
      principalAmount: 25000000,
      outstandingAmount: 25000000,
      interestRate: 0.12, // 12%
      interestMethod: 'FLAT',
      termMonths: 12,
      startDate: DateTime(2025, 1, 1),
      earlyPaymentFeeRate: 0.0,
      status: 'ACTIVE',
    ),
    LoanModel(
      id: 4,
      userId: 1,
      loanTypeId: 4,
      name: 'Khoản D - Vay cá nhân',
      principalAmount: 10000000,
      outstandingAmount: 10000000,
      interestRate: 0.10, // 10%
      interestMethod: 'FLAT',
      termMonths: 6,
      startDate: DateTime(2025, 1, 1),
      earlyPaymentFeeRate: 0.0,
      status: 'ACTIVE',
    ),
    LoanModel(
      id: 5,
      userId: 1,
      loanTypeId: 1,
      name: 'Khoản E - Đã tất toán',
      principalAmount: 30000000,
      outstandingAmount: 0,
      interestRate: 0.18,
      interestMethod: 'FLAT',
      termMonths: 12,
      startDate: DateTime(2024, 1, 1),
      earlyPaymentFeeRate: 0.0,
      status: 'CLOSED',
    ),
  ];

  setUp(() {
    DebtStrategyMockData.reset();
    mockDebtRepo = MockDebtStrategyRepository();
    fakeLoanRepo = FakeLoanRepository()..stubbedLoans = List.from(sampleLoans);
    controller = DebtStrategyController(mockDebtRepo, fakeLoanRepo);
  });

  group('Debt Strategy Algorithm & Business Logic Tests', () {
    test(
      '1. EX-03: Khoản vay đã tất toán tự động bị loại khỏi danh sách tối ưu',
      () async {
        await controller.loadData();

        expect(controller.validLoans.length, equals(4));
        expect(
          controller.validLoans.any((l) => l.name == 'Khoản E - Đã tất toán'),
          isFalse,
        );
      },
    );

    test(
      '2. Snowball: Sắp xếp theo dư nợ nhỏ nhất trước (D -> C -> B -> A)',
      () async {
        await controller.loadData();
        controller.setStrategyType(DebtStrategyType.snowball);

        final plan = controller.snowballPlan;
        expect(plan, isNotNull);
        expect(plan!.items.length, equals(4));

        // Thứ tự ưu tiên Snowball:
        // 1: Khoản D (10 tr)
        // 2: Khoản C (25 tr)
        // 3: Khoản B (50 tr)
        // 4: Khoản A (100 tr)
        expect(plan.items[0].loan.name, equals('Khoản D - Vay cá nhân'));
        expect(plan.items[1].loan.name, equals('Khoản C - Thẻ tín dụng'));
        expect(plan.items[2].loan.name, equals('Khoản B - Tiêu dùng'));
        expect(plan.items[3].loan.name, equals('Khoản A - Vay mua nhà'));
      },
    );

    test(
      '3. Avalanche: Sắp xếp theo lãi suất cao nhất trước (B -> C -> D -> A)',
      () async {
        await controller.loadData();
        controller.setStrategyType(DebtStrategyType.avalanche);

        final plan = controller.avalanchePlan;
        expect(plan, isNotNull);
        expect(plan!.items.length, equals(4));

        // Thứ tự ưu tiên Avalanche:
        // 1: Khoản B (15%)
        // 2: Khoản C (12%)
        // 3: Khoản D (10%)
        // 4: Khoản A (8%)
        expect(plan.items[0].loan.name, equals('Khoản B - Tiêu dùng'));
        expect(plan.items[1].loan.name, equals('Khoản C - Thẻ tín dụng'));
        expect(plan.items[2].loan.name, equals('Khoản D - Vay cá nhân'));
        expect(plan.items[3].loan.name, equals('Khoản A - Vay mua nhà'));
      },
    );

    test('4. Phân tích chỉ số tổng hợp (Mục 6)', () async {
      await controller.loadData();

      expect(controller.totalDebtsCount, equals(4));
      expect(controller.totalOutstandingDebt, equals(185000000.0));
      expect(controller.weightedAverageInterestRate, greaterThan(0.05));
    });

    test(
      '5. Áp dụng kế hoạch tối ưu (Mục 11 & 13) và chuyển sang ACTIVE',
      () async {
        await controller.loadData();
        controller.setStrategyType(DebtStrategyType.snowball);

        final success = await controller.applySelectedStrategy();
        expect(success, isTrue);
        expect(controller.hasActivePlan, isTrue);
        expect(
          controller.activeAppliedStrategy?.strategyType,
          equals('SNOWBALL'),
        );
      },
    );

    test('6. EX-01: Không có khoản nợ nào trong hệ thống', () async {
      fakeLoanRepo.stubbedLoans = [];
      await controller.loadData();

      expect(controller.exceptionCode, equals('EX-01'));
      expect(controller.validLoans, isEmpty);
    });

    test('7. EX-02: Khoản nợ thiếu thông tin tính toán bắt buộc', () async {
      fakeLoanRepo.stubbedLoans = [
        LoanModel(
          id: 99,
          userId: 1,
          loanTypeId: 1,
          name: 'Nợ lỗi',
          principalAmount: 10000000,
          outstandingAmount: 10000000,
          interestRate: -0.05, // Lãi suất âm -> Không hợp lệ
          interestMethod: 'FLAT',
          termMonths: 0, // Kỳ hạn 0 -> Không hợp lệ
          startDate: DateTime(2025, 1, 1),
          earlyPaymentFeeRate: 0.0,
          status: 'ACTIVE',
        ),
      ];
      await controller.loadData();

      expect(controller.exceptionCode, equals('EX-02'));
      expect(controller.invalidLoans.length, equals(1));
    });

    test('8. EX-05: Giả lập sự cố cơ sở dữ liệu khi lưu kế hoạch', () async {
      await controller.loadData();
      mockDebtRepo.shouldSimulateDatabaseError = true;

      final success = await controller.applySelectedStrategy();
      expect(success, isFalse);
      expect(controller.exceptionCode, equals('EX-05'));
      expect(controller.errorMessage, contains('EX-05'));
    });
  });
}
