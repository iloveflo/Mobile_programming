import 'package:flutter/material.dart';

import '../../models/credit_report_model.dart';
import '../common/app_colors.dart';

/// Thẻ hiển thị xu hướng biến động điểm tín dụng và tổng dư nợ qua các kỳ báo cáo (Luồng 4)
class CreditReportTrendCard extends StatelessWidget {
  final List<CreditReportModel> trendReports;

  const CreditReportTrendCard({super.key, required this.trendReports});

  String _formatCurrency(double amount) {
    final integerPart = amount.toInt().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integerPart[i]);
    }
    return '${buffer.toString()} đ';
  }

  String _formatShortPeriod(String? period) {
    if (period == null || period.isEmpty) return 'Kỳ';
    final parts = period.split('-');
    if (parts.length == 2) {
      return 'T${parts[1]}';
    }
    return period;
  }

  @override
  Widget build(BuildContext context) {
    if (trendReports.length < 2) {
      // Khi chỉ có 1 kỳ báo cáo, hiển thị thẻ thông tin khởi đầu
      final report = trendReports.firstOrNull;
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Icon(
                Icons.insights_rounded,
                color: AppColors.primary,
                size: 24.0,
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Khởi đầu theo dõi xu hướng',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Đã có báo cáo kỳ ${report?.reportPeriod ?? ""}. Hệ thống sẽ vẽ biểu đồ xu hướng biến động ngay khi có từ 2 kỳ báo cáo trở lên.',
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final firstReport = trendReports.first;
    final lastReport = trendReports.last;
    final scoreDiff =
        (lastReport.creditScore ?? 0) - (firstReport.creditScore ?? 0);
    final debtDiff = lastReport.totalDebt - firstReport.totalDebt;

    // Giới hạn hiển thị tối đa 6 kỳ báo cáo gần nhất để biểu đồ giữ tỷ lệ chuẩn và không bị co cụm trên mobile
    final displayReports = trendReports.length > 6
        ? trendReports.sublist(trendReports.length - 6)
        : trendReports;

    // Tìm điểm số cao nhất trong các kỳ để vẽ tỷ lệ thanh cột
    final maxScore = displayReports
        .map((r) => r.creditScore ?? 0)
        .fold<int>(850, (max, s) => s > max ? s : max);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Tóm tắt biến động
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.primary,
                    size: 22.0,
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    'XU HƯỚNG TÍN DỤNG',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: scoreDiff >= 0
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      scoreDiff >= 0
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 13.0,
                      color: scoreDiff >= 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    const SizedBox(width: 2.0),
                    Text(
                      '${scoreDiff >= 0 ? "+" : ""}$scoreDiff điểm',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: scoreDiff >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            trendReports.length > 6
                ? 'Theo dõi ${displayReports.length} kỳ gần nhất (tổng ${trendReports.length} kỳ). Dư nợ đã ${debtDiff <= 0 ? "giảm ${_formatCurrency(-debtDiff)}" : "tăng ${_formatCurrency(debtDiff)}"}.'
                : 'Theo dõi qua ${trendReports.length} kỳ báo cáo gần nhất. Dư nợ đã ${debtDiff <= 0 ? "giảm ${_formatCurrency(-debtDiff)}" : "tăng ${_formatCurrency(debtDiff)}"}.',
            style: const TextStyle(
              fontSize: 12.0,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16.0),

          // Trực quan hóa dạng thanh biểu đồ theo chuỗi thời gian (Luồng 4 - Bước 6)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: displayReports.map((report) {
              final score = report.creditScore ?? 0;
              final heightFactor = maxScore > 0
                  ? (score / 850.0).clamp(0.2, 1.0)
                  : 0.5;
              final isLatest = report.id == lastReport.id;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score > 0 ? '$score' : '-',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isLatest ? FontWeight.w800 : FontWeight.w600,
                      color: isLatest
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Container(
                    width: 32.0,
                    height: 80.0 * heightFactor,
                    decoration: BoxDecoration(
                      color: isLatest
                          ? AppColors.primary
                          : AppColors.primaryLight.withValues(alpha: 0.5),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    _formatShortPeriod(report.reportPeriod),
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: isLatest ? FontWeight.w700 : FontWeight.w500,
                      color: isLatest
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
