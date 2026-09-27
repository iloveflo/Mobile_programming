import 'package:flutter/material.dart';

import '../models/loan_model.dart';
import 'app_colors.dart';

/// Thẻ hiển thị một khoản vay trong danh sách (LoanCard)
/// Tự động nhận diện Khoản vay thông thường và Thẻ tín dụng để hiển thị layout tối ưu
class LoanCard extends StatelessWidget {
  final LoanModel loan;
  final VoidCallback? onTap;

  const LoanCard({super.key, required this.loan, this.onTap});

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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.border, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10.0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh header hiển thị Tổ chức cho vay & Trạng thái
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                color: loan.isCreditCard
                    ? const Color(0xFFFAF5FF)
                    : AppColors.background,
                child: Row(
                  children: [
                    Icon(
                      loan.isCreditCard
                          ? Icons.credit_card_rounded
                          : Icons.account_balance_rounded,
                      size: 16.0,
                      color: loan.isCreditCard
                          ? const Color(0xFF7C3AED)
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        '${loan.lenderName} • ${loan.loanCode}',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: loan.isCreditCard
                              ? const Color(0xFF6B21A8)
                              : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildStatusBadge(),
                  ],
                ),
              ),

              // Nội dung chính
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: loan.isCreditCard
                    ? _buildCreditCardBody()
                    : _buildStandardLoanBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Body dành cho khoản vay thông thường
  Widget _buildStandardLoanBody() {
    final int percentInt = (loan.progressRatio * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                loan.name,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 3.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                loan.loanTypeDisplayName,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        // Hàng số tiền: Dư nợ & Gốc ban đầu
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dư nợ còn lại',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  _formatCurrency(loan.outstandingAmount),
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Gốc ban đầu',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  _formatCurrency(loan.principalAmount),
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        // Thanh tiến độ trả nợ
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LinearProgressIndicator(
                  value: loan.progressRatio,
                  minHeight: 6.0,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    loan.isClosed ? AppColors.textSecondary : AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            Text(
              '$percentInt%',
              style: const TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14.0),

        // Box kỳ thanh toán tới (nếu khoản vay còn active)
        if (loan.isActive)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.event_note_rounded,
                      size: 16.0,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kỳ tới',
                          style: TextStyle(
                            fontSize: 10.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatDate(loan.nextDueDate),
                          style: const TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Ước tính (gốc + lãi)',
                      style: TextStyle(
                        fontSize: 10.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      _formatCurrency(loan.monthlyInstallmentEstimate),
                      style: const TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Body dành cho Thẻ tín dụng
  Widget _buildCreditCardBody() {
    final double usageRatio = loan.principalAmount > 0
        ? (loan.outstandingAmount / loan.principalAmount).clamp(0.0, 1.0)
        : 0.0;
    final int usagePercent = (usageRatio * 100).round();
    final bool isHighUsage = usageRatio > 0.7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loan.name,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12.0),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dư nợ sao kê',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  _formatCurrency(loan.outstandingAmount),
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w800,
                    color: isHighUsage
                        ? AppColors.error
                        : const Color(0xFF6B21A8),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Hạn mức thẻ',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  _formatCurrency(loan.principalAmount),
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        // Thanh tỷ lệ sử dụng hạn mức
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: LinearProgressIndicator(
                  value: usageRatio,
                  minHeight: 6.0,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isHighUsage ? AppColors.error : const Color(0xFF9333EA),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10.0),
            Text(
              '$usagePercent% hạn mức',
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
                color: isHighUsage ? AppColors.error : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14.0),

        // Thanh toán tối thiểu
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: const Color(0xFFFDF4FF),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: const Color(0xFFF5D0FE), width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.payment_rounded,
                    size: 16.0,
                    color: Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 6.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hạn trả',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        _formatDate(loan.nextDueDate),
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Tối thiểu dự kiến (5%)',
                    style: TextStyle(
                      fontSize: 10.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _formatCurrency(loan.outstandingAmount * 0.05),
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color bg;
    Color fg;
    String text;

    if (loan.isClosed) {
      bg = AppColors.border;
      fg = AppColors.textSecondary;
      text = 'ĐÃ TẤT TOÁN';
    } else if (loan.isOverdue) {
      bg = const Color(0xFFFEE2E2);
      fg = AppColors.error;
      text = 'QUÁ HẠN';
    } else {
      bg = const Color(0xFFDCFCE7);
      fg = AppColors.success;
      text = 'ĐANG VAY';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.0,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
