import 'package:flutter/material.dart';

import '../../controllers/loan_controller.dart';
import '../../models/loan_model.dart';
import '../widget.dart';

/// Modal BottomSheet tính toán & xác nhận tất toán khoản vay trước hạn
class EarlyPayoffModal extends StatefulWidget {
  final LoanModel loan;
  final LoanController loanController;
  final VoidCallback? onPayoffSuccess;

  const EarlyPayoffModal({
    super.key,
    required this.loan,
    required this.loanController,
    this.onPayoffSuccess,
  });

  /// Phương thức hiển thị modal
  static Future<void> show(
    BuildContext context, {
    required LoanModel loan,
    required LoanController loanController,
    VoidCallback? onPayoffSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => EarlyPayoffModal(
        loan: loan,
        loanController: loanController,
        onPayoffSuccess: onPayoffSuccess,
      ),
    );
  }

  @override
  State<EarlyPayoffModal> createState() => _EarlyPayoffModalState();
}

class _EarlyPayoffModalState extends State<EarlyPayoffModal> {
  bool _isSubmitting = false;

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
    final loan = widget.loan;
    final double principal = loan.outstandingAmount;
    final double normalizedRate = loan.interestRatePercent / 100;
    final double accruedInterest = principal * (normalizedRate / 12);
    final double penaltyRate = loan.earlyPaymentFeeRate > 0
        ? loan.earlyPaymentFeeRate
        : 0.015;
    final double penaltyAmount = principal * penaltyRate;
    final double totalPayoff = principal + accruedInterest + penaltyAmount;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.savings_outlined,
                color: AppColors.primary,
                size: 24.0,
              ),
              const SizedBox(width: 8.0),
              const Text(
                'Tất toán khoản vay trước hạn',
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
          const Text(
            'Quy tắc tất toán: Dư nợ gốc + Lãi phát sinh kỳ này + Phí phạt trả trước hạn.',
            style: TextStyle(fontSize: 13.0, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16.0),
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dư nợ gốc còn lại:',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _formatCurrency(principal),
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lãi phát sinh kỳ này:',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _formatCurrency(accruedInterest),
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Phí phạt trả sớm (${(penaltyRate * 100).toStringAsFixed(1)}%):',
                      style: const TextStyle(
                        fontSize: 13.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _formatCurrency(penaltyAmount),
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20.0, color: AppColors.border),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng tiền cần thanh toán:',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      _formatCurrency(totalPayoff),
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          AppPrimaryButton(
            label: _isSubmitting
                ? 'Đang thực hiện tất toán...'
                : 'Xác nhận tất toán trước hạn',
            isLoading: _isSubmitting,
            onPressed: _isSubmitting
                ? null
                : () async {
                    setState(() => _isSubmitting = true);
                    final success = await widget.loanController.settleLoanEarly(
                      loan.id.toString(),
                    );
                    if (!context.mounted) return;
                    setState(() => _isSubmitting = false);
                    Navigator.pop(context);
                    if (success) {
                      widget.onPayoffSuccess?.call();
                      AppSnackBar.showSuccess(
                        context,
                        'Đã tất toán khoản vay trước hạn thành công! Trạng thái hợp đồng đã đóng.',
                      );
                    } else {
                      AppSnackBar.showError(
                        context,
                        widget.loanController.errorMessage ??
                            'Tất toán khoản vay thất bại.',
                      );
                    }
                  },
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }
}
