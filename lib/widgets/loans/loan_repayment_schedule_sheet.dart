import 'package:flutter/material.dart';

import '../../models/loan_model.dart';
import '../widget.dart';

/// Modal BottomSheet hiển thị toàn bộ lịch trình trả nợ định kỳ của khoản vay
class LoanRepaymentScheduleSheet extends StatelessWidget {
  final LoanModel loan;

  const LoanRepaymentScheduleSheet({super.key, required this.loan});

  /// Phương thức hiển thị modal
  static Future<void> show(BuildContext context, {required LoanModel loan}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => LoanRepaymentScheduleSheet(loan: loan),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final double monthlyPrincipal = loan.tenorMonths > 0
        ? loan.principalAmount / loan.tenorMonths
        : 0;
    final double monthlyRate = (loan.interestRatePercent / 100) / 12;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (sheetContext, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8.0),
                  const Text(
                    'Lịch trả nợ định kỳ',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                'Kỳ hạn: ${loan.tenorMonths} tháng • Lãi suất: ${loan.interestRateFormatted}',
                style: const TextStyle(
                  fontSize: 13.0,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14.0),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 10.0),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: loan.tenorMonths.clamp(1, 60),
                  separatorBuilder: (_, _) =>
                      const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (ctx, i) {
                    final month = i + 1;
                    final interest =
                        (loan.principalAmount - (monthlyPrincipal * i)).clamp(
                          0.0,
                          loan.principalAmount,
                        ) *
                        monthlyRate;
                    final total = monthlyPrincipal + interest;
                    final isPaid =
                        month <=
                        (loan.progressRatio * loan.tenorMonths).round();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14.0,
                            backgroundColor: isPaid
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.primarySoft,
                            child: Text(
                              '$month',
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                color: isPaid
                                    ? AppColors.success
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kỳ thứ $month',
                                  style: const TextStyle(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Gốc: ${_formatCurrency(monthlyPrincipal)} • Lãi: ${_formatCurrency(interest)}',
                                  style: const TextStyle(
                                    fontSize: 11.0,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _formatCurrency(total),
                            style: const TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
