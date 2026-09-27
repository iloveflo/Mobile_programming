import '../../models/collateral_model.dart';
import '../../models/loan_model.dart';

/// Hợp đồng giao diện cho Kho lưu trữ dữ liệu Khoản vay (LoanRepository)
abstract class LoanRepository {
  /// Lấy danh sách các khoản vay theo bộ lọc tìm kiếm
  Future<List<LoanModel>> getLoans({
    String? keyword,
    LoanStatus? status,
    String? lender,
  });

  /// Lấy thông tin chi tiết một khoản vay cụ thể theo ID
  Future<LoanModel> getLoanDetail(String loanId);

  /// Tạo mới một khoản vay
  Future<LoanModel> createLoan(Map<String, dynamic> loanData);

  /// Cập nhật thông tin khoản vay hiện tại
  Future<LoanModel> updateLoan(String loanId, Map<String, dynamic> loanData);

  /// Xóa hoặc đóng khoản vay (softDelete = true chuyển trạng thái sang CLOSED)
  Future<void> deleteLoan(String loanId, {bool softDelete = true});

  /// Lấy danh sách tài sản bảo đảm gắn với khoản vay
  Future<List<CollateralModel>> getCollateralsByLoan(String loanId);

  /// Lấy tất cả tài sản bảo đảm của người dùng hiện tại (hoặc theo khoản vay nếu có loanId)
  Future<List<CollateralModel>> getCollaterals({String? loanId});

  /// Thêm mới tài sản bảo đảm
  Future<CollateralModel> addCollateral(Map<String, dynamic> collateralData);

  /// Quét OCR tài liệu/hợp đồng vay từ ảnh chụp
  Future<Map<String, dynamic>> scanDocumentOcr(String imagePath);
}
