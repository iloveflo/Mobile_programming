import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/models/loan_model.dart';
import 'package:my_first_app/repositories/mock/mock_loan_repository.dart';

void main() {
  late MockLoanRepository mockRepo;
  late LoanController controller;

  setUp(() {
    mockRepo = MockLoanRepository();
    controller = LoanController(mockRepo);
  });

  group('LoanController & MockLoanRepository Tests', () {
    test('Khởi tạo và tải danh sách khoản vay thành công', () async {
      expect(controller.loans, isEmpty);
      await controller.fetchLoans();
      expect(controller.loans, isNotEmpty);
      expect(controller.loans.length, greaterThanOrEqualTo(4));
    });

    test('Lọc theo trạng thái LoanStatus.active', () async {
      await controller.fetchLoans();
      await controller.setFilterStatus(LoanStatus.active);
      expect(controller.loans, isNotEmpty);
      for (final loan in controller.loans) {
        expect(loan.isActive, isTrue);
      }
    });

    test('Tìm kiếm theo từ khóa ngân hàng', () async {
      await controller.fetchLoans();
      await controller.setSearchKeyword('Techcombank');
      expect(controller.loans, isNotEmpty);
      for (final loan in controller.loans) {
        expect(
          loan.name.toLowerCase().contains('techcombank') ||
              loan.lenderName.toLowerCase().contains('techcombank'),
          isTrue,
        );
      }
    });

    test('Tạo mới khoản vay thành công', () async {
      await controller.fetchLoans();
      final initialCount = controller.loans.length;

      final success = await controller.createLoan({
        'loan_name': 'Vay tín chấp nâng cấp laptop',
        'lender_name': 'MBBank',
        'principal_amount': 25000000.0,
        'outstanding_amount': 25000000.0,
        'interest_rate': 12.0,
        'tenor_months': 12,
        'start_date': '15/09/2026',
        'interest_method': 'Dư nợ giảm dần',
        'status': 'ACTIVE',
      });

      expect(success, isTrue);
      expect(controller.loans.length, equals(initialCount + 1));
      expect(
        controller.loans.first.loanName,
        equals('Vay tín chấp nâng cấp laptop'),
      );
    });

    test('Ghi nhận thanh toán và cập nhật dư nợ', () async {
      await controller.fetchLoans();
      final firstLoan = controller.loans.first;
      final oldOutstanding = firstLoan.outstandingAmount;

      final success = await controller.updateLoan(firstLoan.id.toString(), {
        'outstanding_amount': oldOutstanding - 5000000,
      });

      expect(success, isTrue);
      final updated = controller.loans.firstWhere((l) => l.id == firstLoan.id);
      expect(updated.outstandingAmount, equals(oldOutstanding - 5000000));
    });

    test('Xóa khoản vay chưa phát sinh trả nợ thành công', () async {
      await controller.fetchLoans();
      // Tạo khoản vay mới chưa trả nợ (paidAmount = 0)
      await controller.createLoan({
        'loan_name': 'Khoản vay test xóa',
        'lender_name': 'MBBank',
        'principal_amount': 20000000.0,
        'outstanding_amount': 20000000.0,
        'interest_rate': 10.0,
        'tenor_months': 12,
        'start_date': '15/09/2026',
        'interest_method': 'Dư nợ giảm dần',
        'status': 'ACTIVE',
      });
      final newLoan = controller.loans.first;
      expect(newLoan.canHardDelete, isTrue);

      final initialCount = controller.loans.length;
      final success = await controller.removeLoan(newLoan.id.toString());
      expect(success, isTrue);
      expect(controller.loans.length, equals(initialCount - 1));
      expect(controller.loans.any((l) => l.id == newLoan.id), isFalse);
    });

    test('Xử lý bóc tách tài liệu hợp đồng AI/OCR thành công', () async {
      final ocrResult = await controller.processOcr('contract_test.jpg');
      expect(ocrResult, isNotNull);
      expect(ocrResult!['contract_number'], isNotNull);
      expect(ocrResult['confidence_score'], greaterThan(0.9));
    });

    test('Tính toán chỉ số danh mục Portfolio Metrics chuẩn xác', () async {
      await controller.fetchLoans();
      expect(controller.totalOriginalPrincipal, greaterThan(0));
      expect(controller.totalRemainingPrincipal, greaterThan(0));
      expect(controller.paidRatio, inInclusiveRange(0.0, 1.0));
    });

    test('Thêm tài sản thế chấp và tải danh sách tài sản thành công', () async {
      await controller.fetchCollaterals();
      final initialCount = controller.collaterals.length;

      final success = await controller.addCollateral(
        name: 'Sổ đỏ Chung cư Vinhomes Metropolis',
        type: 'REAL_ESTATE',
        value: 3500000000.0,
        description: 'Căn hộ tầng 12, tháp M1',
      );

      expect(success, isTrue);
      expect(controller.collaterals.length, equals(initialCount + 1));
      expect(
        controller.collaterals.first.name,
        equals('Sổ đỏ Chung cư Vinhomes Metropolis'),
      );
      expect(controller.totalCollateralValue, greaterThan(3500000000.0));
    });

    test(
      'Từ chối thêm tài sản nếu giá trị định giá nằm ngoài hạn mức của loại tài sản',
      () async {
        await controller.fetchCollaterals();

        // Thử thêm Bất động sản với giá trị 1đ (vi phạm mức sàn 100 triệu)
        final failTooLow = await controller.addCollateral(
          name: 'Nhà cấp 4',
          type: 'REAL_ESTATE',
          value: 1.0,
        );
        expect(failTooLow, isFalse);
        expect(controller.errorMessage, contains('tối thiểu'));

        // Thử thêm Phương tiện với giá trị 1đ (vi phạm mức sàn 50 triệu)
        final failVehicle = await controller.addCollateral(
          name: 'Xe máy',
          type: 'VEHICLE',
          value: 1.0,
        );
        expect(failVehicle, isFalse);
        expect(controller.errorMessage, contains('tối thiểu'));

        // Thử thêm vượt mức trần
        final failTooHigh = await controller.addCollateral(
          name: 'Xe siêu sang',
          type: 'VEHICLE',
          value: 50000000000.0, // 50 tỷ vượt trần xe 20 tỷ
        );
        expect(failTooHigh, isFalse);
        expect(controller.errorMessage, contains('tối đa'));
      },
    );

    test(
      'Tất toán trước hạn chuyển trạng thái SETTLED và dư nợ về 0',
      () async {
        await controller.fetchLoans();
        final activeLoan = controller.loans.firstWhere((l) => l.isActive);

        final success = await controller.settleLoanEarly(
          activeLoan.id.toString(),
        );
        expect(success, isTrue);

        final settledLoan = controller.loans.firstWhere(
          (l) => l.id == activeLoan.id,
        );
        expect(settledLoan.isSettled, isTrue);
        expect(settledLoan.outstandingAmount, equals(0.0));
      },
    );

    test(
      'Khoản vay đã phát sinh thanh toán tuyệt đối không được phép xóa',
      () async {
        await controller.fetchLoans();
        // Chọn khoản vay có paidAmount > 0 (ví dụ id: 101, principal: 500M, outstanding: 385M)
        final paidLoan = controller.loans.firstWhere(
          (l) => l.paidAmount > 0 && l.isActive,
        );
        expect(paidLoan.canHardDelete, isFalse);

        final initialLength = controller.loans.length;
        final success = await controller.removeLoan(paidLoan.id.toString());
        expect(success, isFalse);
        expect(controller.errorMessage, contains('không thể xóa'));
        expect(
          controller.loans.length,
          equals(initialLength),
        ); // Vẫn còn nguyên vẹn trong list
      },
    );

    test(
      'Tạo mới khoản vay lưu đúng loại khoản vay (loan_type) và hiển thị lãi suất chuẩn hóa',
      () async {
        await controller.fetchLoans();

        final success = await controller.createLoan({
          'loan_name': 'Vay mua nhà Ecopark',
          'lender_name': 'Techcombank',
          'loan_type': 'MORTGAGE',
          'principal_amount': 2000000000.0,
          'outstanding_amount': 2000000000.0,
          'interest_rate': 8.5,
          'tenor_months': 120,
          'start_date': '15/09/2026',
          'interest_method': 'Dư nợ giảm dần',
          'status': 'ACTIVE',
        });

        expect(success, isTrue);
        final created = controller.loans.first;
        expect(created.loanTypeKey, equals('MORTGAGE'));
        expect(
          created.loanTypeDisplayName,
          equals('Vay thế chấp / Bất động sản'),
        );
        expect(created.interestRatePercent, equals(8.5));
        expect(created.interestRateFormatted, equals('8.5%/năm'));
      },
    );

    test('Lấy chi tiết khoản vay tức thì không bị trễ', () async {
      await controller.fetchLoans();
      final target = controller.loans.first;
      controller.selectLoan(target);
      expect(controller.selectedLoan?.id, target.id);

      await controller.getDetail(target.id.toString());
      expect(controller.selectedLoan?.id, target.id);
      expect(controller.isLoading, isFalse);
    });
  });
}
