import '../models/loan_model.dart';

class LoanMockData {
  static final List<LoanModel> loansDatabase = [
    LoanModel(
      id: 101,
      userId: 1,
      loanTypeId: 2,
      loanType: 'CAR',
      name: 'Vay mua xe VinFast VF8',
      lender: 'Vietcombank',
      principalAmount: 500000000.0,
      interestRate: 0.085, // 8.5%/năm
      interestMethod: 'REDUCING_BALANCE',
      termMonths: 48,
      startDate: DateTime(2025, 6, 15),
      endDate: DateTime(2029, 6, 15),
      outstandingAmount: 385000000.0,
      earlyPaymentFeeRate: 0.015,
      status: 'ACTIVE',
      createdAt: DateTime(2025, 6, 10, 8, 30),
      updatedAt: DateTime(2026, 9, 1, 9),
    ),
    LoanModel(
      id: 102,
      userId: 1,
      loanTypeId: 2, // Thẻ tín dụng
      loanType: 'CREDIT_CARD',
      name: 'Thẻ tín dụng VIB Super Card',
      lender: 'VIB',
      principalAmount: 100000000.0, // Hạn mức thẻ
      interestRate: 0.24, // 24%/năm
      interestMethod: 'FLAT',
      termMonths: 12,
      startDate: DateTime(2026, 1, 5),
      endDate: DateTime(2027, 1, 5),
      outstandingAmount: 28500000.0, // Dư nợ kỳ này
      earlyPaymentFeeRate: 0.0,
      status: 'ACTIVE',
      createdAt: DateTime(2026, 1, 5, 10),
      updatedAt: DateTime(2026, 9, 15, 14),
    ),
    LoanModel(
      id: 103,
      userId: 1,
      loanTypeId: 1,
      loanType: 'CONSUMER',
      name: 'Vay tiêu dùng tín chấp',
      lender: 'MBBank',
      principalAmount: 80000000.0,
      interestRate: 0.12, // 12%/năm
      interestMethod: 'REDUCING_BALANCE',
      termMonths: 24,
      startDate: DateTime(2026, 2, 20),
      endDate: DateTime(2028, 2, 20),
      outstandingAmount: 62000000.0,
      earlyPaymentFeeRate: 0.02,
      status: 'ACTIVE',
      createdAt: DateTime(2026, 2, 15, 9),
      updatedAt: DateTime(2026, 9, 1, 10),
    ),
    LoanModel(
      id: 104,
      userId: 1,
      loanTypeId: 2,
      loanType: 'MORTGAGE',
      name: 'Vay mua căn hộ Sunrise City',
      lender: 'Techcombank',
      principalAmount: 1800000000.0,
      interestRate: 0.079, // 7.9%/năm
      interestMethod: 'REDUCING_BALANCE',
      termMonths: 120,
      startDate: DateTime(2024, 3, 10),
      endDate: DateTime(2034, 3, 10),
      outstandingAmount: 1540000000.0,
      earlyPaymentFeeRate: 0.025,
      status: 'ACTIVE',
      createdAt: DateTime(2024, 3, 5, 8),
      updatedAt: DateTime(2026, 9, 10, 11),
    ),
    LoanModel(
      id: 105,
      userId: 1,
      loanTypeId: 1,
      loanType: 'CONSUMER',
      name: 'Vay tiền mặt qua sao kê lương',
      lender: 'FE Credit',
      principalAmount: 30000000.0,
      interestRate: 0.18,
      interestMethod: 'FLAT',
      termMonths: 12,
      startDate: DateTime(2025, 1, 15),
      endDate: DateTime(2026, 1, 15),
      outstandingAmount: 0.0,
      earlyPaymentFeeRate: 0.03,
      status: 'CLOSED', // Đã tất toán
      createdAt: DateTime(2025, 1, 10, 9),
      updatedAt: DateTime(2026, 1, 15, 16),
    ),
  ];

  /// Danh mục các ngân hàng uy tín chuẩn hóa (không cho nhập tự do)
  static const List<String> standardBanks = [
    'Vietcombank',
    'Techcombank',
    'BIDV',
    'VietinBank',
    'MBBank',
    'VPBank',
    'TPBank',
    'ACB',
    'Khác/Tổ chức tín dụng',
  ];

  /// Danh mục các loại khoản vay
  static const Map<String, String> loanTypeLabels = {
    'MORTGAGE': 'Vay thế chấp / Bất động sản',
    'CAR': 'Vay mua ô tô',
    'CONSUMER': 'Vay tiêu dùng / Tín chấp',
    'CREDIT_CARD': 'Thẻ tín dụng',
    'OTHER': 'Khoản vay khác',
  };

  /// Bảng lãi suất tham chiếu cơ sở (Benchmark Interest Rates %/năm) theo Ngân hàng & Loại vay
  static const Map<String, Map<String, double>> benchmarkRates = {
    'Techcombank': {
      'MORTGAGE': 8.5,
      'CAR': 9.2,
      'CONSUMER': 13.5,
      'CREDIT_CARD': 26.0,
      'OTHER': 10.0,
    },
    'Vietcombank': {
      'MORTGAGE': 7.9,
      'CAR': 8.5,
      'CONSUMER': 11.5,
      'CREDIT_CARD': 18.0,
      'OTHER': 9.5,
    },
    'BIDV': {
      'MORTGAGE': 7.8,
      'CAR': 8.2,
      'CONSUMER': 11.0,
      'CREDIT_CARD': 18.0,
      'OTHER': 9.5,
    },
    'VietinBank': {
      'MORTGAGE': 8.0,
      'CAR': 8.5,
      'CONSUMER': 11.5,
      'CREDIT_CARD': 18.5,
      'OTHER': 9.8,
    },
    'MBBank': {
      'MORTGAGE': 8.5,
      'CAR': 9.0,
      'CONSUMER': 12.5,
      'CREDIT_CARD': 22.0,
      'OTHER': 10.5,
    },
    'VPBank': {
      'MORTGAGE': 9.5,
      'CAR': 10.5,
      'CONSUMER': 14.0,
      'CREDIT_CARD': 28.0,
      'OTHER': 12.0,
    },
    'TPBank': {
      'MORTGAGE': 8.8,
      'CAR': 9.5,
      'CONSUMER': 13.0,
      'CREDIT_CARD': 25.0,
      'OTHER': 11.0,
    },
    'ACB': {
      'MORTGAGE': 8.2,
      'CAR': 8.9,
      'CONSUMER': 12.0,
      'CREDIT_CARD': 23.0,
      'OTHER': 10.5,
    },
    'Khác/Tổ chức tín dụng': {
      'MORTGAGE': 9.0,
      'CAR': 10.0,
      'CONSUMER': 15.0,
      'CREDIT_CARD': 25.0,
      'OTHER': 12.0,
    },
  };

  /// Lấy mức lãi suất cơ sở tham chiếu theo ngân hàng và loại khoản vay
  static double getBenchmarkRate(String bank, String loanType) {
    final bankRates =
        benchmarkRates[bank] ?? benchmarkRates['Khác/Tổ chức tín dụng']!;
    return bankRates[loanType] ?? bankRates['OTHER'] ?? 10.0;
  }
}
