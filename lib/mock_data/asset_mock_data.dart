import '../models/asset_model.dart';

class AssetMockData {
  static final List<AssetModel> assetsDatabase = [
    AssetModel(
      id: 1,
      userId: 1,
      name: 'Tài khoản tiết kiệm',
      type: 'SAVINGS',
      value: 80000000.0,
      valuationDate: DateTime(2026, 8, 31),
      description: 'Khoản tiết kiệm dùng để theo dõi tài sản ròng.',
      createdAt: DateTime(2026, 1, 10, 9, 30),
    ),
  ];
}
