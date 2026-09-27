import '../models/asset_model.dart';

class AssetMockData {
  static final List<AssetModel> assetsDatabase = [
    AssetModel(
      id: 1,
      userId: 1,
      loanId: 101, // Gắn với khoản vay ô tô VinFast
      name: 'Ô tô VinFast VF8 Plus 2023',
      type: 'VEHICLE',
      value: 750000000.0,
      valuationDate: DateTime(2025, 6, 1),
      description:
          'Xe thế chấp giải ngân khoản vay Vietcombank. Cavet gốc giữ tại ngân hàng.',
      createdAt: DateTime(2025, 6, 1, 9, 30),
    ),
    AssetModel(
      id: 2,
      userId: 1,
      loanId: 104, // Gắn với khoản vay mua nhà Techcombank
      name: 'Căn hộ chung cư Sunrise City (85m2)',
      type: 'REAL_ESTATE',
      value: 2800000000.0,
      valuationDate: DateTime(2024, 2, 20),
      description: 'Sổ hồng căn hộ tháp W2, tầng 18. Thế chấp vay Techcombank.',
      createdAt: DateTime(2024, 2, 20, 14, 0),
    ),
    AssetModel(
      id: 3,
      userId: 1,
      loanId: null,
      name: 'Sổ tiết kiệm BIDV kỳ hạn 12 tháng',
      type: 'SAVINGS',
      value: 250000000.0,
      valuationDate: DateTime(2026, 8, 31),
      description: 'Tài sản thanh khoản cao dùng dự phòng tài chính.',
      createdAt: DateTime(2026, 1, 10, 9, 30),
    ),
  ];
}
