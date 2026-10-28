import '../models/loan_type_model.dart';

class LoanTypeMockData {
  static final List<LoanTypeModel> loanTypesDatabase = [
    LoanTypeModel(
      id: 1,
      typeCode: 'CONSUMER',
      name: 'Vay tiêu dùng / Tín chấp',
      description:
          'Khoản vay tín chấp tiêu dùng không bắt buộc tài sản bảo đảm',
      createdAt: DateTime(2025, 1, 1, 8),
    ),
    LoanTypeModel(
      id: 2,
      typeCode: 'MORTGAGE',
      name: 'Vay thế chấp / Bất động sản',
      description: 'Khoản vay có tài sản bảo đảm là bất động sản hoặc nhà đất',
      createdAt: DateTime(2025, 1, 1, 8),
    ),
    LoanTypeModel(
      id: 3,
      typeCode: 'CAR',
      name: 'Vay mua xe / Ô tô',
      description: 'Khoản vay thế chấp mua phương tiện đi lại, ô tô',
      createdAt: DateTime(2025, 1, 1, 8),
    ),
    LoanTypeModel(
      id: 4,
      typeCode: 'CREDIT_CARD',
      name: 'Thẻ tín dụng',
      description: 'Hạn mức thấu chi thẻ tín dụng chi tiêu linh hoạt',
      createdAt: DateTime(2025, 1, 1, 8),
    ),
    LoanTypeModel(
      id: 5,
      typeCode: 'OTHER',
      name: 'Khoản vay khác',
      description: 'Các gói tín dụng và khoản vay cá nhân khác',
      createdAt: DateTime(2025, 1, 1, 8),
    ),
  ];
}
