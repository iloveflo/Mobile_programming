import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/network/api_client.dart';
import 'package:my_first_app/models/notification_preference_model.dart';
import 'package:my_first_app/models/simulation_model.dart';
import 'package:my_first_app/repositories/remote/api_auth_repository.dart';
import 'package:my_first_app/repositories/remote/api_credit_profile_repository.dart';
import 'package:my_first_app/repositories/remote/api_credit_report_repository.dart';
import 'package:my_first_app/repositories/remote/api_debt_strategy_repository.dart';
import 'package:my_first_app/repositories/remote/api_loan_repository.dart';
import 'package:my_first_app/repositories/remote/api_payment_schedule_repository.dart';
import 'package:my_first_app/repositories/remote/api_simulation_repository.dart';
import 'package:my_first_app/repositories/remote/api_storage_repository.dart';
import 'package:my_first_app/services/session_storage_service.dart';

class _MemorySessionStorage extends SessionStorageService {
  @override
  Future<void> saveSession({
    dynamic token,
    dynamic user,
    String? identifier,
  }) async {}

  @override
  Future<void> clearSession({bool keepMemoryCache = false}) async {}
}

class _FullFakeApiClient extends ApiClient {
  dynamic getResponse;
  dynamic postResponse;
  dynamic putResponse;
  dynamic patchResponse;
  dynamic deleteResponse;
  List<int> bytesResponse = const [1, 2, 3];
  bool uploadBinaryResult = true;
  Object? throwError;
  int getCalls = 0;

  String? lastEndpoint;
  dynamic lastBody;
  Map<String, dynamic>? lastQueryParams;
  Map<String, String>? lastHeaders;

  _FullFakeApiClient() : super(baseUrl: 'http://127.0.0.1:3000/api/v1');

  void _maybeThrow() {
    if (throwError != null) throw throwError!;
  }

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    getCalls++;
    lastEndpoint = endpoint;
    lastHeaders = headers;
    lastQueryParams = queryParams;
    _maybeThrow();
    return getResponse;
  }

  @override
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    lastEndpoint = endpoint;
    lastBody = body;
    lastHeaders = headers;
    _maybeThrow();
    return postResponse;
  }

  @override
  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    lastEndpoint = endpoint;
    lastBody = body;
    lastHeaders = headers;
    _maybeThrow();
    return putResponse;
  }

  @override
  Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    lastEndpoint = endpoint;
    lastBody = body;
    lastHeaders = headers;
    _maybeThrow();
    return patchResponse;
  }

  @override
  Future<dynamic> delete(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    lastEndpoint = endpoint;
    lastBody = body;
    lastHeaders = headers;
    _maybeThrow();
    return deleteResponse;
  }

  @override
  Future<List<int>> getBytes(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    lastEndpoint = endpoint;
    lastHeaders = headers;
    lastQueryParams = queryParams;
    _maybeThrow();
    return bytesResponse;
  }

  @override
  Future<bool> uploadBinary(
    Uri uploadUrl,
    List<int> bytes, {
    String contentType = 'image/jpeg',
    Map<String, String>? extraHeaders,
  }) async {
    _maybeThrow();
    return uploadBinaryResult;
  }
}

void main() {
  late _FullFakeApiClient client;

  setUp(() {
    client = _FullFakeApiClient();
  });

  group('ApiCreditProfileRepository', () {
    late ApiCreditProfileRepository repo;
    setUp(() => repo = ApiCreditProfileRepository(client: client));

    test('getCreditProfile parses data and returns null on 404', () async {
      client.getResponse = {
        'data': {
          'profile_id': 1,
          'user_id': 10,
          'total_debt': 50000000.0,
          'monthly_income': 20000000.0,
          'monthly_debt_payment': 4000000.0,
          'dti_ratio': 20.0,
          'credit_score': 750,
          'risk_level': 'LOW',
        },
      };
      final profile = await repo.getCreditProfile(userId: 10);
      expect(profile, isNotNull);
      expect(profile!.creditScore, 750);
      expect(client.lastQueryParams, {'user_id': '10'});

      client.throwError = const ApiException(
        statusCode: 404,
        message: 'Not found',
      );
      expect(await repo.getCreditProfile(), isNull);
    });

    test(
      'recalculateCreditProfile & error mappings (401/403/500/Socket/Timeout)',
      () async {
        client.postResponse = {
          'data': {
            'profile_id': 2,
            'user_id': 10,
            'total_debt': 40000000.0,
            'monthly_income': 25000000.0,
            'monthly_debt_payment': 3000000.0,
            'dti_ratio': 12.0,
            'credit_score': 780,
            'risk_level': 'LOW',
          },
        };
        final updated = await repo.recalculateCreditProfile(userId: 10);
        expect(updated.creditScore, 780);
        expect(client.lastEndpoint, '/credit-profile/recalculate');

        for (final err in <Object>[
          const ApiException(statusCode: 401, message: 'unauth'),
          const ApiException(statusCode: 403, message: 'forbidden'),
          const ApiException(statusCode: 500, message: 'server'),
          const SocketException('no net'),
          TimeoutException('timeout'),
        ]) {
          client.throwError = err;
          await expectLater(repo.recalculateCreditProfile(), throwsException);
        }
      },
    );
  });

  group('ApiCreditReportRepository', () {
    late ApiCreditReportRepository repo;
    setUp(() => repo = ApiCreditReportRepository(client: client));

    test(
      'getCreditReports, getCreditReportDetail, generateReport, deleteReport',
      () async {
        final sampleReport = {
          'report_id': 11,
          'user_id': 1,
          'report_period': '2026-11',
          'credit_score': 740,
          'dti_ratio': 25.0,
          'total_debt': 100000000.0,
          'risk_level': 'LOW',
          'generated_at': '2026-11-28T10:00:00.000Z',
        };

        client.getResponse = {
          'data': [sampleReport],
        };
        final list = await repo.getCreditReports(userId: 1);
        expect(list.length, 1);
        expect(list.first.id, 11);

        client.getResponse = {'data': sampleReport};
        final detail = await repo.getCreditReportDetail(11, userId: 1);
        expect(detail?.reportPeriod, '2026-11');

        client.postResponse = {'data': sampleReport};
        final generated = await repo.generateReport(
          userId: 1,
          reportPeriod: '2026-11',
        );
        expect(generated.creditScore, 740);
        expect(client.lastEndpoint, '/credit-reports/generate');

        await repo.deleteReport(11);
        expect(client.lastEndpoint, '/credit-reports/11');

        client.throwError = const ApiException(statusCode: 409, message: 'dup');
        await expectLater(
          repo.generateReport(reportPeriod: '2026-11'),
          throwsException,
        );
      },
    );
  });

  group('ApiDebtStrategyRepository', () {
    late ApiDebtStrategyRepository repo;
    setUp(() => repo = ApiDebtStrategyRepository(client: client));

    test(
      'getStrategies, getActiveStrategy, applyStrategy, cancelStrategy',
      () async {
        final sampleStrategy = {
          'strategy_id': 5,
          'user_id': 1,
          'strategy_type': 'AVALANCHE',
          'extra_payment': 2000000.0,
          'estimated_interest_saved': 15000000.0,
          'estimated_months_saved': 6,
          'status': 'ACTIVE',
        };

        client.getResponse = {
          'data': [sampleStrategy],
        };
        final list = await repo.getStrategies(userId: 1);
        expect(list.length, 1);
        expect(list.first.strategyType, 'AVALANCHE');

        client.getResponse = {'data': sampleStrategy};
        final active = await repo.getActiveStrategy(userId: 1);
        expect(active?.id, 5);

        client.throwError = const ApiException(
          statusCode: 404,
          message: 'none',
        );
        expect(await repo.getActiveStrategy(userId: 1), isNull);
        client.throwError = null;

        client.postResponse = {'data': sampleStrategy};
        final applied = await repo.applyStrategy(
          userId: 1,
          strategyType: 'AVALANCHE',
          extraPayment: 2000000,
          estimatedInterestSaved: 15000000,
          estimatedMonthsSaved: 6,
        );
        expect(applied.id, 5);
        expect(client.lastEndpoint, '/debt-strategies/apply');

        await repo.cancelStrategy(5);
        expect(client.lastEndpoint, '/debt-strategies/5/cancel');
      },
    );
  });

  group('ApiSimulationRepository', () {
    late ApiSimulationRepository repo;
    setUp(() => repo = ApiSimulationRepository(client: client));

    test('getSimulations, saveSimulation, deleteSimulation', () async {
      final sampleSim = {
        'simulation_id': 9,
        'user_id': 1,
        'loan_id': 101,
        'scenario_type': 'EXTRA_PAYMENT',
        'extra_payment': 1000000.0,
        'estimated_interest': 9500000.0,
        'estimated_interest_saved': 2500000.0,
        'months_reduced': 3,
        'total_saving': 2500000.0,
        'created_at': '2026-11-28T10:00:00.000Z',
      };

      client.getResponse = {
        'data': [sampleSim],
      };
      final sims = await repo.getSimulations(userId: 1, loanId: 101);
      expect(sims.length, 1);
      expect(sims.first.id, 9);

      client.postResponse = {'data': sampleSim};
      final saved = await repo.saveSimulation(
        SimulationModel.fromJson(sampleSim),
      );
      expect(saved.estimatedInterestSaved, 2500000.0);

      await repo.deleteSimulation(9);
      expect(client.lastEndpoint, '/simulations/9');
    });
  });

  group('ApiStorageRepository', () {
    late ApiStorageRepository repo;
    setUp(() => repo = ApiStorageRepository(client: client));

    test('uploadImageFile full flow (success & upload failure)', () async {
      client.postResponse = {
        'data': {
          'upload_url': 'https://r2.example.com/upload',
          'file_key': 'ekyc/front.jpg',
          'download_url': 'https://cdn.example.com/ekyc/front.jpg',
          'headers': {'x-amz-acl': 'private'},
        },
      };
      final okResult = await repo.uploadImageFile(
        bytes: [1, 2, 3, 4],
        folder: 'ekyc',
        fileName: 'front.jpg',
        contentType: 'image/jpeg',
      );
      expect(okResult.isSuccess, isTrue);
      expect(okResult.fileKey, 'ekyc/front.jpg');

      client.uploadBinaryResult = false;
      final failResult = await repo.uploadImageFile(
        bytes: [1, 2],
        folder: 'ekyc',
        fileName: 'front.jpg',
        contentType: 'image/jpeg',
      );
      expect(failResult.isSuccess, isFalse);
    });

    test(
      'getPresignedViewUrl caches URL, handles http passthrough, list & delete',
      () async {
        expect(
          await repo.getPresignedViewUrl(fileKey: 'https://cdn.test/a.png'),
          'https://cdn.test/a.png',
        );

        client.getResponse = {'view_url': 'https://signed.test/a.png?sig=1'};
        final url1 = await repo.getPresignedViewUrl(fileKey: 'ekyc/a.png');
        final url2 = await repo.getPresignedViewUrl(fileKey: 'ekyc/a.png');
        expect(url1, 'https://signed.test/a.png?sig=1');
        expect(url2, url1);
        expect(client.getCalls, 1);

        repo.clearViewUrlCache();
        await repo.getPresignedViewUrl(fileKey: 'ekyc/a.png');
        expect(client.getCalls, 2);

        client.getResponse = {
          'data': [
            {'file_key': 'ekyc/a.png'},
          ],
        };
        final files = await repo.listUploadedFiles(folder: 'ekyc');
        expect(files.length, 1);

        await repo.deleteFile('ekyc/a.png');
        expect(client.lastEndpoint, '/api/storage/file?file_key=ekyc%2Fa.png');
      },
    );
  });

  group('ApiPaymentScheduleRepository', () {
    late ApiPaymentScheduleRepository repo;
    setUp(() => repo = ApiPaymentScheduleRepository(client: client));

    test(
      'schedules CRUD, pagination, notifications & preference validation',
      () async {
        final scheduleJson = {
          'schedule_id': 1,
          'loan_id': 101,
          'installment_number': 1,
          'due_date': '2026-12-01',
          'principal_amount': 1000000.0,
          'interest_amount': 100000.0,
          'fee_amount': 0.0,
          'total_amount': 1100000.0,
          'remaining_balance': 9000000.0,
          'status': 'PENDING',
        };

        client.getResponse = {
          'data': [scheduleJson],
        };
        expect((await repo.getPaymentSchedules(userId: 1)).length, 1);

        client.getResponse = {
          'data': {
            'data': [scheduleJson],
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 1,
              'has_more': false,
            },
            'summary': {'total_count': 1, 'pending_count': 1},
          },
        };
        final page = await repo.getPaymentSchedulesPage(userId: 1);
        expect(page.items.length, 1);
        expect(page.total, 1);

        client.getResponse = {'data': scheduleJson};
        expect((await repo.getScheduleDetail(1))?.id, 1);

        client.postResponse = {
          'data': {...scheduleJson, 'status': 'PAID'},
        };
        final paid = await repo.markScheduleAsPaid(1, userId: 1);
        expect(paid.status, 'PAID');

        client.getResponse = null;
        final defaultPref = await repo.getNotificationPreference(userId: 1);
        expect(defaultPref.pushEnabled, isTrue);

        await expectLater(
          repo.updateNotificationPreference(
            const NotificationPreferenceModel(
              id: 1,
              userId: 1,
              pushEnabled: true,
              emailEnabled: true,
              reminderDays: 3,
            ),
            userEmail: '',
          ),
          throwsException,
        );

        client.putResponse = {
          'data': {
            'preference_id': 1,
            'user_id': 1,
            'push_enabled': true,
            'email_enabled': true,
            'reminder_days': 5,
          },
        };
        final updatedPref = await repo.updateNotificationPreference(
          const NotificationPreferenceModel(
            id: 1,
            userId: 1,
            pushEnabled: true,
            emailEnabled: true,
            reminderDays: 5,
          ),
          userEmail: 'a@b.com',
        );
        expect(updatedPref.reminderDays, 5);

        client.getResponse = {
          'data': [
            {
              'notification_id': 7,
              'user_id': 1,
              'type': 'DUE_SOON',
              'channel': 'PUSH',
              'title': 'Nhắc nợ',
              'message': 'Đến hạn',
              'status': 'SENT',
              'scheduled_at': '2026-11-28T08:00:00.000Z',
            },
          ],
        };
        expect((await repo.getNotifications(userId: 1)).length, 1);

        await repo.deleteNotification(7);
        expect(client.lastEndpoint, '/notifications/7');
        await repo.clearNotifications();
        expect(client.lastEndpoint, '/notifications');

        client.postResponse = {'cancelled_count': 2};
        expect(await repo.syncSchedulesAndNotifications(userId: 1), 2);
      },
    );
  });

  group('ApiAuthRepository & ApiLoanRepository remaining methods', () {
    test(
      'ApiAuthRepository register, OTP, reset/change password, sessions, eKYC, PDF',
      () async {
        final authRepo = ApiAuthRepository(
          client: client,
          sessionStorage: _MemorySessionStorage(),
        );

        client.postResponse = {
          'data': {'challenge_token': 'chal_1'},
        };
        await authRepo.register({
          'email': 'new@test.com',
          'password': 'Password123!',
        });
        expect(client.lastEndpoint, '/api/auth/register');

        client.postResponse = {
          'success': true,
          'data': {
            'token': 'jwt_abc',
            'refreshToken': 'ref_abc',
            'reset_token': 'rst_1',
            'user': {
              'user_id': 1,
              'full_name': 'New User',
              'email': 'new@test.com',
            },
          },
        };
        expect(
          await authRepo.verifyOtp(otp: '123456', flowType: 'REGISTER'),
          isTrue,
        );
        expect(client.authToken, 'jwt_abc');

        await authRepo.requestForgotPasswordOtp('new@test.com');
        await authRepo.resendOtp();
        await authRepo.resetPassword(newPassword: 'NewPassword123!');
        await authRepo.changePassword(
          currentPassword: 'NewPassword123!',
          newPassword: 'NewPassword456!',
        );
        expect(client.lastEndpoint, '/api/auth/change-password');

        client.getResponse = {
          'data': [
            {
              'session_id': 'sess_1',
              'device_name': 'Pixel 8',
              'platform': 'Android',
              'is_current': true,
              'created_at': '2026-11-28T10:00:00.000Z',
            },
          ],
        };
        final sessions = await authRepo.getActiveSessions();
        expect(sessions.length, 1);
        await authRepo.revokeSession('sess_1');
        expect(client.lastEndpoint, '/api/auth/sessions/sess_1');

        client.getResponse = {
          'data': {'pdf_url': 'https://cdn.test/profile.pdf'},
        };
        expect(
          await authRepo.exportFinancialProfilePdf(),
          'https://cdn.test/profile.pdf',
        );
        expect(await authRepo.downloadFinancialProfilePdfBytes(), [1, 2, 3]);

        client.postResponse = {
          'data': {
            'user_id': 1,
            'full_name': 'New User',
            'email': 'new@test.com',
            'is_ekyc_verified': true,
          },
        };
        final verified = await authRepo.verifyEkyc(
          idCardNumber: '001200001234',
          frontCardUrl: 'ekyc/f.jpg',
          backCardUrl: 'ekyc/b.jpg',
        );
        expect(verified.isEkycVerified, isTrue);
      },
    );

    test(
      'ApiLoanRepository detail, create, delete, collaterals, ocr, documents',
      () async {
        final loanRepo = ApiLoanRepository(client: client);
        final loanJson = {
          'loan_id': 301,
          'user_id': 1,
          'loan_type_id': 1,
          'loan_name': 'Vay mua xe',
          'lender_name': 'TPBank',
          'principal_amount': 300000000.0,
          'outstanding_amount': 280000000.0,
          'interest_rate': 9.5,
          'interest_method': 'REDUCING_BALANCE',
          'term_months': 48,
          'start_date': '2026-11-01',
          'status': 'ACTIVE',
        };

        client.getResponse = {'data': loanJson};
        expect((await loanRepo.getLoanDetail('301')).id, 301);

        client.postResponse = {'data': loanJson};
        expect((await loanRepo.createLoan(loanJson)).id, 301);

        await loanRepo.deleteLoan('301', softDelete: false);
        expect(client.lastEndpoint, '/api/loans/301');

        client.postResponse = {
          'data': {
            'asset_id': 77,
            'user_id': 1,
            'loan_id': 301,
            'asset_name': 'Xe Mazda 3',
            'asset_type': 'VEHICLE',
            'asset_value': 600000000.0,
          },
        };
        final col = await loanRepo.addCollateral({
          'loan_id': 301,
          'name': 'Xe Mazda 3',
          'type': 'VEHICLE',
          'value': 600000000.0,
        });
        expect(col.id, 77);

        await loanRepo.deleteCollateral(77);
        expect(client.lastEndpoint, '/api/collaterals/77');

        client.postResponse = {'confidence_score': 0.95};
        expect(
          (await loanRepo.scanDocumentOcr('/tmp/doc.jpg'))['confidence_score'],
          0.95,
        );

        client.getResponse = {
          'data': [
            {
              'document_id': 12,
              'loan_id': 301,
              'file_key': 'loans/301/hd.pdf',
              'document_type': 'CONTRACT',
              'uploaded_at': '2026-11-28T10:00:00.000Z',
            },
          ],
        };
        final docs = await loanRepo.getLoanDocuments('301');
        expect(docs.length, 1);
        expect(docs.first.id, 12);
      },
    );
  });
}
