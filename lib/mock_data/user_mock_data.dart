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
      idCardNumber: '079201008888',
      address: 'Tòa nhà Landmark 81, P. 22, Q. Bình Thạnh, TP. Hồ Chí Minh',
      occupation: 'Kỹ sư Phần mềm Senior',
      workplace: 'Tập đoàn Công nghệ FPT',
      contractType: 'Hợp đồng lao động không xác định thời hạn',
      isEkycVerified: true,
      ekycTier: 'C06',
      membershipTier: 'GOLD',
      cicScore: 745,
      isBiometricEnabled: true,
      isAutoLockEnabled: true,
      createdAt: DateTime(2026, 1, 5, 9),
      updatedAt: DateTime(2026, 9, 1, 8),
      token: 'mock_token_123',
    ),
  ];
}
