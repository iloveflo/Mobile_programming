import 'dart:math';
import 'package:flutter/material.dart';

/// Trạng thái lọc khoản vay
enum LoanStatus {
  all(label: 'Tất cả'),
  active(label: 'Đang hoạt động'),
  closed(label: 'Đã tất toán'),
  overdue(label: 'Quá hạn');

  final String label;
  const LoanStatus({required this.label});
}

/// Mô hình Khoản vay (Loan) chuẩn FinCredit
class LoanModel {
  final int id;
  final int userId;
  final int loanTypeId;
  final String? loanType; // MORTGAGE, CAR, CONSUMER, CREDIT_CARD, OTHER
  final String name;
  final String? lender; // Tên ngân hàng / bên cho vay
  final double principalAmount;
  final double interestRate; // Ví dụ 0.085 tương ứng 8.5%/năm
  final String
  interestMethod; // REDUCING_BALANCE (Dư nợ giảm dần) hoặc FLAT (Gốc ban đầu)
  final int termMonths;
  final DateTime startDate;
  final DateTime? endDate;
  final double outstandingAmount; // Dư nợ còn lại
  final double earlyPaymentFeeRate; // Phí trả nợ trước hạn (ví dụ 0.02 = 2%)
  final String status; // ACTIVE, CLOSED, OVERDUE
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LoanModel({
    required this.id,
    required this.userId,
    required this.loanTypeId,
    this.loanType,
    required this.name,
    this.lender,
    required this.principalAmount,
    required this.interestRate,
    required this.interestMethod,
    required this.termMonths,
    required this.startDate,
    this.endDate,
    required this.outstandingAmount,
    required this.earlyPaymentFeeRate,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  /// Khóa định danh loại khoản vay (MORTGAGE, CAR, CONSUMER, CREDIT_CARD, OTHER)
  String get loanTypeKey {
    if (loanType != null && loanType!.trim().isNotEmpty) {
      return loanType!.trim().toUpperCase();
    }
    if (loanTypeId == 2 || isCreditCard) return 'CREDIT_CARD';
    final lower = name.toLowerCase();
    if (lower.contains('nhà') ||
        lower.contains('thế chấp') ||
        lower.contains('bất động sản')) {
      return 'MORTGAGE';
    }
    if (lower.contains('xe') || lower.contains('ô tô')) {
      return 'CAR';
    }
    return 'CONSUMER';
  }

  /// Tên tiếng Việt hiển thị loại khoản vay
  String get loanTypeDisplayName {
    switch (loanTypeKey) {
      case 'MORTGAGE':
        return 'Vay thế chấp / Bất động sản';
      case 'CAR':
        return 'Vay mua xe / Ô tô';
      case 'CONSUMER':
        return 'Vay tiêu dùng / Tín chấp';
      case 'CREDIT_CARD':
        return 'Thẻ tín dụng';
      case 'OTHER':
      default:
        return 'Khoản vay khác';
    }
  }

  /// Lãi suất định dạng phần trăm (%/năm, ví dụ 8.5)
  double get interestRatePercent =>
      interestRate <= 1.0 ? (interestRate * 100.0) : interestRate;

  /// Chuỗi hiển thị lãi suất chuẩn hóa (ví dụ "8.5%/năm")
  String get interestRateFormatted =>
      '${interestRatePercent.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}%/năm';

  /// Tên hiển thị khoản vay
  String get loanName => name;

  /// Kỳ hạn theo tháng
  int get tenorMonths => termMonths;

  /// Mã hợp đồng chuẩn hóa
  String get loanCode => 'HD-${id.toString().padLeft(4, '0')}';

  /// Tên ngân hàng / bên cho vay
  String get lenderName {
    if (lender != null && lender!.isNotEmpty) {
      return lender!;
    }
    // Trích xuất từ tên khoản vay nếu có
    final lower = name.toLowerCase();
    if (lower.contains('vietcombank') || lower.contains('vcb')) {
      return 'Vietcombank';
    }
    if (lower.contains('techcombank') || lower.contains('tcb')) {
      return 'Techcombank';
    }
    if (lower.contains('mbbank') || lower.contains('mb')) {
      return 'MBBank';
    }
    if (lower.contains('bidv')) {
      return 'BIDV';
    }
    if (lower.contains('vpbank')) {
      return 'VPBank';
    }
    if (lower.contains('vib')) {
      return 'VIB';
    }
    if (lower.contains('fe credit')) {
      return 'FE Credit';
    }
    return 'Ngân hàng / TCTD';
  }

  /// Trạng thái hiển thị tiếng Việt
  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Đang vay';
      case 'SETTLED':
        return 'Đã tất toán';
      case 'CLOSED':
        return 'Đã đóng';
      case 'OVERDUE':
        return 'Quá hạn';
      default:
        return status;
    }
  }

  /// Màu sắc theo trạng thái
  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return const Color(0xFF16A34A);
      case 'SETTLED':
        return const Color(0xFF059669);
      case 'CLOSED':
        return const Color(0xFF64748B);
      case 'OVERDUE':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF1976D2);
    }
  }

  /// Ngày bắt đầu định dạng
  String get startDateFormatted =>
      '${startDate.day.toString().padLeft(2, '0')}/${startDate.month.toString().padLeft(2, '0')}/${startDate.year}';

  /// Ngày kết thúc định dạng
  String get endDateFormatted {
    if (endDate != null) {
      return '${endDate!.day.toString().padLeft(2, '0')}/${endDate!.month.toString().padLeft(2, '0')}/${endDate!.year}';
    }
    final calcEnd = DateTime(
      startDate.year,
      startDate.month + termMonths,
      startDate.day,
    );
    return '${calcEnd.day.toString().padLeft(2, '0')}/${calcEnd.month.toString().padLeft(2, '0')}/${calcEnd.year}';
  }

  /// Ngày đến hạn định dạng
  String get nextDueDateFormatted =>
      '${nextDueDate.day.toString().padLeft(2, '0')}/${nextDueDate.month.toString().padLeft(2, '0')}/${nextDueDate.year}';

  /// Kiểm tra có phải thẻ tín dụng không
  bool get isCreditCard =>
      loanTypeId == 2 ||
      name.toLowerCase().contains('thẻ tín dụng') ||
      name.toLowerCase().contains('credit card');

  /// Số tiền gốc đã trả
  double get paidAmount =>
      (principalAmount - outstandingAmount).clamp(0.0, principalAmount);

  /// Tiến độ thanh toán (0.0 -> 1.0)
  double get progressRatio => principalAmount > 0
      ? (paidAmount / principalAmount).clamp(0.0, 1.0)
      : 0.0;

  bool get isActive => status.toUpperCase() == 'ACTIVE';
  bool get isClosed =>
      status.toUpperCase() == 'CLOSED' || status.toUpperCase() == 'SETTLED';
  bool get isSettled => status.toUpperCase() == 'SETTLED';
  bool get isOverdue => status.toUpperCase() == 'OVERDUE';

  /// Điều kiện xóa cứng: Chỉ cho phép xóa hoàn toàn khi chưa có bất kỳ giao dịch thanh toán nào
  bool get canHardDelete => paidAmount <= 0.0;

  /// Tính tỷ lệ LTV (%) theo giá trị định giá của tài sản đảm bảo
  double calculateLtv(double collateralValuation) {
    if (collateralValuation <= 0) return 0.0;
    return (principalAmount / collateralValuation) * 100.0;
  }

  /// Ngày thanh toán kỳ tiếp theo
  DateTime get nextDueDate {
    final now = DateTime.now();
    DateTime due = DateTime(now.year, now.month, startDate.day);
    if (due.isBefore(now)) {
      due = DateTime(now.year, now.month + 1, startDate.day);
    }
    return due;
  }

  /// Ước tính số tiền thanh toán kỳ tháng tới
  double get monthlyInstallmentEstimate {
    if (isClosed || outstandingAmount <= 0) return 0.0;
    if (termMonths <= 0) return 0.0;

    final double monthlyRate = interestRate / 12.0;

    if (interestMethod == 'REDUCING_BALANCE') {
      if (monthlyRate == 0) return outstandingAmount / termMonths;
      // Công thức EMI: P * r * (1+r)^n / ((1+r)^n - 1)
      final num factor = pow(1.0 + monthlyRate, termMonths);
      return outstandingAmount * (monthlyRate * factor) / (factor - 1.0);
    } else {
      // Dư nợ gốc ban đầu: Gốc chia đều + Lãi tính theo gốc ban đầu
      final double monthlyPrincipal = principalAmount / termMonths;
      final double monthlyInterest = principalAmount * monthlyRate;
      return monthlyPrincipal + monthlyInterest;
    }
  }

  /// Ước tính số tiền thanh toán kỳ tháng tới (alias)
  double get estimatedMonthlyPayment => monthlyInstallmentEstimate;

  LoanModel copyWith({
    int? id,
    int? userId,
    int? loanTypeId,
    String? loanType,
    String? name,
    String? lender,
    double? principalAmount,
    double? interestRate,
    String? interestMethod,
    int? termMonths,
    DateTime? startDate,
    DateTime? endDate,
    double? outstandingAmount,
    double? earlyPaymentFeeRate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      loanTypeId: loanTypeId ?? this.loanTypeId,
      loanType: loanType ?? this.loanType,
      name: name ?? this.name,
      lender: lender ?? this.lender,
      principalAmount: principalAmount ?? this.principalAmount,
      interestRate: interestRate ?? this.interestRate,
      interestMethod: interestMethod ?? this.interestMethod,
      termMonths: termMonths ?? this.termMonths,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      earlyPaymentFeeRate: earlyPaymentFeeRate ?? this.earlyPaymentFeeRate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory LoanModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) {
        return null;
      }
      if (val is DateTime) {
        return val;
      }
      return DateTime.tryParse(val.toString());
    }

    return LoanModel(
      id: json['loan_id'] is num
          ? (json['loan_id'] as num).toInt()
          : int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      userId: json['user_id'] is num ? (json['user_id'] as num).toInt() : 1,
      loanTypeId: json['loan_type_id'] is num
          ? (json['loan_type_id'] as num).toInt()
          : int.tryParse(json['loanTypeId']?.toString() ?? '1') ?? 1,
      loanType: json['loan_type']?.toString() ?? json['loanType']?.toString(),
      name: (json['loan_name'] ?? json['name'] ?? 'Khoản vay') as String,
      lender: json['lender_name'] ?? json['lender'] as String?,
      principalAmount:
          (json['principal_amount'] ?? json['principalAmount'] as num?)
              ?.toDouble() ??
          0.0,
      interestRate:
          (json['interest_rate'] ?? json['interestRate'] as num?)?.toDouble() ??
          0.0,
      interestMethod:
          (json['interest_method'] ??
                  json['interestMethod'] ??
                  'REDUCING_BALANCE')
              as String,
      termMonths: json['term_months'] is num
          ? (json['term_months'] as num).toInt()
          : int.tryParse(json['termMonths']?.toString() ?? '12') ?? 12,
      startDate:
          parseDate(json['start_date'] ?? json['startDate']) ?? DateTime.now(),
      endDate: parseDate(json['end_date'] ?? json['endDate']),
      outstandingAmount:
          (json['outstanding_amount'] ?? json['outstandingAmount'] as num?)
              ?.toDouble() ??
          0.0,
      earlyPaymentFeeRate:
          (json['early_payment_fee_rate'] ??
                  json['earlyPaymentFeeRate'] as num?)
              ?.toDouble() ??
          0.02,
      status: (json['status'] ?? 'ACTIVE') as String,
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDate(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'loan_id': id,
    'user_id': userId,
    'loan_type_id': loanTypeId,
    'loan_type': loanTypeKey,
    'loan_name': name,
    'lender_name': lender,
    'principal_amount': principalAmount,
    'interest_rate': interestRate,
    'interest_method': interestMethod,
    'term_months': termMonths,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate?.toIso8601String(),
    'outstanding_amount': outstandingAmount,
    'early_payment_fee_rate': earlyPaymentFeeRate,
    'status': status,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };
}
