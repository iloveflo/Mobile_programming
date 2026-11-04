import 'dart:math';
import 'package:flutter/material.dart';

import '../../controllers/loan_controller.dart';
import '../widget.dart';

/// Thẻ hiển thị biểu đồ trực quan dự phóng dòng tiền trả nợ 6 tháng trên trang chủ
class HomeCashflowProjectionCard extends StatelessWidget {
  final LoanController loanController;

  const HomeCashflowProjectionCard({super.key, required this.loanController});

  @override
  Widget build(BuildContext context) {
    final activeLoans = loanController.loans.where((l) => l.isActive).toList();

    // Tính toán dự phóng 6 tháng dựa trên dữ liệu thực tế từ các khoản vay
    final now = DateTime.now();
    final List<String> months = [];
    final List<double> values = []; // đơn vị triệu đồng

    for (int i = 0; i < 6; i++) {
      final monthDate = DateTime(now.year, now.month + i, 1);
      months.add('T${monthDate.month.toString().padLeft(2, '0')}');

      double monthPayment = 0.0;
      for (final loan in activeLoans) {
        final effectiveEndDate =
            loan.endDate ??
            DateTime(
              loan.startDate.year,
              loan.startDate.month + loan.termMonths,
              loan.startDate.day,
            );
        final isMonthActive =
            monthDate.isBefore(effectiveEndDate) ||
            (monthDate.year == effectiveEndDate.year &&
                monthDate.month <= effectiveEndDate.month);

        if (isMonthActive) {
          if (loan.interestMethod == 'REDUCING_BALANCE' &&
              loan.termMonths > 0) {
            final double principalPortion =
                loan.principalAmount / loan.termMonths;
            final double estimatedRemaining =
                (loan.outstandingAmount - (principalPortion * i)).clamp(
                  0.0,
                  loan.principalAmount,
                );
            final double monthlyInterest =
                estimatedRemaining * (loan.interestRate / 12.0);
            monthPayment += (principalPortion + monthlyInterest);
          } else {
            monthPayment += loan.monthlyInstallmentEstimate;
          }
        }
      }
      values.add(double.parse((monthPayment / 1000000.0).toStringAsFixed(1)));
    }

    final double totalProjectedMillion = values.fold(0.0, (sum, v) => sum + v);
    final double maxVal = values.isEmpty
        ? 1.0
        : (values.reduce(max) > 0 ? values.reduce(max) * 1.2 : 1.0);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dự phóng dòng tiền trả nợ (6 tháng)',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                totalProjectedMillion > 0
                    ? 'Tổng: ${totalProjectedMillion.toStringAsFixed(1)} tr'
                    : 'Tổng: 0 đ',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Các cột biểu đồ trực quan
          if (totalProjectedMillion <= 0)
            Container(
              height: 100.0,
              alignment: Alignment.center,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 32.0,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 6.0),
                  Text(
                    'Không có nghĩa vụ trả nợ trong 6 tháng tới',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 120.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(months.length, (idx) {
                  final heightFactor = (values[idx] / maxVal).clamp(0.1, 1.0);
                  final isCurrent = idx == 0;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${values[idx]}tr',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Container(
                        width: 28.0,
                        height: 75.0 * heightFactor,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primary
                              : const Color(0xFF93C5FD).withValues(alpha: 0.6),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        months[idx],
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
