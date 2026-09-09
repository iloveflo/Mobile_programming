import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/controllers/auth_controller.dart';
import 'package:my_first_app/repositories/mock/mock_auth_repository.dart';

void main() {
  group('AuthController', () {
    late AuthController controller;

    setUp(() => controller = AuthController(MockAuthRepository()));

    test('đăng nhập thành công với tài khoản mẫu', () async {
      final result = await controller.login('dev@test.com', '123456');
      expect(result, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.currentUser?.email, 'dev@test.com');
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('đăng nhập thất bại và trả về thông báo lỗi', () async {
      final result = await controller.login('dev@test.com', 'sai-mat-khau');
      expect(result, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNotEmpty);
    });

    test('đăng xuất xóa người dùng hiện tại', () async {
      await controller.login('dev@test.com', '123456');
      controller.logout();
      expect(controller.isAuthenticated, isFalse);
      expect(controller.currentUser, isNull);
    });
  });
}
