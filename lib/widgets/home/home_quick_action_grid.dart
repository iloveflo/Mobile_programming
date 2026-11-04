import 'package:flutter/material.dart';

import '../widget.dart';

class _QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

/// Lưới 8 phím tắt thao tác nhanh (4x2 Quick Action Grid) trên trang chủ
class HomeQuickActionGrid extends StatelessWidget {
  final VoidCallback onAddLoan;
  final VoidCallback onViewSchedule;
  final VoidCallback onViewCic;
  final VoidCallback onOcr;
  final VoidCallback onInterestCalc;
  final VoidCallback onSimulation;
  final VoidCallback onDebtStrategy;
  final VoidCallback onDtiReport;

  const HomeQuickActionGrid({
    super.key,
    required this.onAddLoan,
    required this.onViewSchedule,
    required this.onViewCic,
    required this.onOcr,
    required this.onInterestCalc,
    required this.onSimulation,
    required this.onDebtStrategy,
    required this.onDtiReport,
  });

  Widget _buildQuickActionButton(_QuickActionItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(item.icon, color: item.color, size: 22.0),
            ),
            const SizedBox(height: 6.0),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionItem(
        icon: Icons.add_circle_outline_rounded,
        label: 'Thêm\nkhoản vay',
        color: const Color(0xFF0D47A1),
        onTap: onAddLoan,
      ),
      _QuickActionItem(
        icon: Icons.calendar_month_outlined,
        label: 'Lịch trả\nnợ tới',
        color: const Color(0xFF0284C7),
        onTap: onViewSchedule,
      ),
      _QuickActionItem(
        icon: Icons.shield_outlined,
        label: 'Tra cứu\nCIC',
        color: const Color(0xFF059669),
        onTap: onViewCic,
      ),
      _QuickActionItem(
        icon: Icons.document_scanner_outlined,
        label: 'Quét hợp\nđồng OCR',
        color: const Color(0xFFD97706),
        onTap: onOcr,
      ),
      _QuickActionItem(
        icon: Icons.calculate_outlined,
        label: 'Máy tính\nlãi suất',
        color: const Color(0xFF7C3AED),
        onTap: onInterestCalc,
      ),
      _QuickActionItem(
        icon: Icons.trending_up_rounded,
        label: 'Mô phỏng\ntrả nợ',
        color: const Color(0xFFE11D48),
        onTap: onSimulation,
      ),
      _QuickActionItem(
        icon: Icons.auto_graph_rounded,
        label: 'Tối ưu\ntrả nợ',
        color: const Color(0xFF2563EB),
        onTap: onDebtStrategy,
      ),
      _QuickActionItem(
        icon: Icons.pie_chart_outline_rounded,
        label: 'Báo cáo\nDTI',
        color: const Color(0xFF0891B2),
        onTap: onDtiReport,
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < 4; i++)
                Expanded(child: _buildQuickActionButton(actions[i])),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 4; i < 8; i++)
                Expanded(child: _buildQuickActionButton(actions[i])),
            ],
          ),
        ],
      ),
    );
  }
}
