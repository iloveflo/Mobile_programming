import 'package:flutter/material.dart';

import '../../models/payment_schedule_model.dart';
import '../common/app_colors.dart';

/// Modal chi tiết toàn diện của một kỳ phân kỳ thanh toán (Mục 5.2)
class ScheduleDetailSheet extends StatelessWidget {
  final PaymentScheduleModel schedule;
  final String? loanName;
  final VoidCallback onPay;

  const ScheduleDetailSheet({
    super.key,
    required this.schedule,
    this.loanName,
    required this.onPay,
  });

  static Future<void> show(
    BuildContext context, {
    required PaymentScheduleModel schedule,
    String? loanName,
    required VoidCallback onPay,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScheduleDetailSheet(
        schedule: schedule,
        loanName: loanName,
        onPay: onPay,
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final isPaid = schedule.status == 'PAID';
    final now = DateTime.now();
    final isOverdue =
        schedule.status == 'OVERDUE' ||
        (!isPaid && schedule.dueDate.isBefore(now));

    final statusColor = isPaid
        ? AppColors.success
        : (isOverdue ? AppColors.error : AppColors.primary);

    final statusText = isPaid
        ? 'Đã thanh toán hoàn tất'
        : (isOverdue ? 'Kỳ quá hạn thanh toán' : 'Chờ thanh toán định kỳ');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          const SizedBox(height: 18.0),

          // Tiêu đề & Trạng thái
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chi tiết Kỳ ${schedule.installmentNumber}',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (loanName != null) ...[
                    const SizedBox(height: 2.0),
                    Text(
                      loanName!,
                      style: const TextStyle(
                        fontSize: 13.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Tổng phải trả nổi bật
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng nghĩa vụ phải trả',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  _formatCurrency(schedule.totalAmount),
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18.0),

          // Danh mục các thành phần số tiền
          _buildRow('Hạn thanh toán bắt buộc', _formatDate(schedule.dueDate)),
          _buildRow(
            'Tiền nợ gốc trong kỳ',
            _formatCurrency(schedule.principalAmount),
          ),
          _buildRow(
            'Tiền lãi phát sinh',
            _formatCurrency(schedule.interestAmount),
          ),
          _buildRow(
            'Phí dịch vụ phát sinh',
            _formatCurrency(schedule.feeAmount),
          ),
          const Divider(height: 18.0, color: AppColors.border),
          _buildRow(
            'Dư nợ còn lại sau kỳ này',
            _formatCurrency(schedule.remainingBalance),
            isBold: true,
          ),
          const SizedBox(height: 24.0),

          // Nút hành động
          if (!isPaid) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onPay();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Ghi nhận hoàn tất thanh toán kỳ này',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46.0),
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text('Đóng'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.0,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
