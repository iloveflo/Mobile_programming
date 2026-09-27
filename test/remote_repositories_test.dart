import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/network/api_client.dart';
import 'package:my_first_app/models/collateral_model.dart';
import 'package:my_first_app/models/loan_model.dart';
import 'package:my_first_app/repositories/interfaces/auth_repository.dart';
import 'package:my_first_app/repositories/remote/api_auth_repository.dart';
import 'package:my_first_app/repositories/remote/api_loan_repository.dart';

/// Fake ApiClient phục vụ kiểm thử đơn vị Remote Repositories không phụ thuộc server thật
class FakeApiClient extends ApiClient {
  dynamic getResponse;
  dynamic postResponse;
  dynamic putResponse;
  dynamic deleteResponse;
  Exception? throwException;

  String? lastEndpoint;
  dynamic lastBody;

  FakeApiClient() : super(baseUrl: 'http://10.0.2.2:3000/api/v1');

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    lastEndpoint = endpoint;
    if (throwException != null) throw throwException!;
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
    if (throwException != null) throw throwException!;
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
    if (throwException != null) throw throwException!;
    return putResponse;
  }

  @override
  Future<dynamic> delete(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    lastEndpoint = endpoint;
    lastBody = body;
    if (throwException != null) throw throwException!;
    return deleteResponse;
  }
}

void main() {
  group('ApiClient Token & Base URL Tests', () {
    test('Quản lý Bearer Token trong ApiClient', () {
      final client = ApiClient(baseUrl: 'http://test-api.vn');
      expect(client.authToken, isNull);

      client.setAuthToken('jwt_sample_token_123');
      expect(client.authToken, 'jwt_sample_token_123');

      client.clearAuthToken();
      expect(client.authToken, isNull);
    });
  });

  group('ApiAuthRepository Tests', () {
    late FakeApiClient fakeClient;
    late AuthRepository authRepo;

    setUp(() {
      fakeClient = FakeApiClient();
      authRepo = ApiAuthRepository(client: fakeClient);
    });

    test('Đăng nhập thành công và tự động thiết lập Bearer Token vào ApiClient', () async {
      fakeClient.postResponse = {
        'data': {
          'token': 'jwt_real_token_xyz',
          'user': {
            'user_id': 101,
            'full_name': 'Nguyễn Văn Backend',
            'email': 'backend@fincredit.vn',
            'phone': '0988776655',
            'password_hash': 'hash_xyz',
          }
        }
      };

      final user = await authRepo.login(
        identifier: 'backend@fincredit.vn',
        password: 'Password123!',
      );

      expect(user.fullName, 'Nguyễn Văn Backend');
      expect(user.email, 'backend@fincredit.vn');
      expect(fakeClient.authToken, 'jwt_real_token_xyz');
    });

    test('Chuyển đổi lỗi 401 sang InvalidCredentialsException', () async {
      fakeClient.throwException = const ApiException(
        statusCode: 401,
        message: 'Email hoặc mật khẩu không chính xác',
      );

      expect(
        () => authRepo.login(identifier: 'sai@email.com', password: '123'),
        throwsA(isA<InvalidCredentialsException>()),
      );
    });

    test('Đăng xuất thành công tự động xóa Bearer Token khỏi ApiClient', () async {
      fakeClient.setAuthToken('token_can_xoa');
      fakeClient.postResponse = {'success': true};

      await authRepo.logout();
      expect(fakeClient.authToken, isNull);
    });
  });

  group('ApiLoanRepository Tests', () {
    late FakeApiClient fakeClient;
    late ApiLoanRepository loanRepo;

    setUp(() {
      fakeClient = FakeApiClient();
      loanRepo = ApiLoanRepository(client: fakeClient);
    });

    test('Lấy danh sách khoản vay và ánh xạ JSON sang List<LoanModel>', () async {
      fakeClient.getResponse = {
        'data': [
          {
            'loan_id': 201,
            'user_id': 1,
            'loan_type_id': 1,
            'loan_type': 'MORTGAGE',
            'loan_name': 'Vay mua chung cư Times City',
            'lender_name': 'Vietcombank',
            'principal_amount': 1500000000.0,
            'outstanding_amount': 1400000000.0,
            'interest_rate': 0.075,
            'interest_method': 'REDUCING_BALANCE',
            'term_months': 120,
            'start_date': '2026-01-15T00:00:00.000',
            'status': 'ACTIVE',
          }
        ]
      };

      final List<LoanModel> loans = await loanRepo.getLoans();
      expect(loans.length, 1);
      expect(loans.first.id, 201);
      expect(loans.first.lenderName, 'Vietcombank');
      expect(loans.first.loanTypeKey, 'MORTGAGE');
      expect(loans.first.principalAmount, 1500000000.0);
    });

    test('Cập nhật khoản vay sử dụng HTTP PUT', () async {
      fakeClient.putResponse = {
        'loan_id': 201,
        'user_id': 1,
        'loan_type_id': 1,
        'loan_name': 'Vay mua chung cư - Đã đổi kỳ hạn',
        'lender_name': 'Vietcombank',
        'principal_amount': 1500000000.0,
        'outstanding_amount': 1400000000.0,
        'interest_rate': 0.075,
        'interest_method': 'REDUCING_BALANCE',
        'term_months': 180,
        'start_date': '2026-01-15T00:00:00.000',
        'status': 'ACTIVE',
      };

      final updated = await loanRepo.updateLoan('201', {'term_months': 180});
      expect(fakeClient.lastEndpoint, '/api/loans/201');
      expect(updated.termMonths, 180);
    });

    test('Lấy danh sách tài sản bảo đảm ánh xạ chuẩn sang List<CollateralModel>', () async {
      fakeClient.getResponse = {
        'data': [
          {
            'asset_id': 501,
            'user_id': 1,
            'loan_id': 201,
            'asset_name': 'Sổ hồng căn hộ Park 5',
            'asset_type': 'REAL_ESTATE',
            'asset_value': 3200000000.0,
            'valuation_date': '2026-01-10T00:00:00.000',
          }
        ]
      };

      final List<CollateralModel> collaterals = await loanRepo.getCollateralsByLoan('201');
      expect(collaterals.length, 1);
      expect(collaterals.first.id, 501);
      expect(collaterals.first.name, 'Sổ hồng căn hộ Park 5');
      expect(collaterals.first.type, 'REAL_ESTATE');
      expect(collaterals.first.value, 3200000000.0);
    });
  });
}

