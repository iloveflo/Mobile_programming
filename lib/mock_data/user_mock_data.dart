import '../models/user_model.dart';

class UserMockData {
  // Bộ nhớ đệm giả lập Database lưu danh sách người dùng
  static final List<Map<String, dynamic>> usersDatabase = [
    {
      'user': const UserModel(
        id: 'usr_001',
        name: 'Nguyen Van Dev',
        email: 'dev@test.com',
        token: 'mock_token_123',
      ),
      'password': '123456',
    },
  ];
}