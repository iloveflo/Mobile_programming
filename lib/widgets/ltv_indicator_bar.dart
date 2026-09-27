import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Thanh chỉ số LTV (Loan-to-Value) - Tỷ lệ dư nợ trên giá trị tài sản bảo đảm
/// Đổi màu linh hoạt theo mức độ an toàn:
/// <= 50%: Xanh lá (An toàn)
/// 50% - 70%: Vàng cam (Trung bình / Chấp nhận được)
/// > 70%: Đỏ (Rủi ro cao)
class LtvIndicatorBar extends StatelessWidget {
  final double ltvRatio; // ví dụ: 0.45 (45%)
  final double? outstandingAmount;
  final double? collateralValue;
  final bool showDetailText;

  const LtvIndicatorBar({
    super.key,
    required this.ltvRatio,
    this.outstandingAmount,
    this.collateralValue,
    this.showDetailText = true,
  });

  String _formatCurrency(num amount) {
    final str = amount.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} đ';
  }

  Color get statusColor {
    if (ltvRatio <= 0.50) return AppColors.success;
    if (ltvRatio <= 0.70) return AppColors.warning;
    return AppColors.error;
  }

  String get statusLabel {
    if (ltvRatio <= 0.50) return 'An toàn (≤50%)';
    if (ltvRatio <= 0.70) return 'Trung bình (50-70%)';
    return 'Cảnh báo rủi ro (>70%)';
  }

  @override
  Widget build(BuildContext context) {
    final percentInt = (ltvRatio * 100).round();
    final color = statusColor;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 18.0,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 6.0),
                  Text(
                    'Tỷ lệ LTV (Loan-to-Value)',
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dư nợ / Giá trị TSBĐ',
                style: TextStyle(
                  fontSize: 12.0,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '$percentInt%',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.0),
            child: LinearProgressIndicator(
              value: ltvRatio.clamp(0.0, 1.0),
              minHeight: 8.0,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (showDetailText &&
              outstandingAmount != null &&
              collateralValue != null) ...[
            const SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dư nợ: ${_formatCurrency(outstandingAmount!)}',
                  style: const TextStyle(
                    fontSize: 11.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'TSBĐ: ${_formatCurrency(collateralValue!)}',
                  style: const TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
