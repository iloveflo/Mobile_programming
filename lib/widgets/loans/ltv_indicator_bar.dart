import 'package:flutter/material.dart';

import '../common/app_colors.dart';

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
  final double? sharedSecuredDebt;
  final int sharedLoanCount;
  final String debtLabel;

  const LtvIndicatorBar({
    super.key,
    required this.ltvRatio,
    this.outstandingAmount,
    this.collateralValue,
    this.showDetailText = true,
    this.sharedSecuredDebt,
    this.sharedLoanCount = 0,
    this.debtLabel = 'Dư nợ',
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
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 18.0,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        'Tỷ lệ bảo đảm nợ (LTV)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130.0),
                child: Container(
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dư nợ / Giá trị TSBĐ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
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
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$debtLabel: ${_formatCurrency(outstandingAmount!)}',
                      style: const TextStyle(
                        fontSize: 11.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'TSBĐ: ${_formatCurrency(collateralValue!)}',
                      style: const TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (sharedLoanCount > 1 &&
              sharedSecuredDebt != null &&
              collateralValue != null &&
              collateralValue! > 0) ...[
            const SizedBox(height: 8.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.25),
                ),
              ),
              child: Text(
                'TSBĐ đang bảo đảm chung cho $sharedLoanCount khoản vay • Tổng dư nợ trên TSBĐ: ${_formatCurrency(sharedSecuredDebt!)} (LTV thực tế: ${((sharedSecuredDebt! / collateralValue!) * 100).round()}%)',
                style: const TextStyle(
                  fontSize: 11.0,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
