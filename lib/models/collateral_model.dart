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
  final String? legalDocumentUrl;
  final String? description;
  final DateTime? createdAt;
  final double? maxLtvRatio;
  final double totalSecuredDebt;
  final double? remainingCollateralCapacity;
  final List<String> linkedLoanIds;

  const CollateralModel({
    required this.id,
    required this.userId,
    this.loanId,
    required this.name,
    required this.type,
    required this.value,
    this.valuationDate,
    this.legalDocumentUrl,
    this.description,
    this.createdAt,
    this.maxLtvRatio,
    this.totalSecuredDebt = 0.0,
    this.remainingCollateralCapacity,
    this.linkedLoanIds = const [],
  });

  /// Tỷ lệ LTV tối đa chuẩn ngân hàng VN theo từng loại tài sản (TT 39/2016/TT-NHNN)
  static double maxLtvForType(String? type) {
    switch ((type ?? '').toUpperCase()) {
      case 'REAL_ESTATE':
        return 0.80;
      case 'VEHICLE':
        return 0.70;
      case 'SAVINGS':
        return 0.95;
      default:
        return 0.70;
    }
  }

  double get effectiveMaxLtv => maxLtvRatio ?? maxLtvForType(type);

  double get effectiveRemainingCapacity =>
      remainingCollateralCapacity ??
      ((value * effectiveMaxLtv) - totalSecuredDebt).clamp(
        0.0,
        double.infinity,
      );

  bool get hasLegalDocument =>
      legalDocumentUrl != null && legalDocumentUrl!.trim().isNotEmpty;

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

    int parseInt(dynamic val, [int fallback = 1]) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? fallback;
      return fallback;
    }

    int? parseNullableInt(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    return CollateralModel(
      id: parseInt(json['asset_id'] ?? json['id'], 1),
      userId: parseInt(json['user_id'] ?? json['userId'], 1),
      loanId: parseNullableInt(json['loan_id'] ?? json['loanId']),
      name: (json['asset_name'] ?? json['name'] ?? 'Tài sản') as String,
      type: (json['asset_type'] ?? json['type'] ?? 'OTHER') as String,
      value: (json['asset_value'] ?? json['value'] as num?)?.toDouble() ?? 0.0,
      valuationDate: parseDate(json['valuation_date'] ?? json['valuationDate']),
      legalDocumentUrl:
          (json['legal_document_url'] ?? json['legalDocumentUrl']) as String?,
      description: json['description'] as String?,
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      maxLtvRatio: (json['max_ltv_ratio'] as num?)?.toDouble(),
      totalSecuredDebt: (json['total_secured_debt'] as num?)?.toDouble() ?? 0.0,
      remainingCollateralCapacity:
          (json['remaining_collateral_capacity'] as num?)?.toDouble(),
      linkedLoanIds:
          (json['linked_loan_ids'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
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
    'legal_document_url': legalDocumentUrl,
    'description': description,
    'created_at': createdAt?.toIso8601String(),
  };
}
