import 'package:flutter/material.dart';

import '../common/app_colors.dart';

/// Khối ghi chú nguyên tắc phân tách môi trường và không can thiệp nợ thực tế (Mục 1, 3 & 13)
class SimulationNoticeCard extends StatelessWidget {
  const SimulationNoticeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // soft blue tint
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nguyên tắc độc lập & Bảo toàn dữ liệu (Mục 13)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Đây là kịch bản tính toán giả định trên bản sao độc lập. Kết quả mô phỏng tuyệt đối KHÔNG tự động thay đổi dư nợ, lãi suất hợp đồng hay lịch trả nợ thực tế tại bên cho vay.',
                  style: TextStyle(
                    fontSize: 11.5,
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
}
