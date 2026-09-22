import '../models/refresh_token_model.dart';

class RefreshTokenMockData {
  static final List<RefreshTokenModel> refreshTokensDatabase = [
    RefreshTokenModel(
      id: 1,
      userId: 1,
      token: 'mock_refresh_token_001',
      expiresAt: DateTime(2026, 12, 31, 23, 59, 59),
      createdAt: DateTime(2026, 1, 10, 9),
    ),
  ];
}
