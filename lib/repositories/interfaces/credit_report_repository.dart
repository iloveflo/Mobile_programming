import '../../models/credit_report_model.dart';

/// Hợp đồng giao diện cho Kho lưu trữ Báo cáo Tín dụng (CreditReportRepository)
/// Quản lý các bản ghi ảnh chụp (Snapshot) sức khỏe tài chính định kỳ theo tháng/quý.
abstract class CreditReportRepository {
  /// Lấy danh sách các bản ghi báo cáo tín dụng định kỳ của người dùng,
  /// sắp xếp theo thời gian mới nhất lên đầu.
  Future<List<CreditReportModel>> getCreditReports({int? userId});

  /// Truy xuất thông tin ảnh chụp chi tiết của một báo cáo tín dụng cụ thể theo [reportId].
  /// Ném ngoại lệ phân quyền (EX-03) nếu báo cáo không thuộc về người dùng hiện tại,
  /// hoặc ngoại lệ không tìm thấy (EX-02) nếu bản ghi không tồn tại.
  Future<CreditReportModel?> getCreditReportDetail(int reportId, {int? userId});

  /// Yêu cầu Backend khởi tạo bản ghi ảnh chụp báo cáo tín dụng mới cho kỳ [reportPeriod].
  /// Ném ngoại lệ thiếu dữ liệu (EX-04) nếu dữ liệu nền tảng chưa đủ để lập chỉ số,
  /// hoặc ngoại lệ sự cố hệ thống/database (EX-05) nếu lưu trữ thất bại.
  Future<CreditReportModel> generateReport({
    int? userId,
    required String reportPeriod,
  });
}
