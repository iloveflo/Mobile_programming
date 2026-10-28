import 'package:get_it/get_it.dart';

import 'controllers/auth_controller.dart';
import 'controllers/credit_profile_controller.dart';
import 'controllers/credit_report_controller.dart';
import 'controllers/debt_strategy_controller.dart';
import 'controllers/loan_controller.dart';
import 'controllers/payment_schedule_controller.dart';
import 'controllers/simulation_controller.dart';
import 'core/config/app_env.dart';
import 'core/network/api_client.dart';
import 'repositories/interfaces/auth_repository.dart';
import 'repositories/interfaces/credit_profile_repository.dart';
import 'repositories/interfaces/credit_report_repository.dart';
import 'repositories/interfaces/debt_strategy_repository.dart';
import 'repositories/interfaces/loan_repository.dart';
import 'repositories/interfaces/payment_schedule_repository.dart';
import 'repositories/interfaces/simulation_repository.dart';
import 'repositories/mock/mock_auth_repository.dart';
import 'repositories/mock/mock_credit_profile_repository.dart';
import 'repositories/mock/mock_credit_report_repository.dart';
import 'repositories/mock/mock_debt_strategy_repository.dart';
import 'repositories/mock/mock_loan_repository.dart';
import 'repositories/mock/mock_payment_schedule_repository.dart';
import 'repositories/mock/mock_simulation_repository.dart';
import 'repositories/remote/api_auth_repository.dart';
import 'repositories/remote/api_credit_profile_repository.dart';
import 'repositories/remote/api_credit_report_repository.dart';
import 'repositories/remote/api_debt_strategy_repository.dart';
import 'repositories/remote/api_loan_repository.dart';
import 'repositories/remote/api_payment_schedule_repository.dart';
import 'repositories/remote/api_simulation_repository.dart';

/// Service Locator trung tâm quản lý Dependency Injection cho toàn ứng dụng FinCredit
final GetIt sl = GetIt.instance;

// =========================================================================
// CÔNG TẮC MẶC ĐỊNH HỆ THỐNG:
// - Chế độ tĩnh: true (Mock Data) / false (Backend API thật)
// - Đồng bộ theo cấu hình môi trường AppEnv.useMock (--dart-define=USE_MOCK=false)
// =========================================================================
const bool defaultIsMock = AppEnv.useMock;

/// Khởi tạo và đăng ký các dịch vụ (Core, Repositories, Controllers)
///
/// Tham số [isMock]:
/// - `null`: Tự động sử dụng cấu hình môi trường [defaultIsMock]
/// - `true`: Bắt buộc sử dụng Mock Data
/// - `false`: Bắt buộc gọi Backend API thật qua ApiClient
void setupServiceLocator({bool? isMock}) {
  final bool useMockMode = isMock ?? defaultIsMock;

  // =========================================================================
  // 1. TẦNG CORE & NETWORK
  // =========================================================================
  _registerLazySingletonIfNot<ApiClient>(
    () => ApiClient(baseUrl: AppEnv.baseUrl),
  );

  // =========================================================================
  // 2. TẦNG DATA & REPOSITORIES (Tự động hoán đổi theo useMockMode)
  // =========================================================================
  if (useMockMode) {
    // A. Xác thực & Bảo mật (Mock)
    _registerLazySingletonIfNot<AuthRepository>(() => MockAuthRepository());

    // B. Quản lý Khoản vay (Mock)
    _registerLazySingletonIfNot<LoanRepository>(() => MockLoanRepository());

    // C. Tối ưu Trả nợ (Mock)
    _registerLazySingletonIfNot<DebtStrategyRepository>(
      () => MockDebtStrategyRepository(),
    );

    // D. Mô phỏng Trả nợ (Mock)
    _registerLazySingletonIfNot<SimulationRepository>(
      () => MockSimulationRepository(),
    );

    // E. Sức khỏe Tín dụng (Mock)
    _registerLazySingletonIfNot<CreditProfileRepository>(
      () => MockCreditProfileRepository(),
    );

    // F. Báo cáo Tín dụng Định kỳ (Mock)
    _registerLazySingletonIfNot<CreditReportRepository>(
      () => MockCreditReportRepository(),
    );

    // G. Lịch phân kỳ & Nhắc nợ (Mock)
    _registerLazySingletonIfNot<PaymentScheduleRepository>(
      () => MockPaymentScheduleRepository(),
    );
  } else {
    // A. Xác thực & Bảo mật (API Thật)
    _registerLazySingletonIfNot<AuthRepository>(
      () => ApiAuthRepository(client: sl<ApiClient>()),
    );

    // B. Quản lý Khoản vay (API Thật)
    _registerLazySingletonIfNot<LoanRepository>(
      () => ApiLoanRepository(client: sl<ApiClient>()),
    );

    // C. Tối ưu Trả nợ (API Thật)
    _registerLazySingletonIfNot<DebtStrategyRepository>(
      () => ApiDebtStrategyRepository(client: sl<ApiClient>()),
    );

    // D. Mô phỏng Trả nợ (API Thật)
    _registerLazySingletonIfNot<SimulationRepository>(
      () => ApiSimulationRepository(client: sl<ApiClient>()),
    );

    // E. Sức khỏe Tín dụng (API Thật)
    _registerLazySingletonIfNot<CreditProfileRepository>(
      () => ApiCreditProfileRepository(client: sl<ApiClient>()),
    );

    // F. Báo cáo Tín dụng Định kỳ (API Thật)
    _registerLazySingletonIfNot<CreditReportRepository>(
      () => ApiCreditReportRepository(client: sl<ApiClient>()),
    );

    // G. Lịch phân kỳ & Nhắc nợ (API Thật)
    _registerLazySingletonIfNot<PaymentScheduleRepository>(
      () => ApiPaymentScheduleRepository(client: sl<ApiClient>()),
    );
  }

  // =========================================================================
  // 3. TẦNG CONTROLLERS / STATE MANAGEMENT
  // =========================================================================
  _registerLazySingletonIfNot<AuthController>(
    () => AuthController(sl<AuthRepository>()),
  );

  _registerLazySingletonIfNot<LoanController>(
    () => LoanController(sl<LoanRepository>()),
  );

  _registerLazySingletonIfNot<DebtStrategyController>(
    () => DebtStrategyController(
      sl<DebtStrategyRepository>(),
      sl<LoanRepository>(),
    ),
  );

  _registerLazySingletonIfNot<SimulationController>(
    () =>
        SimulationController(sl<SimulationRepository>(), sl<LoanRepository>()),
  );

  _registerLazySingletonIfNot<CreditProfileController>(
    () => CreditProfileController(
      sl<CreditProfileRepository>(),
      sl<LoanRepository>(),
    ),
  );

  _registerLazySingletonIfNot<CreditReportController>(
    () => CreditReportController(sl<CreditReportRepository>()),
  );

  _registerLazySingletonIfNot<PaymentScheduleController>(
    () => PaymentScheduleController(sl<PaymentScheduleRepository>()),
  );
}

/// Chuyển đổi linh hoạt giữa chế độ Mock Data và API thật ngay khi ứng dụng đang chạy
Future<void> switchServiceLocatorMode({required bool isMock}) async {
  // Giải phóng các repositories phụ thuộc vào chế độ mock/real
  if (sl.isRegistered<AuthRepository>()) {
    await sl.unregister<AuthRepository>();
  }
  if (sl.isRegistered<LoanRepository>()) {
    await sl.unregister<LoanRepository>();
  }
  if (sl.isRegistered<DebtStrategyRepository>()) {
    await sl.unregister<DebtStrategyRepository>();
  }
  if (sl.isRegistered<SimulationRepository>()) {
    await sl.unregister<SimulationRepository>();
  }
  if (sl.isRegistered<CreditProfileRepository>()) {
    await sl.unregister<CreditProfileRepository>();
  }
  if (sl.isRegistered<CreditReportRepository>()) {
    await sl.unregister<CreditReportRepository>();
  }
  if (sl.isRegistered<PaymentScheduleRepository>()) {
    await sl.unregister<PaymentScheduleRepository>();
  }

  // Đăng ký lại theo chế độ mới
  if (isMock) {
    sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
    sl.registerLazySingleton<LoanRepository>(() => MockLoanRepository());
    sl.registerLazySingleton<DebtStrategyRepository>(
      () => MockDebtStrategyRepository(),
    );
    sl.registerLazySingleton<SimulationRepository>(
      () => MockSimulationRepository(),
    );
    sl.registerLazySingleton<CreditProfileRepository>(
      () => MockCreditProfileRepository(),
    );
    sl.registerLazySingleton<CreditReportRepository>(
      () => MockCreditReportRepository(),
    );
    sl.registerLazySingleton<PaymentScheduleRepository>(
      () => MockPaymentScheduleRepository(),
    );
  } else {
    sl.registerLazySingleton<AuthRepository>(
      () => ApiAuthRepository(client: sl<ApiClient>()),
    );
    sl.registerLazySingleton<LoanRepository>(
      () => ApiLoanRepository(client: sl<ApiClient>()),
    );
    sl.registerLazySingleton<DebtStrategyRepository>(
      () => ApiDebtStrategyRepository(client: sl<ApiClient>()),
    );
    sl.registerLazySingleton<SimulationRepository>(
      () => ApiSimulationRepository(client: sl<ApiClient>()),
    );
    sl.registerLazySingleton<CreditProfileRepository>(
      () => ApiCreditProfileRepository(client: sl<ApiClient>()),
    );
    sl.registerLazySingleton<CreditReportRepository>(
      () => ApiCreditReportRepository(client: sl<ApiClient>()),
    );
    sl.registerLazySingleton<PaymentScheduleRepository>(
      () => ApiPaymentScheduleRepository(client: sl<ApiClient>()),
    );
  }

  // Đăng ký lại Controllers để nhận Repository mới
  if (sl.isRegistered<AuthController>()) {
    await sl.unregister<AuthController>();
    sl.registerLazySingleton<AuthController>(
      () => AuthController(sl<AuthRepository>()),
    );
  }

  if (sl.isRegistered<LoanController>()) {
    await sl.unregister<LoanController>();
    sl.registerLazySingleton<LoanController>(
      () => LoanController(sl<LoanRepository>()),
    );
  }

  if (sl.isRegistered<DebtStrategyController>()) {
    await sl.unregister<DebtStrategyController>();
    sl.registerLazySingleton<DebtStrategyController>(
      () => DebtStrategyController(
        sl<DebtStrategyRepository>(),
        sl<LoanRepository>(),
      ),
    );
  }

  if (sl.isRegistered<SimulationController>()) {
    await sl.unregister<SimulationController>();
    sl.registerLazySingleton<SimulationController>(
      () => SimulationController(
        sl<SimulationRepository>(),
        sl<LoanRepository>(),
      ),
    );
  }

  if (sl.isRegistered<CreditProfileController>()) {
    await sl.unregister<CreditProfileController>();
    sl.registerLazySingleton<CreditProfileController>(
      () => CreditProfileController(
        sl<CreditProfileRepository>(),
        sl<LoanRepository>(),
      ),
    );
  }

  if (sl.isRegistered<CreditReportController>()) {
    await sl.unregister<CreditReportController>();
    sl.registerLazySingleton<CreditReportController>(
      () => CreditReportController(sl<CreditReportRepository>()),
    );
  }

  if (sl.isRegistered<PaymentScheduleController>()) {
    await sl.unregister<PaymentScheduleController>();
    sl.registerLazySingleton<PaymentScheduleController>(
      () => PaymentScheduleController(sl<PaymentScheduleRepository>()),
    );
  }
}

/// Reset toàn bộ Service Locator (hữu ích trong các bài kiểm thử tự động Unit / Widget Tests)
Future<void> resetServiceLocator({bool dispose = true}) async {
  await sl.reset(dispose: dispose);
}

/// Hàm hỗ trợ đăng ký an toàn, tránh lỗi trùng lặp khi Hot Reload hoặc chạy nhiều bài test
void _registerLazySingletonIfNot<T extends Object>(T Function() factory) {
  if (!sl.isRegistered<T>()) {
    sl.registerLazySingleton<T>(factory);
  }
}
