import 'package:flutter/material.dart';

import '../common/app_colors.dart';

/// Thẻ tổng quan tài chính cho Lịch phân kỳ & Nhắc nợ
class ScheduleSummaryCard extends StatelessWidget {
  final double currentMonthDueAmount;
  final int upcomingCount;
  final int overdueCount;
  final int paidCount;
  final VoidCallback onOpenPreferences;
  final VoidCallback onOpenNotifications;

  const ScheduleSummaryCard({
    super.key,
    required this.currentMonthDueAmount,
    required this.upcomingCount,
    required this.overdueCount,
    required this.paidCount,
    required this.onOpenPreferences,
    required this.onOpenNotifications,
  });

  String _formatCurrency(double amount) {
    final integerPart = amount.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integerPart[i]);
    }
    return '${buffer.toString()} đ';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 14.0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng 1: Tiêu đề & Nút thao tác nhanh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nghĩa vụ thanh toán tháng này',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white,
                      size: 22.0,
                    ),
                    tooltip: 'Hộp thư nhắc nợ',
                    visualDensity: VisualDensity.compact,
                    onPressed: onOpenNotifications,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 22.0,
                    ),
                    tooltip: 'Cài đặt nhắc nợ',
                    visualDensity: VisualDensity.compact,
                    onPressed: onOpenPreferences,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            _formatCurrency(currentMonthDueAmount),
            style: const TextStyle(
              fontSize: 26.0,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16.0),

          // Dòng 2: 3 chỉ số trạng thái nhanh (Quá hạn, Sắp đến hạn, Đã trả)
          Row(
            children: [
              _buildBadge(
                label: 'Quá hạn',
                count: overdueCount,
                backgroundColor: overdueCount > 0
                    ? AppColors.error.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.15),
                textColor: Colors.white,
              ),
              const SizedBox(width: 8.0),
              _buildBadge(
                label: 'Sắp đến hạn',
                count: upcomingCount,
                backgroundColor: upcomingCount > 0
                    ? AppColors.warning.withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.15),
                textColor: Colors.white,
              ),
              const SizedBox(width: 8.0),
              _buildBadge(
                label: 'Đã hoàn tất',
                count: paidCount,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                textColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required int count,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: 0.85),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
