import 'package:get_it/get_it.dart';

import 'controllers/auth_controller.dart';
import 'controllers/loan_controller.dart';
import 'core/config/app_env.dart';
import 'core/network/api_client.dart';
import 'repositories/interfaces/auth_repository.dart';
import 'repositories/interfaces/loan_repository.dart';
import 'repositories/mock/mock_auth_repository.dart';
import 'repositories/mock/mock_loan_repository.dart';
import 'repositories/remote/api_auth_repository.dart';
import 'repositories/remote/api_loan_repository.dart';

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
  } else {
    // A. Xác thực & Bảo mật (API Thật)
    _registerLazySingletonIfNot<AuthRepository>(
      () => ApiAuthRepository(client: sl<ApiClient>()),
    );

    // B. Quản lý Khoản vay (API Thật)
    _registerLazySingletonIfNot<LoanRepository>(
      () => ApiLoanRepository(client: sl<ApiClient>()),
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

  // Đăng ký lại theo chế độ mới
  if (isMock) {
    sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
    sl.registerLazySingleton<LoanRepository>(() => MockLoanRepository());
  } else {
    sl.registerLazySingleton<AuthRepository>(
      () => ApiAuthRepository(client: sl<ApiClient>()),
    );
    sl.registerLazySingleton<LoanRepository>(
      () => ApiLoanRepository(client: sl<ApiClient>()),
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
