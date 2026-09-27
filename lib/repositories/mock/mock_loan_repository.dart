import 'package:get_it/get_it.dart';

import '../../controllers/auth_controller.dart';
import '../../mock_data/asset_mock_data.dart';
import '../../mock_data/loan_mock_data.dart';
import '../../models/collateral_model.dart';
import '../../models/loan_model.dart';
import '../interfaces/loan_repository.dart';

/// Triển khai Mock của LoanRepository lưu trữ và xử lý trực tiếp trên RAM (In-Memory)
class MockLoanRepository implements LoanRepository {
  final List<LoanModel> _loans = [];
  final List<CollateralModel> _assets = [];

  MockLoanRepository() {
    _initMockData();
  }

  int? _getCurrentUserId() {
    try {
      if (GetIt.I.isRegistered<AuthController>()) {
        return GetIt.I<AuthController>().currentUser?.userId;
      }
    } catch (_) {}
    return null;
  }

  void _initMockData() {
    _loans.clear();
    _loans.addAll(LoanMockData.loansDatabase);

    _assets.clear();
    for (final a in AssetMockData.assetsDatabase) {
      _assets.add(
        CollateralModel(
          id: a.id,
          userId: a.userId,
          loanId: a.loanId,
          name: a.name,
          type: a.type,
          value: a.value,
          valuationDate: a.valuationDate,
          description: a.description,
          createdAt: a.createdAt,
        ),
      );
    }
  }

  Future<void> _simulateDelay([int minMs = 0, int maxMs = 0]) async {
    // Đã loại bỏ toàn bộ độ trễ giả lập để mang lại trải nghiệm tức thì (0ms)
    return;
  }

  @override
  Future<List<LoanModel>> getLoans({
    String? keyword,
    LoanStatus? status,
    String? lender,
  }) async {
    await _simulateDelay();

    final currentUserId = _getCurrentUserId();
    var results = List<LoanModel>.from(_loans);

    // Lọc theo người dùng hiện tại (nếu đã đăng nhập vào hệ thống)
    if (currentUserId != null) {
      results = results.where((loan) => loan.userId == currentUserId).toList();
    }

    // 1. Lọc theo từ khóa tìm kiếm (Tên khoản vay, Mã hợp đồng, Tên ngân hàng)
    if (keyword != null && keyword.trim().isNotEmpty) {
      final query = keyword.trim().toLowerCase();
      results = results.where((loan) {
        return loan.name.toLowerCase().contains(query) ||
            loan.loanCode.toLowerCase().contains(query) ||
            loan.lenderName.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Lọc theo trạng thái khoản vay
    if (status != null && status != LoanStatus.all) {
      switch (status) {
        case LoanStatus.active:
          results = results.where((l) => l.isActive).toList();
          break;
        case LoanStatus.closed:
          results = results.where((l) => l.isClosed).toList();
          break;
        case LoanStatus.overdue:
          results = results.where((l) => l.isOverdue).toList();
          break;
        case LoanStatus.all:
          break;
      }
    }

    // 3. Lọc theo bên cho vay
    if (lender != null && lender.trim().isNotEmpty && lender != 'Tất cả') {
      results = results
          .where(
            (l) => l.lenderName.toLowerCase() == lender.trim().toLowerCase(),
          )
          .toList();
    }

    return results;
  }

  @override
  Future<LoanModel> getLoanDetail(String loanId) async {
    await _simulateDelay(300, 600);

    final loan = _loans.cast<LoanModel?>().firstWhere(
      (l) =>
          l?.id.toString() == loanId ||
          l?.loanCode.toLowerCase() == loanId.toLowerCase(),
      orElse: () => null,
    );

    if (loan != null) {
      return loan;
    }

    throw Exception('Không tìm thấy thông tin khoản vay với mã $loanId.');
  }

  @override
  Future<LoanModel> createLoan(Map<String, dynamic> loanData) async {
    await _simulateDelay();

    final int newId = DateTime.now().millisecondsSinceEpoch % 100000;
    final double principal =
        (loanData['principal_amount'] ?? loanData['principalAmount'] as num?)
            ?.toDouble() ??
        100000000.0;
    final int termMonths =
        (loanData['tenor_months'] ??
                loanData['term_months'] ??
                loanData['termMonths'] as num?)
            ?.toInt() ??
        24;
    final double rawRate =
        (loanData['interest_rate'] ?? loanData['interestRate'] as num?)
            ?.toDouble() ??
        8.5;
    final double interestRate = rawRate > 1.0 ? rawRate / 100.0 : rawRate;

    DateTime startDate = DateTime.now();
    if (loanData['start_date'] != null) {
      final str = loanData['start_date'].toString();
      if (str.contains('/')) {
        final parts = str.split('/');
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]) ?? 1;
          final m = int.tryParse(parts[1]) ?? 1;
          final y = int.tryParse(parts[2]) ?? DateTime.now().year;
          startDate = DateTime(y, m, d);
        }
      } else {
        startDate = DateTime.tryParse(str) ?? DateTime.now();
      }
    }
    final DateTime endDate = DateTime(
      startDate.year,
      startDate.month + termMonths,
      startDate.day,
    );

    final currentUserId = _getCurrentUserId();
    final String loanType =
        (loanData['loan_type'] ?? loanData['loanType'] ?? 'CONSUMER')
            .toString();
    final int loanTypeId =
        (loanData['loan_type_id'] ?? loanData['loanTypeId'] as num?)?.toInt() ??
        (loanType == 'MORTGAGE' || loanType == 'CREDIT_CARD' ? 2 : 1);

    final newLoan = LoanModel(
      id: newId,
      userId:
          (loanData['user_id'] is num
              ? (loanData['user_id'] as num).toInt()
              : null) ??
          currentUserId ??
          1,
      loanTypeId: loanTypeId,
      loanType: loanType,
      name: (loanData['loan_name'] ?? loanData['name'] ?? 'Khoản vay mới')
          .toString(),
      lender:
          (loanData['lender_name'] ?? loanData['lender'] ?? 'Ngân hàng TMCP')
              .toString(),
      principalAmount: principal,
      interestRate: interestRate,
      interestMethod:
          (loanData['interest_method'] ??
                  loanData['interestMethod'] ??
                  'REDUCING_BALANCE')
              .toString(),
      termMonths: termMonths,
      startDate: startDate,
      endDate: endDate,
      outstandingAmount: (loanData['outstanding_amount'] ?? principal as num)
          .toDouble(),
      earlyPaymentFeeRate:
          (loanData['early_payment_fee_rate'] ??
                  loanData['earlyPaymentFeeRate'] as num?)
              ?.toDouble() ??
          0.02,
      status: (loanData['status'] ?? 'ACTIVE').toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _loans.insert(0, newLoan);

    // Gắn tài sản thế chấp nếu có thông tin định giá đi kèm
    if (loanData['collateral_name'] != null &&
        (loanData['collateral_value'] as num?) != null) {
      _assets.insert(
        0,
        CollateralModel(
          id: DateTime.now().millisecondsSinceEpoch % 100000 + 1,
          userId: currentUserId ?? 1,
          loanId: newId,
          name: loanData['collateral_name'].toString(),
          type: (loanData['collateral_type'] ?? 'REAL_ESTATE').toString(),
          value: (loanData['collateral_value'] as num).toDouble(),
          valuationDate: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
    }

    return newLoan;
  }

  @override
  Future<LoanModel> updateLoan(
    String loanId,
    Map<String, dynamic> loanData,
  ) async {
    await _simulateDelay();

    final index = _loans.indexWhere(
      (l) =>
          l.id.toString() == loanId ||
          l.loanCode.toLowerCase() == loanId.toLowerCase(),
    );

    if (index == -1) {
      throw Exception('Không tìm thấy khoản vay để cập nhật.');
    }

    final current = _loans[index];
    final int termMonths =
        (loanData['tenor_months'] ??
                loanData['term_months'] ??
                loanData['termMonths'] as num?)
            ?.toInt() ??
        current.termMonths;
    final double? rawRate =
        (loanData['interest_rate'] ?? loanData['interestRate'] as num?)
            ?.toDouble();
    final double interestRate = rawRate != null
        ? (rawRate > 1.0 ? rawRate / 100.0 : rawRate)
        : current.interestRate;
    final String? loanType =
        loanData['loan_type']?.toString() ??
        loanData['loanType']?.toString() ??
        current.loanType;

    DateTime startDate = current.startDate;
    if (loanData['start_date'] != null) {
      final str = loanData['start_date'].toString();
      if (str.contains('/')) {
        final parts = str.split('/');
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]) ?? 1;
          final m = int.tryParse(parts[1]) ?? 1;
          final y = int.tryParse(parts[2]) ?? current.startDate.year;
          startDate = DateTime(y, m, d);
        }
      } else {
        startDate = DateTime.tryParse(str) ?? current.startDate;
      }
    }
    final DateTime endDate = DateTime(
      startDate.year,
      startDate.month + termMonths,
      startDate.day,
    );

    final updatedLoan = current.copyWith(
      name: (loanData['loan_name'] ?? loanData['name'] ?? current.name)
          .toString(),
      lender: (loanData['lender_name'] ?? loanData['lender'] ?? current.lender)
          .toString(),
      loanType: loanType,
      principalAmount:
          (loanData['principal_amount'] ?? loanData['principalAmount'] as num?)
              ?.toDouble() ??
          current.principalAmount,
      interestRate: interestRate,
      interestMethod:
          (loanData['interest_method'] ??
                  loanData['interestMethod'] ??
                  current.interestMethod)
              .toString(),
      termMonths: termMonths,
      startDate: startDate,
      endDate: endDate,
      outstandingAmount:
          (loanData['outstanding_amount'] ??
                  loanData['outstandingAmount'] as num?)
              ?.toDouble() ??
          current.outstandingAmount,
      status: (loanData['status'] ?? current.status).toString(),
      updatedAt: DateTime.now(),
    );

    _loans[index] = updatedLoan;
    return updatedLoan;
  }

  @override
  Future<void> deleteLoan(String loanId, {bool softDelete = false}) async {
    await _simulateDelay();

    final index = _loans.indexWhere(
      (l) =>
          l.id.toString() == loanId ||
          l.loanCode.toLowerCase() == loanId.toLowerCase(),
    );

    if (index == -1) {
      throw Exception('Không tìm thấy khoản vay để xóa.');
    }

    final current = _loans[index];

    // Quy tắc quản lý: Nếu đã phát sinh trả nợ (paidAmount > 0) thì TUYỆT ĐỐI KHÔNG ĐƯỢC XÓA
    if (current.paidAmount > 0) {
      throw Exception(
        'Khoản vay đã phát sinh lịch sử thanh toán, không được phép xóa.',
      );
    }

    _loans.removeAt(index);
  }

  @override
  Future<List<CollateralModel>> getCollaterals({String? loanId}) async {
    await _simulateDelay(300, 600);

    final currentUserId = _getCurrentUserId();
    final int? id = loanId != null ? int.tryParse(loanId) : null;

    return _assets.where((a) {
      if (currentUserId != null && a.userId != currentUserId) return false;
      if (id != null && a.loanId != id) return false;
      return true;
    }).toList();
  }

  @override
  Future<List<CollateralModel>> getCollateralsByLoan(String loanId) async {
    return getCollaterals(loanId: loanId);
  }

  @override
  Future<CollateralModel> addCollateral(
    Map<String, dynamic> collateralData,
  ) async {
    await _simulateDelay(300, 600);

    final currentUserId = _getCurrentUserId() ?? 1;
    final int newId = DateTime.now().millisecondsSinceEpoch % 100000;
    final int? loanId = collateralData['loan_id'] is num
        ? (collateralData['loan_id'] as num).toInt()
        : (int.tryParse(collateralData['loanId']?.toString() ?? ''));

    final newCollateral = CollateralModel(
      id: newId,
      userId: currentUserId,
      loanId: loanId,
      name:
          (collateralData['name'] ??
                  collateralData['asset_name'] ??
                  'Tài sản mới')
              .toString(),
      type:
          (collateralData['type'] ??
                  collateralData['asset_type'] ??
                  'REAL_ESTATE')
              .toString(),
      value: (collateralData['value'] as num?)?.toDouble() ?? 0.0,
      valuationDate: DateTime.now(),
      description: collateralData['description']?.toString(),
      createdAt: DateTime.now(),
    );

    _assets.insert(0, newCollateral);
    return newCollateral;
  }

  @override
  Future<Map<String, dynamic>> scanDocumentOcr(String imagePath) async {
    // Giả lập quét OCR xử lý AI từ 1000 - 1500ms
    await _simulateDelay(1000, 1500);

    // Trả về kết quả bóc tách giả lập từ ảnh chụp hợp đồng/hóa đơn
    return {
      'contract_number': 'VCB/2026/HD-9021',
      'lender_name': 'Vietcombank',
      'loan_name': 'Vay mua xe thế chấp hợp đồng',
      'principal_amount': 350000000.0,
      'interest_rate': 8.9, // 8.9%
      'interest_method': 'Dư nợ giảm dần',
      'tenor_months': 36,
      'start_date': '15/09/2026',
      'confidence_score': 0.96,
      'confidence': 0.96,
      'raw_extracted_text':
          'HỢP ĐỒNG TÍN DỤNG SỐ VCB/2026/HD-9021. BÊN VAY: NGUYEN VAN A. SỐ TIỀN: 350,000,000 VND. THỜI HẠN: 36 THÁNG. LÃI SUẤT: 8.9%/NĂM.',
    };
  }
}
