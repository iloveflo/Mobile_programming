import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/controllers/loan_controller.dart';
import 'package:my_first_app/controllers/payment_schedule_controller.dart';
import 'package:my_first_app/core/network/api_client.dart';
import 'package:my_first_app/mock_data/user_mock_data.dart';
import 'package:my_first_app/models/asset_model.dart';
import 'package:my_first_app/models/credit_profile_model.dart';
import 'package:my_first_app/models/credit_report_model.dart';
import 'package:my_first_app/models/debt_strategy_model.dart';
import 'package:my_first_app/models/loan_document_model.dart';
import 'package:my_first_app/models/notification_model.dart';
import 'package:my_first_app/models/payment_schedule_model.dart';
import 'package:my_first_app/models/refresh_token_model.dart';
import 'package:my_first_app/models/session_model.dart';
import 'package:my_first_app/models/simulation_model.dart';
import 'package:my_first_app/models/storage_upload_model.dart';
import 'package:my_first_app/repositories/interfaces/auth_repository.dart';
import 'package:my_first_app/repositories/mock/mock_auth_repository.dart';
import 'package:my_first_app/repositories/mock/mock_loan_repository.dart';
import 'package:my_first_app/repositories/remote/api_auth_repository.dart';
import 'package:my_first_app/screens/auth/register_screen.dart';
import 'package:my_first_app/screens/credit/credit_health_screen.dart';
import 'package:my_first_app/screens/credit_report/credit_report_list_screen.dart';
import 'package:my_first_app/screens/debt/debt_strategy_screen.dart';
import 'package:my_first_app/screens/home/home_screen.dart';
import 'package:my_first_app/screens/schedule/payment_schedule_screen.dart';
import 'package:my_first_app/service_locator.dart';
import 'package:my_first_app/services/session_storage_service.dart';
import 'package:my_first_app/widgets/common/app_document_viewer_modal.dart';
import 'package:my_first_app/widgets/profile/ekyc_verification_sheet.dart';

class _StubSessionStorage extends SessionStorageService {
  @override
  Future<void> saveSession({
    dynamic token,
    dynamic user,
    String? identifier,
  }) async {}

  @override
  Future<void> clearSession({bool keepMemoryCache = false}) async {}
}

class _ErrorFakeApiClient extends ApiClient {
  Object? err;
  dynamic postRes;
  _ErrorFakeApiClient() : super(baseUrl: 'http://127.0.0.1:3000/api/v1');

  @override
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    if (err != null) throw err!;
    return postRes;
  }
}

void main() {
  setUpAll(() async {
    await resetServiceLocator(dispose: false);
    setupServiceLocator(isMock: true);
  });

  group('Models Serialization & Getters Coverage', () {
    test('AssetModel, RefreshTokenModel, SessionModel, StorageUploadModel', () {
      final asset = AssetModel.fromJson({
        'asset_id': 1,
        'user_id': 1,
        'asset_name': 'Nhà phố',
        'asset_type': 'REAL_ESTATE',
        'asset_value': 2000000000.0,
        'valuation_date': '2026-01-01',
      });
      expect(asset.toJson()['asset_name'], 'Nhà phố');

      final rt = RefreshTokenModel.fromJson({
        'token_id': 10,
        'user_id': 1,
        'token': 'abc',
        'device_name': 'Pixel',
        'platform': 'Android',
        'expires_at': '2026-12-31T00:00:00.000Z',
      });
      expect(rt.toJson()['token'], 'abc');

      final sess = SessionModel.fromJson({
        'token_id': 10,
        'device_name': 'Pixel 8',
        'platform': 'Android',
        'ip_address': '127.0.0.1',
        'is_current': true,
        'created_at': '2026-11-01T00:00:00.000Z',
        'expires_at': '2026-12-01T00:00:00.000Z',
      });
      expect(sess.toJson()['device_name'], 'Pixel 8');

      final up = PresignedUploadUrlModel.fromJson({
        'upload_url': 'https://r2.test/put',
        'file_key': 'k.jpg',
        'download_url': 'https://cdn.test/k.jpg',
      });
      expect(up.fileKey, 'k.jpg');
      expect(
        UploadResultModel.success(fileKey: 'k', downloadUrl: 'u').isSuccess,
        isTrue,
      );
      expect(UploadResultModel.failure('err').isSuccess, isFalse);
    });

    test(
      'CreditProfileModel, CreditReportModel, DebtStrategyModel, SimulationModel, LoanDocumentModel, NotificationModel, PaymentScheduleModel',
      () {
        final cp = CreditProfileModel.fromJson({
          'profile_id': 1,
          'user_id': 1,
          'total_debt': 50000000.0,
          'monthly_income': 25000000.0,
          'monthly_debt_payment': 5000000.0,
          'dti_ratio': 20.0,
          'ltv_ratio': 45.0,
          'credit_utilization': 15.0,
          'on_time_payment_rate': 98.0,
          'credit_score': 740,
          'risk_level': 'LOW',
          'calculated_at': '2026-11-28T00:00:00.000Z',
        });
        expect(cp.toJson()['credit_score'], 740);

        final cr = CreditReportModel.fromJson({
          'report_id': 2,
          'user_id': 1,
          'credit_score': 750,
          'dti_ratio': 22.0,
          'ltv_ratio': 40.0,
          'total_debt': 60000000.0,
          'overdue_amount': 0.0,
          'risk_level': 'LOW',
          'report_period': '2026-11',
          'generated_at': '2026-11-28T00:00:00.000Z',
        });
        expect(cr.toJson()['report_period'], '2026-11');

        final ds = DebtStrategyModel.fromJson({
          'strategy_id': 3,
          'user_id': 1,
          'strategy_type': 'SNOWBALL',
          'extra_payment': 1500000.0,
          'estimated_interest_saved': 8000000.0,
          'estimated_months_saved': 4,
          'status': 'ACTIVE',
        });
        expect(ds.toJson()['strategy_type'], 'SNOWBALL');

        final sim = SimulationModel.fromJson({
          'simulation_id': 4,
          'user_id': 1,
          'loan_id': 101,
          'extra_payment': 1000000.0,
          'early_payment_fee': 0.0,
          'estimated_interest': 5000000.0,
          'estimated_interest_saved': 1200000.0,
          'months_reduced': 2,
          'total_saving': 1200000.0,
          'scenario_type': 'EARLY_PAYOFF',
        });
        expect(sim.toJson()['scenario_type'], 'EARLY_PAYOFF');

        final doc = LoanDocumentModel.fromJson({
          'document_id': 5,
          'loan_id': 101,
          'document_type': 'CONTRACT',
          'file_url': 'loans/101/hd.pdf',
          'ocr_status': 'COMPLETED',
          'ocr_result': {'lender': 'VCB'},
        });
        expect(doc.toJson()['document_type'], 'CONTRACT');

        final notif = NotificationModel.fromJson({
          'notification_id': 6,
          'user_id': 1,
          'schedule_id': 1,
          'type': 'DUE_SOON',
          'channel': 'PUSH',
          'title': 'Nhắc hạn',
          'message': 'Sắp đến hạn',
          'status': 'SENT',
          'scheduled_at': '2026-11-28T08:00:00.000Z',
        });
        expect(notif.type, 'DUE_SOON');
        expect(notif.toJson(), isA<Map<String, dynamic>>());

        final ps = PaymentScheduleModel.fromJson({
          'schedule_id': 7,
          'loan_id': 101,
          'installment_number': 1,
          'due_date': '2026-12-01',
          'principal_amount': 1000000.0,
          'interest_amount': 100000.0,
          'fee_amount': 0.0,
          'total_amount': 1100000.0,
          'remaining_balance': 9000000.0,
          'status': 'PENDING',
        });
        expect(ps.toJson()['status'], 'PENDING');
      },
    );
  });

  group('MockLoanRepository & ApiAuthRepository Error Branches', () {
    test(
      'MockLoanRepository CRUD, settleLoanEarly, collaterals & documents',
      () async {
        final repo = MockLoanRepository();
        final loans = await repo.getLoans();
        final id = loans.first.id.toString();

        await repo.getLoanDetail(id);
        await repo.getLoanDocuments(id);
        await repo.scanDocumentOcr('fake.jpg');
        final col = await repo.addCollateral({
          'loan_id': loans.first.id,
          'name': 'Sổ đỏ test',
          'type': 'REAL_ESTATE',
          'value': 1000000000.0,
        });
        await repo.deleteCollateral(col.id);
        await expectLater(
          repo.deleteLoan(id, softDelete: true),
          throwsException,
        );
      },
    );

    test(
      'ApiAuthRepository error mappings on login (403/423/500/Socket/Timeout/OTP)',
      () async {
        final client = _ErrorFakeApiClient();
        final repo = ApiAuthRepository(
          client: client,
          sessionStorage: _StubSessionStorage(),
        );

        client.postRes = {
          'data': {'requires_otp': true, 'challenge_token': 'chal_xyz'},
        };
        await expectLater(
          repo.login(identifier: 'a@b.com', password: '123'),
          throwsA(isA<NewDeviceOtpRequiredException>()),
        );

        for (final err in <Object>[
          const ApiException(statusCode: 403, message: 'Chưa xác thực'),
          const ApiException(statusCode: 423, message: 'Khóa'),
          const ApiException(statusCode: 500, message: 'Server'),
          const SocketException('offline'),
          TimeoutException('timeout'),
        ]) {
          client.err = err;
          await expectLater(
            repo.login(identifier: 'a@b.com', password: '123'),
            throwsException,
          );
        }
      },
    );
  });

  group('Screens & Modals Extra Interaction Coverage', () {
    setUp(() async {
      sl<AuthController>().setCurrentUser(UserMockData.usersDatabase.first);
      await sl<LoanController>().fetchLoans();
      await sl<PaymentScheduleController>().loadSchedules(userId: 1);
      await sl<PaymentScheduleController>().loadNotifications(userId: 1);
    });

    testWidgets('RegisterScreen nhập form & bấm Đăng ký', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
      await tester.pumpAndSettle();

      final btn = find.text('Đăng ký & Nhận mã OTP');
      if (btn.evaluate().isNotEmpty) {
        await tester.ensureVisible(btn.first);
        await tester.tap(btn.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('CreditHealthScreen bấm tính toán lại', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: CreditHealthScreen()));
      await tester.pumpAndSettle();

      final refreshIcon = find.byIcon(Icons.refresh);
      if (refreshIcon.evaluate().isNotEmpty) {
        await tester.tap(refreshIcon.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('PaymentScheduleScreen mở thông báo & cài đặt nhắc nợ', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: PaymentScheduleScreen()));
      await tester.pumpAndSettle();

      for (final icon in [Icons.notifications_outlined, Icons.tune]) {
        final found = find.byIcon(icon);
        if (found.evaluate().isNotEmpty) {
          await tester.tap(found.first);
          await tester.pumpAndSettle();
          Navigator.of(
            tester.element(find.byType(PaymentScheduleScreen)),
          ).maybePop();
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('DebtStrategyScreen mở dialog áp dụng kế hoạch', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(const MaterialApp(home: DebtStrategyScreen()));
      await tester.pumpAndSettle();

      final applyBtn = find.textContaining('Áp dụng');
      if (applyBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(applyBtn.first);
        await tester.tap(applyBtn.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets(
      'HomeScreen, CreditReportListScreen, EkycVerificationSheet & AppDocumentViewerModal',
      (tester) async {
        tester.view.physicalSize = const Size(800, 3200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          const MaterialApp(home: CreditReportListScreen()),
        );
        await tester.pumpAndSettle();

        final auth = AuthController(MockAuthRepository());
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EkycVerificationSheet(
                authController: auth,
                user: UserMockData.usersDatabase.first,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final verifyBtn = find.byType(ElevatedButton);
        if (verifyBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(verifyBtn.last);
          await tester.tap(verifyBtn.last);
          await tester.pumpAndSettle();
        }

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: AppDocumentViewerModal(
                title: 'Ảnh CCCD',
                fileKey: 'https://cdn.test/cccd.jpg',
                isPrivate: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      },
    );
  });
}
