import 'package:flutter/material.dart';

import '../../models/payment_schedule_model.dart';
import '../common/app_colors.dart';

/// Thẻ hiển thị một kỳ phân kỳ thanh toán trong danh sách (Mục 5.2)
class PaymentScheduleCard extends StatelessWidget {
  final PaymentScheduleModel schedule;
  final String? loanName;
  final VoidCallback onTap;
  final VoidCallback onPay;

  const PaymentScheduleCard({
    super.key,
    required this.schedule,
    this.loanName,
    required this.onTap,
    required this.onPay,
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

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    return '$day/$month/${dt.year}';
  }

  String _resolveStatusLabel(String status, DateTime dueDate) {
    if (status == 'PAID') return 'Đã thanh toán';
    final now = DateTime.now();
    if (status == 'OVERDUE' || dueDate.isBefore(now)) return 'Quá hạn';

    final daysDiff = dueDate.difference(now).inDays;
    if (daysDiff >= 0 && daysDiff <= 5) return 'Sắp đến hạn ($daysDiff ngày)';
    return 'Chưa đến hạn';
  }

  Color _resolveStatusColor(String status, DateTime dueDate) {
    if (status == 'PAID') return AppColors.success;
    final now = DateTime.now();
    if (status == 'OVERDUE' || dueDate.isBefore(now)) return AppColors.error;

    final daysDiff = dueDate.difference(now).inDays;
    if (daysDiff >= 0 && daysDiff <= 5) return AppColors.warning;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _resolveStatusColor(schedule.status, schedule.dueDate);
    final statusLabel = _resolveStatusLabel(schedule.status, schedule.dueDate);
    final isPaid = schedule.status == 'PAID';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: schedule.status == 'OVERDUE'
                ? AppColors.error.withValues(alpha: 0.4)
                : AppColors.border,
            width: schedule.status == 'OVERDUE' ? 1.5 : 1.0,
          ),
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
            // Dòng 1: Kỳ thanh toán & Trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 5.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          'Kỳ ${schedule.installmentNumber}',
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (loanName != null) ...[
                              Text(
                                loanName!,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2.0),
                            ],
                            Row(
                              children: [
                                const Icon(
                                  Icons.event_rounded,
                                  size: 13.0,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4.0),
                                Expanded(
                                  child: Text(
                                    'Hạn: ${_formatDate(schedule.dueDate)}',
                                    style: const TextStyle(
                                      fontSize: 12.0,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20.0, color: AppColors.border),

            // Dòng 2: Chi tiết các thành phần số tiền (Gốc, Lãi, Tổng phải trả)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tiền gốc',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      _formatCurrency(schedule.principalAmount),
                      style: const TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tiền lãi',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      _formatCurrency(schedule.interestAmount),
                      style: const TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Tổng phải trả',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      _formatCurrency(schedule.totalAmount),
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (!isPaid) ...[
              const SizedBox(height: 14.0),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onPay,
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 16.0,
                  ),
                  label: const Text('Ghi nhận thanh toán'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
