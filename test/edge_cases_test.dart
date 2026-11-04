import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/models/loan_model.dart';
import 'package:my_first_app/models/user_model.dart';
import 'package:my_first_app/repositories/mock/mock_loan_repository.dart';
import 'package:my_first_app/repositories/mock/mock_storage_repository.dart';
import 'package:my_first_app/service_locator.dart';

void main() {
  setUpAll(() async {
    setupServiceLocator();
  });

  group('Boundary & Edge Cases Tests', () {
    test('1. LoanController xử lý an toàn khi danh sách khoản vay rỗng', () {
      final mockRepo = MockLoanRepository();
      final controller = LoanController(mockRepo);

      // Trực tiếp kiểm tra danh mục rỗng
      expect(controller.loans, isEmpty);
      expect(controller.totalOriginalPrincipal, 0.0);
      expect(controller.totalRemainingPrincipal, 0.0);
      expect(controller.totalPaidAmount, 0.0);
      // Kiểm tra tránh lỗi chia cho 0 (division by zero)
      expect(controller.paidRatio, 0.0);
      expect(controller.totalMonthlyCommitment, 0.0);
      expect(controller.activeLoansCount, 0);
      expect(controller.collaterals, isEmpty);
      expect(controller.totalCollateralValue, 0.0);
      expect(controller.portfolioLtvRatio, 0.0);
    });

    test(
      '2. LoanController lọc trạng thái không có hợp đồng trả về mảng rỗng không lỗi',
      () async {
        final controller = sl<LoanController>();
        await controller.fetchLoans();

        // Lọc trạng thái không có khoản vay
        await controller.setFilterStatus(LoanStatus.overdue);
        expect(controller.loans, isA<List<LoanModel>>());

        // Khôi phục lại trạng thái active
        await controller.setFilterStatus(LoanStatus.active);
        expect(controller.loans, isNotEmpty);
      },
    );

    test(
      '3. StorageRepository trả về failure khi upload tệp rỗng 0 bytes',
      () async {
        final storageRepo = MockStorageRepository();

        final result = await storageRepo.uploadImageFile(
          bytes: [],
          folder: 'avatars',
          fileName: 'empty.jpg',
          contentType: 'image/jpeg',
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, 'Tệp ảnh rỗng, không thể tải lên.');
      },
    );

    test(
      '4. AuthController thu hồi phiên không tồn tại không làm ứng dụng crash',
      () async {
        final authController = sl<AuthController>();
        await authController.loadSessions();

        final initialCount = authController.activeSessions.length;
        await authController.revokeSession('non_existent_session_99999');

        expect(authController.activeSessions.length, initialCount);
      },
    );

    test(
      '5. AuthController updateCurrentUser an toàn khi truyền tham số rỗng',
      () async {
        final authController = sl<AuthController>();
        await authController.login('dev@test.com', '123456');

        final oldUser = authController.currentUser!;
        authController.updateCurrentUser();

        expect(authController.currentUser?.fullName, oldUser.fullName);
        expect(authController.currentUser?.phone, oldUser.phone);
        expect(
          authController.currentUser?.monthlyIncome,
          oldUser.monthlyIncome,
        );
      },
    );

    test(
      '6. UserModel & BankAccountModel map chuẩn xác schema SQL database',
      () {
        final userJson = {
          'user_id': 99,
          'full_name': 'Nguyen SQL',
          'email': 'sql@test.com',
          'password_hash': 'hashed_sql',
          'avatar_url': 'https://r2.dev/avatars/user_99.png',
          'monthly_income': 35000000.0,
          'contract_type': 'INDEFINITE',
          'ekyc_tier': 'PRO',
          'membership_tier': 'VIP',
          'cic_score': 760,
          'is_biometric_enabled': true,
          'auto_lock_enabled': true,
          'bank_accounts': [
            {
              'account_id': 501,
              'bank_name': 'Vietcombank',
              'account_number': '0011009999',
              'account_holder_name': 'NGUYEN SQL',
              'is_default_disbursal': true,
              'is_auto_debit': false,
            },
          ],
        };

        final user = UserModel.fromJson(userJson);
        expect(user.userId, 99);
        expect(user.avatarUrl, 'https://r2.dev/avatars/user_99.png');
        expect(user.membershipTier, 'VIP');
        expect(user.bankAccounts.first.id, '501');
        expect(user.bankAccounts.first.isDefaultDisbursal, true);

        final exportedJson = user.toJson();
        expect(
          exportedJson['avatar_url'],
          'https://r2.dev/avatars/user_99.png',
        );
        expect(exportedJson['user_id'], 99);

        final updated = user.copyWith(
          avatarUrl: 'https://r2.dev/avatars/new.png',
        );
        expect(updated.avatarUrl, 'https://r2.dev/avatars/new.png');
      },
    );
  });
}
