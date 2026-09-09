import '../../mock_data/user_mock_data.dart';
import '../../models/user_model.dart';
import '../interfaces/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Tìm user trong Database giả lập
    final record = UserMockData.usersDatabase
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (element) =>
              element?['user'].email == email.trim() &&
              element?['password'] == password,
          orElse: () => null,
        );

    if (record != null) {
      return record['user'] as UserModel;
    }

    throw Exception('Tài khoản hoặc mật khẩu không chính xác!');
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    await Future.delayed(
      const Duration(milliseconds: 1000),
    ); // Giả lập mạng chậm

    // Kiểm tra xem email đã tồn tại hay chưa
    final isExist = UserMockData.usersDatabase.any(
      (element) => element['user'].email == email.trim(),
    );

    if (isExist) {
      throw Exception('Email này đã được sử dụng!');
    }

    // Tạo đối tượng người dùng mới
    final newUser = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      token: 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
    );

    // Lưu vào database RAM
    UserMockData.usersDatabase.add({'user': newUser, 'password': password});

    return newUser;
  }
}
