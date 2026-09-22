import '../models/loan_type_model.dart';

class LoanTypeMockData {
  static final List<LoanTypeModel> loanTypesDatabase = [
    LoanTypeModel(
      id: 1,
      name: 'Vay tín chấp',
      description: 'Khoản vay không cần tài sản bảo đảm.',
      createdAt: DateTime(2026, 1, 5, 9),
    ),
    LoanTypeModel(
      id: 2,
      name: 'Vay thế chấp',
      description: 'Khoản vay có tài sản bảo đảm.',
      createdAt: DateTime(2026, 1, 6, 9),
    ),
  ];
}
