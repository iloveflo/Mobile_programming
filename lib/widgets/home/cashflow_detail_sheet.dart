import 'dart:math';
import 'package:flutter/material.dart';

import '../../controllers/loan_controller.dart';
import '../../models/user_model.dart';
import '../../routes/app_router.dart';
import '../../screens/main_shell_screen.dart';
import '../widget.dart';

/// Modal BottomSheet Thống kê & Dự phóng Dòng tiền (Cashflow Breakdown & Projections)
class CashflowDetailSheet extends StatelessWidget {
  final UserModel? user;
  final LoanController loanController;

  const CashflowDetailSheet({
    super.key,
    required this.user,
    required this.loanController,
  });

  /// Phương thức hiển thị modal
  static Future<void> show(
    BuildContext context, {
    required UserModel? user,
    required LoanController loanController,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) =>
          CashflowDetailSheet(user: user, loanController: loanController),
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

  Widget _buildCashflowRow(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16.0, color: color),
        const SizedBox(width: 6.0),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double income = user?.monthlyIncome ?? 0.0;
    final double commitment = loanController.totalMonthlyCommitment;
    final double netCashflow = income - commitment;
    final double absorptionRate = income > 0
        ? (commitment / income) * 100
        : 0.0;
    final bool isSurplus = netCashflow >= 0;
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
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Color(0xFF0D47A1),
                    size: 22.0,
                  ),
                ),
                const SizedBox(width: 10.0),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thống kê & Dự phóng Dòng tiền',
                        style: TextStyle(
                          fontSize: 17.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.0),
                      Text(
                        'Phân tích khả năng hấp thụ nợ & thanh khoản hàng tháng',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // 3 Thẻ KPI Dòng tiền
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSurplus
                      ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)]
                      : [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: isSurplus
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFCA5A5),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSurplus ? 'Dòng tiền thặng dư' : 'Dòng tiền thâm hụt',
                        style: TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: isSurplus
                              ? const Color(0xFF166534)
                              : const Color(0xFF991B1B),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 3.0,
                        ),
                        decoration: BoxDecoration(
                          color: isSurplus
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          isSurplus ? 'DƯƠNG (+)' : 'ÂM (-)',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Row(
                    children: [
                      Text(
                        _formatCurrency(netCashflow.abs()),
                        style: TextStyle(
                          fontSize: 24.0,
                          fontWeight: FontWeight.w800,
                          color: isSurplus
                              ? const Color(0xFF166534)
                              : const Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        isSurplus ? '/ tháng tự do' : '/ tháng thiếu hụt',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: isSurplus
                              ? const Color(0xFF166534)
                              : const Color(0xFF991B1B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),

            // Bảng cân đối thu chi hàng tháng
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildCashflowRow(
                    'Dòng tiền vào (Thu nhập xác nhận):',
                    income > 0
                        ? '+ ${_formatCurrency(income)}'
                        : '0 đ (Chưa cập nhật)',
                    const Color(0xFF16A34A),
                    Icons.arrow_downward_rounded,
                  ),
                  const Divider(height: 14.0),
                  _buildCashflowRow(
                    'Dòng tiền ra (Tổng nghĩa vụ trả nợ):',
                    '- ${_formatCurrency(commitment)}',
                    const Color(0xFFDC2626),
                    Icons.arrow_upward_rounded,
                  ),
                  const Divider(height: 14.0),
                  _buildCashflowRow(
                    'Tỷ lệ hấp thụ dòng tiền (DTI):',
                    '${absorptionRate.toStringAsFixed(1)}%',
                    absorptionRate > 50
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF0891B2),
                    Icons.pie_chart_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18.0),

            // Biểu đồ dự phóng dòng tiền 6 tháng
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Dự phóng dòng tiền chi trả (6 tháng)',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
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
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: totalProjectedMillion <= 0
                  ? Container(
                      height: 110.0,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.event_available_outlined,
                            size: 34.0,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 6.0),
                          Text(
                            'Không có nghĩa vụ trả nợ trong 6 tháng tới',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : SizedBox(
                      height: 130.0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(months.length, (idx) {
                          final heightFactor = (values[idx] / maxVal).clamp(
                            0.1,
                            1.0,
                          );
                          final isCurrent = idx == 0;

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${values[idx]}tr',
                                style: TextStyle(
                                  fontSize: 10.0,
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
                                height: 80.0 * heightFactor,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? AppColors.primary
                                      : const Color(0xFF93C5FD),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6.0),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                months[idx],
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.w500,
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
            ),
            const SizedBox(height: 16.0),

            // Đánh giá chuyên gia FinCredit
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isSurplus
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: isSurplus
                      ? const Color(0xFF86EFAC)
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isSurplus
                        ? Icons.check_circle_outline_rounded
                        : Icons.lightbulb_outline_rounded,
                    size: 20.0,
                    color: isSurplus
                        ? const Color(0xFF166534)
                        : const Color(0xFF92400E),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      isSurplus
                          ? (income <= 0 && commitment <= 0
                                ? 'Lời khuyên FinCredit: Bạn chưa phát sinh nghĩa vụ nợ nào. Hãy cập nhật thu nhập hàng tháng để FinCredit tư vấn các phương án tích lũy và đầu tư tối ưu.'
                                : 'Lời khuyên FinCredit: Bạn đang duy trì dòng tiền thặng dư ${_formatCurrency(netCashflow)}/tháng. Hãy trích lập tối thiểu 20% dòng tiền thặng dư vào quỹ tích lũy dự phòng trước khi đầu tư.')
                          : 'Cảnh báo FinCredit: Dòng tiền của bạn đang bị thâm hụt do nghĩa vụ nợ lớn hơn thu nhập hàng tháng. Hãy cân nhắc kéo dài kỳ hạn vay hoặc trả dứt nợ thẻ tín dụng sớm nhất để tái lập thế cân bằng.',
                      style: TextStyle(
                        fontSize: 12.0,
                        height: 1.4,
                        color: isSurplus
                            ? const Color(0xFF166534)
                            : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // 2 Nút CTA
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      MainShellScreen.switchTab(context, 2);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      'Xem lịch trả nợ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRouter.debtStrategy);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text(
                      'Tối ưu dòng tiền',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
          ],
        ),
      ),
    );
  }
}
