import 'package:flutter/material.dart';

import '../../models/credit_profile_model.dart';
import '../common/app_colors.dart';

/// Widget hiển thị Điểm sức khỏe tín dụng dạng Gauge tròn với thang điểm 850 và phân loại rủi ro
class CreditScoreGauge extends StatelessWidget {
  final CreditProfileModel? profile;
  final bool isRecalculating;
  final VoidCallback onRecalculate;

  const CreditScoreGauge({
    super.key,
    required this.profile,
    required this.isRecalculating,
    required this.onRecalculate,
  });

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Chưa cập nhật';
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final int score = profile?.creditScore ?? 0;
    final double progress = (score / 850.0).clamp(0.0, 1.0);

    final Color themeColor;
    final String riskText;
    final String tierTitle;

    if (score >= 750) {
      themeColor = const Color(0xFF16A34A);
      riskText = 'Rủi ro rất thấp • Chuẩn mực';
      tierTitle = 'Hạng 1 (Xuất sắc)';
    } else if (score >= 680) {
      themeColor = const Color(0xFF059669);
      riskText = 'Rủi ro thấp • Đạt chuẩn';
      tierTitle = 'Hạng 2 (Rất tốt)';
    } else if (score >= 580) {
      themeColor = const Color(0xFFD97706);
      riskText = 'Rủi ro trung bình';
      tierTitle = 'Hạng 3 (Khá)';
    } else if (score >= 450) {
      themeColor = const Color(0xFFEA580C);
      riskText = 'Cần chú ý';
      tierTitle = 'Hạng 4 (Trung bình)';
    } else {
      themeColor = const Color(0xFFDC2626);
      riskText = 'Rủi ro cao';
      tierTitle = 'Hạng 5 (Cần cải thiện)';
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header: Tiêu đề + Nút tính toán lại
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ĐIỂM SỨC KHỎE TÍN DỤNG',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    'Cập nhật: ${_formatDate(profile?.updatedAt)}',
                    style: const TextStyle(
                      fontSize: 11.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: isRecalculating
                    ? const SizedBox(
                        width: 18.0,
                        height: 18.0,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.sync_rounded, color: AppColors.primary),
                tooltip: 'Yêu cầu tính toán lại',
                onPressed: isRecalculating ? null : onRecalculate,
              ),
            ],
          ),
          const SizedBox(height: 18.0),

          // Vòng cung điểm nổi bật
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 154.0,
                  height: 154.0,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 14.0,
                    backgroundColor: AppColors.primarySoft,
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score > 0 ? '$score' : '--',
                      style: const TextStyle(
                        fontSize: 38.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const Text(
                      'Thang điểm: 850',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Badge phân loại rủi ro
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 6.0,
            ),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 16.0, color: themeColor),
                const SizedBox(width: 6.0),
                Text(
                  '$tierTitle • $riskText',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: themeColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          const Text(
            'Chỉ số được thẩm định và tổng hợp từ dữ liệu khoản vay, lịch phân kỳ và giao dịch thanh toán.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
