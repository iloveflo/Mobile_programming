import 'package:get_it/get_it.dart';

import 'controllers/auth_controller.dart';
import 'core/network/api_client.dart';
import 'repositories/interfaces/auth_repository.dart';
import 'repositories/mock/mock_auth_repository.dart';
import 'repositories/remote/api_auth_repository.dart';

final sl = GetIt.instance;

// =========================================================================
// CÔNG TẮC BẬT/TẮT TOÀN BỘ DỰ ÁN:
// true  -> Chạy Mock Data tĩnh (giai đoạn dựng Frontend)
// false -> Chạy gọi API thật (kết nối Backend)
// =========================================================================
const bool isMock = true;

void setupServiceLocator() {
  // 1. Đăng ký ApiClient (chỉ cần khi dùng API thật)
  if (!isMock) {
    sl.registerLazySingleton<ApiClient>(() => ApiClient());
  }

  // 2. Tự động hoán đổi Repository theo biến isMock
  if (isMock) {
    sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
    // sl.registerLazySingleton<ProductRepository>(() => MockProductRepository());
  } else {
    sl.registerLazySingleton<AuthRepository>(
      () => ApiAuthRepository(client: sl<ApiClient>()),
    );
    // sl.registerLazySingleton<ProductRepository>(
    //   () => ApiProductRepository(client: sl<ApiClient>()),
    // );
  }

  // 3. Đăng ký Controllers (Giữ nguyên, không bao giờ phải sửa)
  sl.registerLazySingleton<AuthController>(
    () => AuthController(sl<AuthRepository>()),
  );
  // sl.registerLazySingleton<ProductController>(
  //   () => ProductController(sl<ProductRepository>()),
  // );
}
