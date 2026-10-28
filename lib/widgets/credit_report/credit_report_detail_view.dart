import 'package:flutter/material.dart';

import '../../models/credit_report_model.dart';
import '../common/app_colors.dart';

/// Chế độ xem chi tiết toàn diện của một bản ghi báo cáo tín dụng (Luồng 3)
class CreditReportDetailView extends StatelessWidget {
  final CreditReportModel report;

  const CreditReportDetailView({super.key, required this.report});

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

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return 'Chưa ghi nhận';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    final second = dt.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second - $day/$month/$year';
  }

  String _resolveRiskLabel(String? risk) {
    switch (risk?.toUpperCase()) {
      case 'LOW':
        return 'Hạng 1 • Rủi ro thấp';
      case 'MEDIUM':
        return 'Hạng 2 • Rủi ro trung bình';
      case 'HIGH':
        return 'Hạng 3 • Rủi ro cao';
      default:
        return 'Chưa phân loại';
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

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      children: [
        // 1. Thẻ thông tin kỳ và thời điểm chụp dữ liệu
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatPeriod(report.reportPeriod),
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: riskColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _resolveRiskLabel(report.riskLevel),
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: riskColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 14.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    'Thời điểm tạo ảnh chụp: ${_formatDateTime(report.generatedAt)}',
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              // Thông điệp bảo toàn nguyên tắc lịch sử
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 18.0,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Dữ liệu ảnh chụp cố định tại thời điểm lập báo cáo, không bị sửa đổi khi hồ sơ hiện tại thay đổi.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.primary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14.0),

        // 2. Thẻ Điểm tín dụng trọng tâm
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              const Text(
                'ĐIỂM SỨC KHỎE TÍN DỤNG TẠI KỲ NÀY',
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    score > 0 ? '$score' : 'N/A',
                    style: const TextStyle(
                      fontSize: 48.0,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  const Text(
                    '/ 850',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              Text(
                _resolveRiskLabel(report.riskLevel),
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  color: riskColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        // 3. Tiêu đề danh mục chỉ số thành phần
        const Text(
          'CÁC CHỈ SỐ TÀI CHÍNH TẠI THỜI ĐIỂM CHỤP',
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10.0),

        // Thẻ DTI
        _buildMetricItem(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Tỷ lệ Nợ trên Thu nhập (DTI)',
          value: report.dtiRatio != null
              ? '${(report.dtiRatio! * 100).toStringAsFixed(1)}%'
              : 'Chưa thể tính',
          description:
              'Tỷ lệ giữa nghĩa vụ trả nợ hàng tháng so với tổng thu nhập.',
          status: report.dtiRatio != null && report.dtiRatio! <= 0.4
              ? 'An toàn'
              : 'Cần lưu ý',
          statusColor: report.dtiRatio != null && report.dtiRatio! <= 0.4
              ? AppColors.success
              : AppColors.warning,
        ),

        // Thẻ LTV
        _buildMetricItem(
          icon: Icons.security_rounded,
          title: 'Tỷ lệ Khoản vay / Tài sản bảo đảm (LTV)',
          value: report.ltvRatio != null
              ? '${(report.ltvRatio! * 100).toStringAsFixed(1)}%'
              : 'Không có tài sản thế chấp',
          description:
              'Tỷ lệ dư nợ trên tổng giá trị định giá tài sản bảo đảm.',
          status: 'Hợp lệ',
          statusColor: AppColors.success,
        ),

        // Thẻ Sử dụng hạn mức
        _buildMetricItem(
          icon: Icons.credit_card_rounded,
          title: 'Tỷ lệ Sử dụng Hạn mức Tín dụng',
          value: report.creditUtilization != null
              ? '${(report.creditUtilization! * 100).toStringAsFixed(1)}%'
              : 'Chưa thể tính',
          description: 'Tỷ lệ dư nợ thẻ/thấu chi trên tổng hạn mức được cấp.',
          status:
              report.creditUtilization != null &&
                  report.creditUtilization! <= 0.35
              ? 'Tối ưu'
              : 'Trung bình',
          statusColor:
              report.creditUtilization != null &&
                  report.creditUtilization! <= 0.35
              ? AppColors.success
              : const Color(0xFF2563EB),
        ),

        // Thẻ Thanh toán đúng hạn
        _buildMetricItem(
          icon: Icons.event_available_rounded,
          title: 'Tỷ lệ Thanh toán Đúng hạn',
          value: report.onTimePaymentRate != null
              ? '${(report.onTimePaymentRate! * 100).toStringAsFixed(1)}%'
              : 'Chưa thể tính',
          description: 'Tỷ lệ các kỳ thanh toán đúng thời hạn theo kế hoạch.',
          status:
              report.onTimePaymentRate != null &&
                  report.onTimePaymentRate! >= 0.95
              ? 'Chuẩn mực'
              : 'Cần chú ý',
          statusColor:
              report.onTimePaymentRate != null &&
                  report.onTimePaymentRate! >= 0.95
              ? AppColors.success
              : AppColors.warning,
        ),

        // Thẻ Tổng dư nợ
        _buildMetricItem(
          icon: Icons.receipt_long_rounded,
          title: 'Tổng Dư nợ Kỳ này',
          value: _formatCurrency(report.totalDebt),
          description:
              'Toàn bộ số dư nợ gốc và lãi còn lại tại thời điểm lập báo cáo.',
          status: 'Đã khóa sổ',
          statusColor: AppColors.primary,
        ),

        // Thẻ Dư nợ quá hạn
        _buildMetricItem(
          icon: Icons.warning_amber_rounded,
          title: 'Tổng Tiền Quá hạn',
          value: _formatCurrency(report.overdueAmount),
          description:
              'Các khoản nợ đã quá ngày đến hạn nhưng chưa thanh toán.',
          status: report.overdueAmount == 0
              ? 'Không phát sinh'
              : 'Đang quá hạn',
          statusColor: report.overdueAmount == 0
              ? AppColors.success
              : AppColors.error,
        ),
      ],
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20.0),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
