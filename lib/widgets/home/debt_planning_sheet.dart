import 'package:flutter/material.dart';

import '../../routes/app_router.dart';
import '../../screens/main_shell_screen.dart';
import '../widget.dart';

/// Modal BottomSheet Kế hoạch & Tối ưu Trả nợ (Snowball, Avalanche, Simulation, Schedule)
class DebtPlanningSheet extends StatelessWidget {
  const DebtPlanningSheet({super.key});

  /// Phương thức hiển thị modal
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => const DebtPlanningSheet(),
    );
  }

  Widget _buildPlanningOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: Colors.white, size: 22.0),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6.0),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14.0,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: AppColors.primary,
                  size: 22.0,
                ),
              ),
              const SizedBox(width: 10.0),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kế hoạch & Tối ưu Trả nợ',
                      style: TextStyle(
                        fontSize: 17.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2.0),
                    Text(
                      'Chọn công cụ quản trị nghĩa vụ nợ thông minh',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 18.0),

          // Lựa chọn 1: Chiến lược tối ưu trả nợ (Snowball / Avalanche)
          _buildPlanningOptionCard(
            context: context,
            title: 'Chiến lược tối ưu trả nợ',
            subtitle:
                'Áp dụng thuật toán Snowball (dư nợ nhỏ trước) hoặc Avalanche (lãi suất cao trước) để tiết kiệm tối đa tiền lãi và rút ngắn thời gian trả nợ.',
            badge: 'Khuyên dùng • Tiết kiệm lãi',
            badgeColor: const Color(0xFF16A34A),
            icon: Icons.auto_graph_rounded,
            color: const Color(0xFF2563EB),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.debtStrategy);
            },
          ),
          const SizedBox(height: 12.0),

          // Lựa chọn 2: Mô phỏng kịch bản trả nợ (Simulation)
          _buildPlanningOptionCard(
            context: context,
            title: 'Mô phỏng kịch bản trả nợ',
            subtitle:
                'Dự toán chính xác số tiền lãi tiết kiệm được khi trả thêm định kỳ, tất toán trước hạn hoặc kiểm tra tác động khi lãi suất thị trường thay đổi.',
            badge: 'Dự toán tài chính',
            badgeColor: const Color(0xFF7C3AED),
            icon: Icons.trending_up_rounded,
            color: const Color(0xFFE11D48),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.simulation);
            },
          ),
          const SizedBox(height: 12.0),

          // Lựa chọn 3: Xem lịch phân kỳ thanh toán
          _buildPlanningOptionCard(
            context: context,
            title: 'Lịch phân kỳ thanh toán định kỳ',
            subtitle:
                'Xem toàn bộ lịch trả nợ của từng hợp đồng, các kỳ sắp đến hạn, lịch sử thanh toán và biên lai định kỳ.',
            badge: 'Kỳ hạn chi tiết',
            badgeColor: const Color(0xFF0891B2),
            icon: Icons.calendar_month_outlined,
            color: const Color(0xFF0D9488),
            onTap: () {
              Navigator.pop(context);
              MainShellScreen.switchTab(context, 2); // Tab Lịch trả nợ
            },
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
