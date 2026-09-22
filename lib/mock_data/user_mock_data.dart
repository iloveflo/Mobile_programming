import '../models/user_model.dart';

class UserMockData {
  static final List<UserModel> usersDatabase = [
    UserModel(
      userId: 1,
      fullName: 'Nguyen Van Dev',
      email: 'dev@test.com',
      phone: '0900000001',
      passwordHash: '123456',
      monthlyIncome: 25000000.0,
      dateOfBirth: DateTime(1998, 5, 12),
      createdAt: DateTime(2026, 1, 5, 9),
      updatedAt: DateTime(2026, 9, 1, 8),
      token: 'mock_token_123',
    ),
  ];
}
