import '../../mock_data/credit_profile_mock_data.dart';
import '../../mock_data/credit_report_mock_data.dart';
import '../../models/credit_report_model.dart';
import '../interfaces/credit_report_repository.dart';

/// Triển khai Mock In-Memory của CreditReportRepository
class MockCreditReportRepository implements CreditReportRepository {
  /// Cờ giả lập ngoại lệ EX-03: Không có quyền truy cập báo cáo của người khác (403 Forbidden)
  bool shouldSimulateUnauthorized = false;

  /// Cờ giả lập ngoại lệ EX-02: Không tìm thấy bản ghi báo cáo (404 Not Found)
  bool shouldSimulateNotFound = false;

  /// Cờ giả lập ngoại lệ EX-04: Thiếu dữ liệu nền tảng khi lập báo cáo
  bool shouldSimulateMissingData = false;

  /// Cờ giả lập ngoại lệ EX-05: Sự cố kết nối hoặc lỗi cơ sở dữ liệu
  bool shouldSimulateDatabaseError = false;

  @override
  Future<List<CreditReportModel>> getCreditReports({int? userId}) async {
    if (shouldSimulateUnauthorized) {
      throw Exception(
        'Dữ liệu báo cáo không thuộc quyền truy cập của người dùng.',
      );
    }
    if (shouldSimulateDatabaseError) {
      throw Exception(
        'Sự cố cơ sở dữ liệu khi truy vấn danh sách báo cáo tín dụng.',
      );
    }

    final targetId = userId ?? 1;
    final results = CreditReportMockData.creditReportsDatabase
        .where((r) => r.userId == targetId)
        .toList();

    // Sắp xếp trình tự thời gian mới nhất lên đầu
    results.sort((a, b) {
      final dateA = a.generatedAt ?? DateTime(1970);
      final dateB = b.generatedAt ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });

    return results;
  }

  @override
  Future<CreditReportModel?> getCreditReportDetail(
    int reportId, {
    int? userId,
  }) async {
    if (shouldSimulateUnauthorized) {
      throw Exception(
        'Dữ liệu báo cáo không thuộc quyền truy cập của người dùng.',
      );
    }
    if (shouldSimulateDatabaseError) {
      throw Exception('Sự cố cơ sở dữ liệu khi truy xuất chi tiết báo cáo.');
    }
    if (shouldSimulateNotFound) {
      throw Exception(
        'Không tìm thấy bản ghi báo cáo tín dụng trong hệ thống.',
      );
    }

    final targetUserId = userId ?? 1;
    final report = CreditReportMockData.creditReportsDatabase
        .cast<CreditReportModel?>()
        .firstWhere((r) => r?.id == reportId, orElse: () => null);

    if (report == null) {
      throw Exception(
        'Không tìm thấy bản ghi báo cáo tín dụng trong hệ thống.',
      );
    }

    // Kiểm tra kiểm soát phân quyền người dùng (EX-03)
    if (report.userId != targetUserId) {
      throw Exception(
        'Dữ liệu báo cáo không thuộc quyền truy cập của người dùng.',
      );
    }

    return report;
  }

  @override
  Future<CreditReportModel> generateReport({
    int? userId,
    required String reportPeriod,
  }) async {
    if (shouldSimulateUnauthorized) {
      throw Exception(
        'Dữ liệu báo cáo không thuộc quyền truy cập của người dùng.',
      );
    }
    if (shouldSimulateMissingData) {
      throw Exception(
        'Dữ liệu tài chính nền tảng chưa đầy đủ để khởi tạo báo cáo kỳ $reportPeriod.',
      );
    }
    if (shouldSimulateDatabaseError) {
      throw Exception(
        'Sự cố cơ sở dữ liệu khi lưu trữ ảnh chụp báo cáo tín dụng.',
      );
    }

    final targetUserId = userId ?? 1;
    final normalizedPeriod = reportPeriod.trim();

    // 1. Chặn lập khống báo cáo tương lai: Chỉ được lập báo cáo cho kỳ quá khứ hoặc kỳ hiện tại
    final now = DateTime.now();
    final parts = normalizedPeriod.split('-');
    if (parts.length == 2) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (y != null && m != null) {
        if (y > now.year || (y == now.year && m > now.month)) {
          final currentStr =
              '${now.year}-${now.month.toString().padLeft(2, '0')}';
          throw Exception(
            'Không thể lập báo cáo tín dụng cho kỳ tương lai ($normalizedPeriod). Kỳ báo cáo tối đa là kỳ hiện tại ($currentStr).',
          );
        }
      }
    }

    // 2. Rà soát chống spam / trùng kỳ: Mỗi kỳ (tháng hoặc quý) chỉ có 1 bản ghi ảnh chụp duy nhất
    final isDuplicate = CreditReportMockData.creditReportsDatabase.any(
      (r) =>
          r.userId == targetUserId &&
          r.reportPeriod?.trim() == normalizedPeriod,
    );
    if (isDuplicate) {
      throw Exception(
        'Kỳ báo cáo $normalizedPeriod đã tồn tại trong hệ thống. Mỗi kỳ báo cáo chỉ được khởi tạo một bản ghi ảnh chụp duy nhất.',
      );
    }

    // Lấy ảnh chụp từ CreditProfile và tính toán dư nợ liên tục theo tiến độ trả nợ
    final profile = CreditProfileMockData.creditProfilesDatabase
        .cast<dynamic>()
        .firstWhere((p) => p.userId == targetUserId, orElse: () => null);

    // Tìm báo cáo gần nhất của người dùng để duy trì tính liên tục của dư nợ
    final latestReport = CreditReportMockData.creditReportsDatabase
        .where((r) => r.userId == targetUserId)
        .firstOrNull;

    final baseDebt = latestReport?.totalDebt ?? 43750000.0;
    // Mỗi kỳ thanh toán định kỳ giảm dần dư nợ
    final currentDebt = (baseDebt - 2250000.0).clamp(0.0, double.infinity);

    final nextId =
        (CreditReportMockData.creditReportsDatabase
            .map((r) => r.id)
            .fold<int>(0, (max, id) => id > max ? id : max)) +
        1;

    final newReport = CreditReportModel(
      id: nextId,
      userId: targetUserId,
      creditScore: profile?.creditScore ?? 745,
      dtiRatio: profile?.dtiRatio ?? 0.285,
      ltvRatio: profile?.ltvRatio ?? 0.0,
      creditUtilization: profile?.creditUtilization ?? 0.32,
      onTimePaymentRate: profile?.onTimePaymentRate ?? 1.0,
      totalDebt: currentDebt,
      overdueAmount: 0.0,
      riskLevel: profile?.riskLevel ?? 'LOW',
      reportPeriod: normalizedPeriod,
      generatedAt: DateTime.now(),
    );

    // Lưu trữ độc lập vào database mock (ảnh chụp cố định không ảnh hưởng đến hồ sơ sau này)
    CreditReportMockData.creditReportsDatabase.insert(0, newReport);

    return newReport;
  }
}
