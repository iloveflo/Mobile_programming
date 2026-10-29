import 'package:flutter/material.dart';

import '../../models/simulation_model.dart';
import '../common/app_colors.dart';

/// Bảng đối chiếu kịch bản mô phỏng và kế hoạch hiện tại (Mục 11 & 10.3)
class SimulationComparisonTable extends StatelessWidget {
  final SimulationComparisonResult comparison;

  const SimulationComparisonTable({super.key, required this.comparison});

  String _formatCurrency(double amount) {
    final integerPart = amount.round().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = integerPart.length - 1; i >= 0; i--) {
      buffer.write(integerPart[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString().split('').reversed.join()} đ';
  }

  String _formatDate(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    return '$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final bool isSavingPositive = comparison.totalCostDifference > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Highlight thẻ tổng kết lợi ích tài chính
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSavingPositive
                  ? [const Color(0xFF16A34A), const Color(0xFF22C55E)]
                  : [const Color(0xFF0D47A1), const Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color:
                    (isSavingPositive ? AppColors.success : AppColors.primary)
                        .withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSavingPositive
                      ? Icons.savings_rounded
                      : Icons.insights_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSavingPositive
                          ? 'TIẾT KIỆM TỔNG CHI PHÍ DỰ KIẾN'
                          : 'KẾT QUẢ DỰ PHÓNG MÔ PHỎNG',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSavingPositive
                          ? '+ ${_formatCurrency(comparison.totalCostDifference)}'
                          : _formatCurrency(comparison.simulatedTotalPayment),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (comparison.monthsReduced > 0)
                      Text(
                        'Rút ngắn ${comparison.monthsReduced} tháng thời gian thanh toán',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Tiêu đề bảng đối chiếu Mục 11
        const Text(
          'BẢNG ĐỐI CHIẾU CHỈ TIÊU TÀI CHÍNH',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Chỉ tiêu tài chính',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Hiện tại',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Mô phỏng (Chênh lệch)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // 1. Dư nợ còn lại
              _buildRow(
                'Dư nợ còn lại',
                _formatCurrency(comparison.currentBalance),
                _formatCurrency(comparison.simulatedBalance),
                diffLabel:
                    comparison.simulatedBalance < comparison.currentBalance
                    ? 'Giảm ${_formatCurrency(comparison.currentBalance - comparison.simulatedBalance)}'
                    : 'Giữ nguyên',
                isPositive:
                    comparison.simulatedBalance < comparison.currentBalance,
              ),

              // 2. Tổng lãi phải trả
              _buildRow(
                'Tổng lãi phải trả',
                _formatCurrency(comparison.currentTotalInterest),
                _formatCurrency(comparison.simulatedTotalInterest),
                diffLabel: comparison.interestSaved > 0
                    ? 'Tiết kiệm ${_formatCurrency(comparison.interestSaved)}'
                    : (comparison.interestSaved < 0
                          ? 'Tăng ${_formatCurrency(-comparison.interestSaved)}'
                          : '0 đ'),
                isPositive: comparison.interestSaved > 0,
              ),

              // 3. Số kỳ còn lại
              _buildRow(
                'Số kỳ còn lại',
                '${comparison.currentRemainingTerms} kỳ',
                '${comparison.simulatedRemainingTerms} kỳ',
                diffLabel: comparison.monthsReduced > 0
                    ? 'Rút ngắn ${comparison.monthsReduced} kỳ'
                    : (comparison.monthsReduced < 0
                          ? 'Kéo dài ${-comparison.monthsReduced} kỳ'
                          : 'Không đổi'),
                isPositive: comparison.monthsReduced > 0,
              ),

              // 4. Số tiền trả mỗi kỳ
              _buildRow(
                'Định mức mỗi kỳ',
                _formatCurrency(comparison.currentMonthlyPayment),
                _formatCurrency(comparison.simulatedMonthlyPayment),
                diffLabel:
                    (comparison.simulatedMonthlyPayment -
                                comparison.currentMonthlyPayment)
                            .abs() <
                        100
                    ? 'Không đổi'
                    : (comparison.simulatedMonthlyPayment >
                              comparison.currentMonthlyPayment
                          ? '+ ${_formatCurrency(comparison.simulatedMonthlyPayment - comparison.currentMonthlyPayment)}'
                          : '- ${_formatCurrency(comparison.currentMonthlyPayment - comparison.simulatedMonthlyPayment)}'),
              ),

              // 5. Tổng số tiền phải trả
              _buildRow(
                'Tổng số tiền phải trả',
                _formatCurrency(comparison.currentTotalPayment),
                _formatCurrency(comparison.simulatedTotalPayment),
                diffLabel: comparison.totalCostDifference > 0
                    ? 'Giảm ${_formatCurrency(comparison.totalCostDifference)}'
                    : (comparison.totalCostDifference < 0
                          ? 'Tăng ${_formatCurrency(-comparison.totalCostDifference)}'
                          : '0 đ'),
                isPositive: comparison.totalCostDifference > 0,
              ),

              // 6. Phí phát sinh (nếu có)
              if (comparison.simulatedFees > 0)
                _buildRow(
                  'Phí phát sinh (Phạt sớm)',
                  '0 đ',
                  _formatCurrency(comparison.simulatedFees),
                  diffLabel: 'Phí trả trước hạn',
                  isWarning: true,
                ),

              // 7. Thời gian tất toán dự kiến
              _buildRow(
                'Tất toán dự kiến',
                _formatDate(comparison.currentPayoffDate),
                _formatDate(comparison.simulatedPayoffDate),
                diffLabel: comparison.monthsReduced > 0
                    ? 'Sớm ${comparison.monthsReduced} tháng'
                    : 'Đúng hạn',
                isPositive: comparison.monthsReduced > 0,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(
    String label,
    String colCurrent,
    String colSimulated, {
    required String diffLabel,
    bool isPositive = false,
    bool isWarning = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.6),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              colCurrent,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  colSimulated,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  diffLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isWarning
                        ? AppColors.warning
                        : (isPositive
                              ? AppColors.success
                              : AppColors.textSecondary),
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
