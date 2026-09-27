/// Cấu hình giới hạn giá trị định giá theo loại tài sản bảo đảm
class CollateralTypeConfig {
  final String key;
  final String displayName;
  final double minValue;
  final double maxValue;
  final String minFormatted;
  final String maxFormatted;

  const CollateralTypeConfig({
    required this.key,
    required this.displayName,
    required this.minValue,
    required this.maxValue,
    required this.minFormatted,
    required this.maxFormatted,
  });

  String get limitRangeText => '$minFormatted – $maxFormatted';
}

/// Mô hình Tài sản bảo đảm / Thế chấp (Collateral) cho khoản vay FinCredit
class CollateralModel {
  final int id;
  final int userId;
  final int? loanId;
  final String name;
  final String type; // REAL_ESTATE, VEHICLE, SAVINGS, OTHER
  final double value; // Giá trị định giá
  final DateTime? valuationDate;
  final String? description;
  final DateTime? createdAt;

  const CollateralModel({
    required this.id,
    required this.userId,
    this.loanId,
    required this.name,
    required this.type,
    required this.value,
    this.valuationDate,
    this.description,
    this.createdAt,
  });

  /// Bảng cấu hình hạn mức định giá theo từng loại tài sản
  static const Map<String, CollateralTypeConfig> typeConfigs = {
    'REAL_ESTATE': CollateralTypeConfig(
      key: 'REAL_ESTATE',
      displayName: 'Bất động sản / Nhà đất',
      minValue: 100000000.0, // 100 triệu
      maxValue: 200000000000.0, // 200 tỷ
      minFormatted: '100.000.000 đ (100 triệu)',
      maxFormatted: '200.000.000.000 đ (200 tỷ)',
    ),
    'VEHICLE': CollateralTypeConfig(
      key: 'VEHICLE',
      displayName: 'Phương tiện vận tải / Ô tô',
      minValue: 50000000.0, // 50 triệu
      maxValue: 20000000000.0, // 20 tỷ
      minFormatted: '50.000.000 đ (50 triệu)',
      maxFormatted: '20.000.000.000 đ (20 tỷ)',
    ),
    'SAVINGS': CollateralTypeConfig(
      key: 'SAVINGS',
      displayName: 'Sổ tiết kiệm / Tiền gửi',
      minValue: 10000000.0, // 10 triệu
      maxValue: 100000000000.0, // 100 tỷ
      minFormatted: '10.000.000 đ (10 triệu)',
      maxFormatted: '100.000.000.000 đ (100 tỷ)',
    ),
    'OTHER': CollateralTypeConfig(
      key: 'OTHER',
      displayName: 'Tài sản bảo đảm khác',
      minValue: 10000000.0, // 10 triệu
      maxValue: 50000000000.0, // 50 tỷ
      minFormatted: '10.000.000 đ (10 triệu)',
      maxFormatted: '50.000.000.000 đ (50 tỷ)',
    ),
  };

  /// Lấy cấu hình giới hạn theo loại tài sản
  static CollateralTypeConfig getConfig(String? type) {
    if (type == null) return typeConfigs['OTHER']!;
    final upper = type.toUpperCase();
    return typeConfigs[upper] ?? typeConfigs['OTHER']!;
  }

  /// Tên loại tài sản hiển thị thân thiện tiếng Việt
  String get typeDisplay => CollateralModel.getConfig(type).displayName;

  /// Định dạng ngày định giá
  String get valuationDateFormatted {
    if (valuationDate == null) return 'Mới nhất';
    return '${valuationDate!.day.toString().padLeft(2, '0')}/${valuationDate!.month.toString().padLeft(2, '0')}/${valuationDate!.year}';
  }

  factory CollateralModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) {
        return null;
      }
      if (val is DateTime) {
        return val;
      }
      return DateTime.tryParse(val.toString());
    }

    return CollateralModel(
      id: json['asset_id'] is num
          ? (json['asset_id'] as num).toInt()
          : int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      userId: json['user_id'] is num ? (json['user_id'] as num).toInt() : 1,
      loanId: json['loan_id'] is num
          ? (json['loan_id'] as num).toInt()
          : (int.tryParse(json['loanId']?.toString() ?? '')),
      name: (json['asset_name'] ?? json['name'] ?? 'Tài sản') as String,
      type: (json['asset_type'] ?? json['type'] ?? 'OTHER') as String,
      value: (json['asset_value'] ?? json['value'] as num?)?.toDouble() ?? 0.0,
      valuationDate: parseDate(json['valuation_date'] ?? json['valuationDate']),
      description: json['description'] as String?,
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'asset_id': id,
    'user_id': userId,
    'loan_id': loanId,
    'asset_name': name,
    'asset_type': type,
    'asset_value': value,
    'valuation_date': valuationDate?.toIso8601String(),
    'description': description,
    'created_at': createdAt?.toIso8601String(),
  };
}
