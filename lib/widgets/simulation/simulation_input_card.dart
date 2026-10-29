import 'package:flutter/material.dart';

import '../../models/loan_model.dart';
import '../../models/simulation_model.dart';
import '../common/app_colors.dart';

/// Thẻ nhập tham số giả định và lựa chọn khoản vay cơ sở (Mục 5.2, 7, 8, 9, 10)
class SimulationInputCard extends StatelessWidget {
  final List<LoanModel> availableLoans;
  final LoanModel selectedLoan;
  final ValueChanged<LoanModel> onLoanChanged;
  final SimulationScenarioType scenario;

  final double extraPayment;
  final ValueChanged<double> onExtraPaymentChanged;

  final double newMonthlyPayment;
  final ValueChanged<double> onNewMonthlyPaymentChanged;

  final double newInterestRate;
  final ValueChanged<double> onNewInterestRateChanged;

  final int earlyPayoffMonths;
  final ValueChanged<int> onEarlyPayoffMonthsChanged;

  final double earlyPaymentFeeRate;
  final ValueChanged<double> onEarlyPaymentFeeRateChanged;

  final String? errorMessage;
  final String? exceptionCode;

  const SimulationInputCard({
    super.key,
    required this.availableLoans,
    required this.selectedLoan,
    required this.onLoanChanged,
    required this.scenario,
    required this.extraPayment,
    required this.onExtraPaymentChanged,
    required this.newMonthlyPayment,
    required this.onNewMonthlyPaymentChanged,
    required this.newInterestRate,
    required this.onNewInterestRateChanged,
    required this.earlyPayoffMonths,
    required this.onEarlyPayoffMonthsChanged,
    required this.earlyPaymentFeeRate,
    required this.onEarlyPaymentFeeRateChanged,
    this.errorMessage,
    this.exceptionCode,
  });

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

  @override
  Widget build(BuildContext context) {
    final bool hasError = exceptionCode == 'EX-03';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasError ? AppColors.error : AppColors.border,
          width: hasError ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Bộ chọn khoản vay cơ sở
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KHOẢN VAY CƠ SỞ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Dư nợ: ${_formatCurrency(selectedLoan.outstandingAmount)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: selectedLoan.id,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                ),
                items: availableLoans.map((l) {
                  return DropdownMenuItem<int>(
                    value: l.id,
                    child: Text(
                      '${l.name} (${l.lender ?? "TCTD"})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) {
                    final found = availableLoans.firstWhere((l) => l.id == id);
                    onLoanChanged(found);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          // 2. Form nhập tham số giả định theo từng kịch bản
          _buildScenarioInputFields(context),

          // 3. Cảnh báo lỗi EX-03 nếu tham số không hợp lệ
          if (hasError && errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScenarioInputFields(BuildContext context) {
    switch (scenario) {
      // Kịch bản 1: Trả thêm một khoản
      case SimulationScenarioType.extraPayment:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Số tiền muốn trả thêm',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  _formatCurrency(extraPayment),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Slider(
              value: extraPayment.clamp(
                1000000.0,
                selectedLoan.outstandingAmount,
              ),
              min: 1000000,
              max: selectedLoan.outstandingAmount > 1000000
                  ? selectedLoan.outstandingAmount
                  : 2000000,
              divisions: 20,
              activeColor: AppColors.primary,
              onChanged: onExtraPaymentChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickChip(
                  '5 triệu',
                  5000000,
                  extraPayment,
                  onExtraPaymentChanged,
                ),
                _buildQuickChip(
                  '10 triệu',
                  10000000,
                  extraPayment,
                  onExtraPaymentChanged,
                ),
                _buildQuickChip(
                  '20 triệu',
                  20000000,
                  extraPayment,
                  onExtraPaymentChanged,
                ),
                _buildQuickChip(
                  '50 triệu',
                  50000000,
                  extraPayment,
                  onExtraPaymentChanged,
                ),
              ],
            ),
          ],
        );

      // Kịch bản 2: Thay đổi số tiền trả mỗi kỳ
      case SimulationScenarioType.changePayment:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Định mức trả mới mỗi kỳ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_formatCurrency(newMonthlyPayment)}/tháng',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Slider(
              value: newMonthlyPayment.clamp(1000000.0, 50000000.0),
              min: 1000000,
              max: 50000000,
              divisions: 49,
              activeColor: AppColors.primary,
              onChanged: onNewMonthlyPaymentChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickChip(
                  '3 triệu',
                  3000000,
                  newMonthlyPayment,
                  onNewMonthlyPaymentChanged,
                ),
                _buildQuickChip(
                  '5 triệu',
                  5000000,
                  newMonthlyPayment,
                  onNewMonthlyPaymentChanged,
                ),
                _buildQuickChip(
                  '8 triệu',
                  8000000,
                  newMonthlyPayment,
                  onNewMonthlyPaymentChanged,
                ),
                _buildQuickChip(
                  '12 triệu',
                  12000000,
                  newMonthlyPayment,
                  onNewMonthlyPaymentChanged,
                ),
              ],
            ),
          ],
        );

      // Kịch bản 3: Thay đổi lãi suất
      case SimulationScenarioType.changeInterestRate:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lãi suất giả định mới',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${(newInterestRate * 100).toStringAsFixed(1)}%/năm',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Slider(
              value: newInterestRate.clamp(0.01, 0.30),
              min: 0.01,
              max: 0.30,
              divisions: 29,
              activeColor: AppColors.primary,
              onChanged: onNewInterestRateChanged,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickRateChip('6.5%', 0.065),
                _buildQuickRateChip('8.0%', 0.080),
                _buildQuickRateChip('9.5%', 0.095),
                _buildQuickRateChip('12.0%', 0.120),
              ],
            ),
          ],
        );

      // Kịch bản 4: Trả trước hạn
      case SimulationScenarioType.earlyPayoff:
        final maxMonths = selectedLoan.termMonths > 1
            ? selectedLoan.termMonths - 1
            : 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mốc tất toán sớm (kỳ số)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Tháng thứ $earlyPayoffMonths',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: earlyPayoffMonths.clamp(1, maxMonths).toDouble(),
              min: 1,
              max: maxMonths.toDouble(),
              divisions: maxMonths > 1 ? maxMonths - 1 : 1,
              activeColor: AppColors.primary,
              onChanged: (val) => onEarlyPayoffMonthsChanged(val.round()),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Phí phạt trả sớm hợp đồng',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${(earlyPaymentFeeRate * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildQuickFeeChip('0%', 0.0),
                _buildQuickFeeChip('1.0%', 0.01),
                _buildQuickFeeChip('1.5%', 0.015),
                _buildQuickFeeChip('2.0%', 0.02),
              ],
            ),
          ],
        );
    }
  }

  Widget _buildQuickChip(
    String label,
    double amount,
    double currentVal,
    ValueChanged<double> onSelected,
  ) {
    final bool isCurrent = (amount - currentVal).abs() < 1000;
    return InkWell(
      onTap: () => onSelected(amount),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickRateChip(String label, double rate) {
    final bool isCurrent = (rate - newInterestRate).abs() < 0.001;
    return InkWell(
      onTap: () => onNewInterestRateChanged(rate),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFeeChip(String label, double fee) {
    final bool isCurrent = (fee - earlyPaymentFeeRate).abs() < 0.001;
    return InkWell(
      onTap: () => onEarlyPaymentFeeRateChanged(fee),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrent ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
