import 'package:flutter/material.dart';

import '../../models/credit_report_model.dart';
import '../common/app_colors.dart';

/// Thẻ hiển thị tóm tắt một kỳ báo cáo tín dụng trong danh sách
class CreditReportCard extends StatelessWidget {
  final CreditReportModel report;
  final VoidCallback onTap;

  const CreditReportCard({
    super.key,
    required this.report,
    required this.onTap,
  });

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

  String _formatPeriod(String? period) {
    if (period == null || period.isEmpty) return 'Kỳ hiện tại';
    final parts = period.split('-');
    if (parts.length == 2) {
      return 'Kỳ Tháng ${parts[1]}/${parts[0]}';
    }
    return 'Kỳ $period';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Chưa ghi nhận';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $day/$month/$year';
  }

  String _resolveRiskLabel(String? risk) {
    switch (risk?.toUpperCase()) {
      case 'LOW':
        return 'Rủi ro thấp';
      case 'MEDIUM':
        return 'Rủi ro trung bình';
      case 'HIGH':
        return 'Rủi ro cao';
      default:
        return 'Đang phân loại';
    }
  }

  Color _resolveRiskColor(String? risk) {
    switch (risk?.toUpperCase()) {
      case 'LOW':
        return AppColors.success;
      case 'MEDIUM':
        return AppColors.warning;
      case 'HIGH':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = report.creditScore ?? 0;
    final riskColor = _resolveRiskColor(report.riskLevel);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
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
            // Dòng 1: Kỳ báo cáo & Huy hiệu rủi ro
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: AppColors.primary,
                        size: 20.0,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatPeriod(report.reportPeriod),
                          style: const TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          'Ảnh chụp: ${_formatDate(report.generatedAt)}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _resolveRiskLabel(report.riskLevel),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: riskColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 22.0, color: AppColors.border),

            // Dòng 2: Điểm tín dụng snapshot & Tổng dư nợ
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Điểm sức khỏe tín dụng',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            score > 0 ? '$score' : 'N/A',
                            style: const TextStyle(
                              fontSize: 22.0,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          const Text(
                            '/ 850',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(width: 1.0, height: 36.0, color: AppColors.border),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tổng dư nợ kỳ này',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        _formatCurrency(report.totalDebt),
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.0,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
