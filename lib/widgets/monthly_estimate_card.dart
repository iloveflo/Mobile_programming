import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'interest_method_card.dart';

/// Thẻ hiển thị ước tính chi phí trả nợ hàng tháng theo thời gian thực (MonthlyEstimateCard)
class MonthlyEstimateCard extends StatelessWidget {
  final double principal;
  final double annualInterestRate; // e.g. 10.5 (%)
  final int tenorMonths;
  final InterestMethod interestMethod;

  const MonthlyEstimateCard({
    super.key,
    required this.principal,
    required this.annualInterestRate,
    required this.tenorMonths,
    this.interestMethod = InterestMethod.reducingBalance,
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

  @override
  Widget build(BuildContext context) {
    if (principal <= 0 || tenorMonths <= 0) {
      return const SizedBox.shrink();
    }

    final double monthlyRate = (annualInterestRate / 100) / 12;
    double principalMonth1 = 0;
    double interestMonth1 = 0;
    double totalMonth1 = 0;
    double totalInterestAllTenor = 0;

    if (interestMethod == InterestMethod.reducingBalance) {
      // Dư nợ giảm dần: Gốc đều hàng tháng + Lãi theo dư nợ thực tế
      principalMonth1 = principal / tenorMonths;
      interestMonth1 = principal * monthlyRate;
      totalMonth1 = principalMonth1 + interestMonth1;
      // Tổng lãi cả kỳ xấp xỉ = principal * monthlyRate * (tenorMonths + 1) / 2
      totalInterestAllTenor = principal * monthlyRate * (tenorMonths + 1) / 2;
    } else {
      // Lãi suất phẳng (Flat rate): Gốc đều + Lãi cố định trên gốc ban đầu
      principalMonth1 = principal / tenorMonths;
      interestMonth1 = principal * monthlyRate;
      totalMonth1 = principalMonth1 + interestMonth1;
      totalInterestAllTenor = interestMonth1 * tenorMonths;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calculate_rounded,
                color: AppColors.primary,
                size: 20.0,
              ),
              const SizedBox(width: 8.0),
              const Text(
                'Ước tính thanh toán kỳ đầu tiên',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '$tenorMonths tháng',
                  style: const TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatCurrency(totalMonth1),
                style: const TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 4.0),
              const Text(
                '/ tháng',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tiền gốc tháng 1:',
                style: TextStyle(
                  fontSize: 12.0,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _formatCurrency(principalMonth1),
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tiền lãi tháng 1:',
                style: TextStyle(
                  fontSize: 12.0,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _formatCurrency(interestMonth1),
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng lãi dự kiến cả kỳ:',
                style: TextStyle(
                  fontSize: 12.0,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _formatCurrency(totalInterestAllTenor),
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
