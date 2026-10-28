import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/simulation_controller.dart';
import 'package:my_first_app/mock_data/simulation_mock_data.dart';
import 'package:my_first_app/models/loan_model.dart';
import 'package:my_first_app/models/simulation_model.dart';
import 'package:my_first_app/repositories/interfaces/loan_repository.dart';
import 'package:my_first_app/repositories/mock/mock_simulation_repository.dart';

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

  late MockSimulationRepository mockSimulationRepo;
  late FakeLoanRepository fakeLoanRepo;
  late SimulationController controller;

  final sampleLoan = LoanModel(
    id: 101,
    userId: 1,
    loanTypeId: 1,
    name: 'Vay mua xe VinFast VF8',
    principalAmount: 500000000.0,
    outstandingAmount: 385000000.0,
    interestRate: 0.085, // 8.5%/năm
    interestMethod: 'REDUCING_BALANCE',
    termMonths: 48,
    startDate: DateTime(2025, 6, 15),
    earlyPaymentFeeRate: 0.015, // 1.5%
    status: 'ACTIVE',
  );

  setUp(() {
    SimulationMockData.reset();
    mockSimulationRepo = MockSimulationRepository();
    fakeLoanRepo = FakeLoanRepository()..stubbedLoans = [sampleLoan];
    controller = SimulationController(mockSimulationRepo, fakeLoanRepo);
  });

  group('Simulation Business Logic & Exceptions Tests', () {
    test(
      '1. Kịch bản 1 (Trả thêm một khoản): Dư nợ giảm và lãi tiết kiệm được',
      () async {
        await controller.loadData();
        controller.selectScenario(SimulationScenarioType.extraPayment);
        controller.setExtraPayment(50000000.0); // Trả thêm 50 triệu

        final res = controller.comparisonResult;
        expect(res, isNotNull);
        expect(res!.simulatedBalance, equals(385000000.0 - 50000000.0));
        expect(res.interestSaved, greaterThan(0));
        expect(res.monthsReduced, greaterThan(0));
        expect(controller.exceptionCode, isNull);
      },
    );

    test(
      '2. Kịch bản 2 (Thay đổi tiền trả mỗi kỳ): Rút ngắn thời gian khi tăng tiền trả',
      () async {
        await controller.loadData();
        controller.selectScenario(SimulationScenarioType.changePayment);
        controller.setNewMonthlyPayment(15000000.0); // Tăng lên 15 triệu/tháng

        final res = controller.comparisonResult;
        expect(res, isNotNull);
        expect(res!.simulatedMonthlyPayment, equals(15000000.0));
        expect(
          res.simulatedRemainingTerms,
          lessThan(res.currentRemainingTerms),
        );
        expect(res.monthsReduced, greaterThan(0));
      },
    );

    test(
      '3. Kịch bản 3 (Thay đổi lãi suất): Lãi suất giảm làm giảm tổng tiền lãi',
      () async {
        await controller.loadData();
        controller.selectScenario(SimulationScenarioType.changeInterestRate);
        controller.setNewInterestRate(0.065); // Giảm xuống 6.5%/năm (từ 8.5%)

        final res = controller.comparisonResult;
        expect(res, isNotNull);
        expect(res!.simulatedInterestRate, equals(0.065));
        expect(res.simulatedTotalInterest, lessThan(res.currentTotalInterest));
        expect(res.interestSaved, greaterThan(0));
      },
    );

    test(
      '4. Kịch bản 4 (Trả trước hạn): Tính đúng phí phạt và lãi tiết kiệm',
      () async {
        await controller.loadData();
        controller.selectScenario(SimulationScenarioType.earlyPayoff);
        controller.setEarlyPayoffMonths(12); // Tất toán sớm tại kỳ 12
        controller.setEarlyPaymentFeeRate(0.015);

        final res = controller.comparisonResult;
        expect(res, isNotNull);
        expect(res!.simulatedBalance, equals(0.0)); // Tất toán hết
        expect(res.simulatedFees, greaterThan(0)); // Phí phạt
        expect(res.interestSaved, greaterThan(0));
        expect(res.simulatedRemainingTerms, equals(12));
      },
    );

    test('5. EX-01: Không có khoản vay khả dụng', () async {
      fakeLoanRepo.stubbedLoans = [];
      await controller.loadData();

      expect(controller.exceptionCode, equals('EX-01'));
      expect(controller.comparisonResult, isNull);
      expect(controller.validLoans, isEmpty);
    });

    test('6. EX-02: Khoản vay cơ sở thiếu dữ liệu', () async {
      fakeLoanRepo.stubbedLoans = [
        LoanModel(
          id: 1,
          userId: 1,
          loanTypeId: 1,
          name: 'Nợ lỗi',
          principalAmount: 100000000,
          outstandingAmount: 0, // Dư nợ 0 -> Không hợp lệ
          interestRate: -0.05,
          interestMethod: 'FLAT',
          termMonths: 0,
          startDate: DateTime(2025, 1, 1),
          earlyPaymentFeeRate: 0.0,
          status: 'ACTIVE',
        ),
      ];
      await controller.loadData();

      // Khi outstandingAmount <= 0 bị lọc bởi validLoans -> EX-01 hoặc EX-02
      expect(controller.validLoans.isEmpty, isTrue);
    });

    test(
      '7. EX-03: Tham số mô phỏng trả thêm vượt quá dư nợ hiện tại',
      () async {
        await controller.loadData();
        controller.selectScenario(SimulationScenarioType.extraPayment);
        controller.setExtraPayment(500000000.0); // 500tr > 385tr dư nợ

        expect(controller.exceptionCode, equals('EX-03'));
        expect(controller.errorMessage, contains('không được vượt quá dư nợ'));
        expect(controller.comparisonResult, isNull);
      },
    );

    test('8. EX-03: Tham số tiền trả mỗi kỳ không đủ bù tiền lãi', () async {
      await controller.loadData();
      controller.selectScenario(SimulationScenarioType.changePayment);
      controller.setNewMonthlyPayment(100000.0); // 100k < 2.7 triệu lãi tháng

      expect(controller.exceptionCode, equals('EX-03'));
      expect(controller.errorMessage, contains('không đủ bù tiền lãi'));
      expect(controller.comparisonResult, isNull);
    });

    test(
      '9. Lưu kịch bản mô phỏng tham khảo (Mục 12: SIMULATION_REFERENCE)',
      () async {
        await controller.loadData();
        final initialCount = controller.savedSimulations.length;

        final success = await controller.saveCurrentSimulation(
          customName: 'Kịch bản thử nghiệm VF8',
        );
        expect(success, isTrue);
        expect(controller.savedSimulations.length, equals(initialCount + 1));
        expect(
          controller.savedSimulations.first.status,
          equals('SIMULATION_REFERENCE'),
        );
      },
    );

    test('10. EX-05: Sự cố cơ sở dữ liệu khi lưu kịch bản', () async {
      await controller.loadData();
      mockSimulationRepo.shouldSimulateDatabaseError = true;

      final success = await controller.saveCurrentSimulation();
      expect(success, isFalse);
      expect(controller.exceptionCode, equals('EX-05'));
      expect(controller.errorMessage, contains('EX-05'));
    });
  });
}
