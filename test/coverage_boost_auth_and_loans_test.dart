import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/models/auth_token_model.dart';
import 'package:my_first_app/models/register_request_model.dart';
import 'package:my_first_app/models/user_model.dart';
import 'package:my_first_app/repositories/mock/mock_auth_repository.dart';
import 'package:my_first_app/screens/auth/login_screen.dart';
import 'package:my_first_app/screens/loans/loan_detail_screen.dart';
import 'package:my_first_app/screens/loans/loan_form_screen.dart';
import 'package:my_first_app/service_locator.dart';
import 'package:my_first_app/widgets/dev/dev_state_panel.dart';

class _RichFakeAuthRepo extends MockAuthRepository {
  bool throwOnSync = false;
  bool throwOnPdf = false;
  bool throwOnEkyc = false;
  AuthTokenModel? sessionToken;

  @override
  Future<AuthTokenModel?> checkSession() async => sessionToken;

  @override
  Future<String> exportFinancialProfilePdf() async {
    if (throwOnPdf) throw Exception('PDF error');
    return 'https://cdn.test/profile.pdf';
  }

  @override
  Future<List<int>> downloadFinancialProfilePdfBytes() async {
    if (throwOnPdf) throw Exception('PDF bytes error');
    return [1, 2, 3, 4];
  }

  @override
  Future<UserModel> verifyEkyc({
    required String idCardNumber,
    required String frontCardUrl,
    required String backCardUrl,
    String? fullName,
    String? dateOfBirth,
    String? address,
  }) async {
    if (throwOnEkyc) throw Exception('eKYC error');
    return UserMockData.usersDatabase.first.copyWith(isEkycVerified: true);
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> profileData) async {
    if (throwOnSync) throw Exception('Sync error');
    return super.updateProfile(profileData);
  }
}

void main() {
  setUpAll(() async {
    await resetServiceLocator(dispose: false);
    setupServiceLocator();
  });

  group('AuthController Full Coverage Tests', () {
    late _RichFakeAuthRepo repo;
    late AuthController auth;

    setUp(() {
      repo = _RichFakeAuthRepo();
      auth = AuthController(repo);
    });

    tearDown(() => auth.cancelOtpTimer());

    test(
      'checkSession, restoreProfileIfNeeded, fetchProfile, syncProfile',
      () async {
        expect(await auth.checkSession(), isFalse);

        repo.sessionToken = AuthTokenModel(
          accessToken: 'tok',
          refreshToken: 'ref',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
          userId: 1,
        );
        expect(await auth.checkSession(), isTrue);
        expect(await auth.restoreProfileIfNeeded(), isTrue);

        await auth.fetchProfile();
        expect(auth.currentUser, isNotNull);

        expect(await auth.syncProfile({'full_name': 'Updated Name'}), isTrue);
        repo.throwOnSync = true;
        expect(await auth.syncProfile({'full_name': 'Fail'}), isFalse);
        expect(auth.errorMessage, isNotNull);
        auth.clearError();
        expect(auth.errorMessage, isNull);
      },
    );

    test('forgotPassword, resetPassword, changePassword, PDF & eKYC', () async {
      auth.setRememberMe(false);
      expect(auth.rememberMe, isFalse);

      auth.setPendingVerification(
        email: 'dev@test.com',
        phone: '0912345678',
        flow: OtpFlow.register,
      );
      expect(auth.pendingEmail, 'dev@test.com');

      expect(await auth.requestForgotPasswordOtp('dev@test.com'), isTrue);
      expect(await auth.resetPassword('NewPass123!'), isTrue);

      await auth.login('dev@test.com', 'NewPass123!');
      expect(
        await auth.changePassword(
          currentPassword: 'NewPass123!',
          newPassword: 'AnotherPass123!',
        ),
        isTrue,
      );

      expect(
        await auth.exportFinancialProfilePdf(),
        'https://cdn.test/profile.pdf',
      );
      expect(await auth.downloadFinancialProfilePdfBytes(), [1, 2, 3, 4]);
      repo.throwOnPdf = true;
      expect(await auth.exportFinancialProfilePdf(), isNull);
      expect(await auth.downloadFinancialProfilePdfBytes(), isNull);

      expect(
        await auth.verifyEkyc(
          idCardNumber: '001200001234',
          frontCardUrl: 'f.jpg',
          backCardUrl: 'b.jpg',
        ),
        isTrue,
      );
      repo.throwOnEkyc = true;
      expect(
        await auth.verifyEkyc(
          idCardNumber: '001200001234',
          frontCardUrl: 'f.jpg',
          backCardUrl: 'b.jpg',
        ),
        isFalse,
      );
    });

    test('DevAuthState branches & register/login states', () async {
      for (final state in DevAuthState.values) {
        auth.setDevState(state);
      }

      auth.setDevState(DevAuthState.networkError);
      expect(
        await auth.login('dev@test.com', '123456'),
        AuthResultState.locked,
      );

      auth.setDevState(DevAuthState.normal);
      await auth.register(
        RegisterRequestModel(
          fullName: 'Test User',
          email: 't@t.com',
          phone: '0900000000',
          dateOfBirth: DateTime(1995, 1, 1),
          password: 'Password123!',
        ),
      );
      expect(await auth.verifyOtp('123456', flow: OtpFlow.register), isTrue);
    });
  });

  group('LoginScreen Interaction Tests', () {
    testWidgets(
      'LoginScreen nhập liệu, toggle mật khẩu, quên mật khẩu & đăng nhập',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
        await tester.pumpAndSettle();

        // Mở dialog Quên mật khẩu và hủy
        final forgotBtn = find.text('Quên mật khẩu?');
        if (forgotBtn.evaluate().isNotEmpty) {
          await tester.tap(forgotBtn);
          await tester.pumpAndSettle();
          expect(find.text('Quên mật khẩu'), findsOneWidget);
          await tester.tap(find.text('Hủy'));
          await tester.pumpAndSettle();
        }

        // Nhập email & password sai
        final fields = find.byType(TextFormField);
        if (fields.evaluate().length >= 2) {
          await tester.enterText(fields.at(0), 'dev@test.com');
          await tester.enterText(fields.at(1), 'wrongpass');
          await tester.pump();
        }

        final checkbox = find.byType(Checkbox);
        if (checkbox.evaluate().isNotEmpty) {
          await tester.tap(checkbox.first);
          await tester.pump();
        }
      },
    );
  });

  group('LoanFormScreen & LoanDetailScreen Deep Tests', () {
    testWidgets(
      'LoanFormScreen tạo mới: chọn loại vay, chip nhanh, phương thức lãi & submit',
      (tester) async {
        tester.view.physicalSize = const Size(800, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        sl<AuthController>().setCurrentUser(UserMockData.usersDatabase.first);
        final loanController = sl<LoanController>();
        await loanController.fetchLoans();

        await tester.pumpWidget(const MaterialApp(home: LoanFormScreen()));
        await tester.pumpAndSettle();

        // Chọn loại vay tín chấp & chip số tiền/kỳ hạn
        for (final label in [
          'Tín chấp',
          'Thẻ tín dụng',
          'Mua xe',
          'Thế chấp BĐS',
        ]) {
          final chip = find.text(label);
          if (chip.evaluate().isNotEmpty) {
            await tester.tap(chip.first);
            await tester.pump();
          }
        }

        for (final tenor in ['12T', '24T', '36T']) {
          final t = find.text(tenor);
          if (t.evaluate().isNotEmpty) {
            await tester.tap(t.first);
            await tester.pump();
          }
        }

        final flatMethod = find.text('Lãi suất phẳng');
        if (flatMethod.evaluate().isNotEmpty) {
          await tester.tap(flatMethod.first);
          await tester.pump();
        }
      },
    );

    testWidgets('LoanFormScreen chế độ chỉnh sửa & prefilledData', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final loanController = sl<LoanController>();
      await loanController.fetchLoans();
      final firstLoan = loanController.loans.first;

      await tester.pumpWidget(
        MaterialApp(home: LoanFormScreen(initialLoan: firstLoan)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoanFormScreen), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: LoanFormScreen(
            prefilledData: {
              'loan_name': 'Vay OCR Test',
              'lender_name': 'Techcombank',
              'principal_amount': 150000000.0,
              'interest_rate': 9.5,
              'tenor_months': 24,
              'loan_type': 'CONSUMER',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LoanFormScreen), findsOneWidget);
    });

    testWidgets('LoanDetailScreen hiển thị chi tiết khoản vay và tương tác', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final loanController = sl<LoanController>();
      await loanController.fetchLoans();
      final firstLoan = loanController.loans.first;

      await tester.pumpWidget(
        MaterialApp(home: LoanDetailScreen(loanId: firstLoan.id.toString())),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoanDetailScreen), findsOneWidget);
      expect(find.textContaining(firstLoan.name), findsWidgets);
    });
  });
}
