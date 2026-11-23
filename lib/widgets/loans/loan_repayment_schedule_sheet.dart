import 'package:flutter/material.dart';

import '../../controllers/payment_schedule_controller.dart';
import '../../models/loan_model.dart';
import '../../models/payment_schedule_model.dart';
import '../../repositories/interfaces/payment_schedule_repository.dart';
import '../../service_locator.dart';
import '../widget.dart';

/// Modal BottomSheet hiển thị toàn bộ lịch trình trả nợ định kỳ của khoản vay
class LoanRepaymentScheduleSheet extends StatefulWidget {
  final LoanModel loan;
  final List<PaymentScheduleModel>? initialSchedules;

  const LoanRepaymentScheduleSheet({
    super.key,
    required this.loan,
    this.initialSchedules,
  });

  /// Phương thức hiển thị modal
  static Future<void> show(
    BuildContext context, {
    required LoanModel loan,
    List<PaymentScheduleModel>? schedules,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) =>
          LoanRepaymentScheduleSheet(loan: loan, initialSchedules: schedules),
    );
  }

  @override
  State<LoanRepaymentScheduleSheet> createState() =>
      _LoanRepaymentScheduleSheetState();
}

class _LoanRepaymentScheduleSheetState
    extends State<LoanRepaymentScheduleSheet> {
  List<PaymentScheduleModel> _schedules = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initSchedules();
  }

  void _initSchedules() {
    if (widget.initialSchedules != null) {
      _schedules = List.of(widget.initialSchedules!)
        ..sort((a, b) => a.installmentNumber.compareTo(b.installmentNumber));
      return;
    }

    if (sl.isRegistered<PaymentScheduleController>()) {
      final cached =
          sl<PaymentScheduleController>().schedules
              .where((s) => s.loanId == widget.loan.id)
              .toList()
            ..sort(
              (a, b) => a.installmentNumber.compareTo(b.installmentNumber),
            );
      if (cached.isNotEmpty) {
        _schedules = cached;
      }
    }

    if (sl.isRegistered<PaymentScheduleRepository>()) {
      _fetchLatestSchedules();
    }
  }

  Future<void> _fetchLatestSchedules() async {
    if (_schedules.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final fetched = await sl<PaymentScheduleRepository>().getPaymentSchedules(
        loanId: widget.loan.id,
      );
      fetched.sort(
        (a, b) => a.installmentNumber.compareTo(b.installmentNumber),
      );
      if (mounted && fetched.isNotEmpty) {
        setState(() {
          _schedules = fetched;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {
      // Fallback sang dữ liệu đã cache hoặc ước tính nếu lỗi mạng
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
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
    final loan = widget.loan;
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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : _schedules.isNotEmpty
                    ? ListView.separated(
                        controller: scrollController,
                        itemCount: _schedules.length,
                        separatorBuilder: (_, _) =>
                            const Divider(color: AppColors.border, height: 1),
                        itemBuilder: (ctx, i) {
                          final item = _schedules[i];
                          final statusUpper = item.status.toUpperCase();
                          final isPaid = statusUpper == 'PAID';
                          final isOverdue = statusUpper == 'OVERDUE';

                          final Color badgeColor = isPaid
                              ? AppColors.success
                              : (isOverdue
                                    ? AppColors.error
                                    : AppColors.primary);
                          final Color badgeBg = isPaid
                              ? AppColors.success.withValues(alpha: 0.15)
                              : (isOverdue
                                    ? AppColors.error.withValues(alpha: 0.12)
                                    : AppColors.primarySoft);
                          final String statusLabel = isPaid
                              ? 'Đã thanh toán'
                              : (isOverdue ? 'Quá hạn' : 'Chờ thanh toán');
                          final String feeSuffix = item.feeAmount > 0
                              ? ' • Phí: ${_formatCurrency(item.feeAmount)}'
                              : '';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14.0,
                                  backgroundColor: badgeBg,
                                  child: Text(
                                    '${item.installmentNumber}',
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.bold,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Kỳ thứ ${item.installmentNumber}',
                                            style: const TextStyle(
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 6.0),
                                          Text(
                                            '• Hạn: ${_formatDate(item.dueDate)}',
                                            style: const TextStyle(
                                              fontSize: 11.0,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2.0),
                                      Text(
                                        'Gốc: ${_formatCurrency(item.principalAmount)} • Lãi: ${_formatCurrency(item.interestAmount)}$feeSuffix',
                                        style: const TextStyle(
                                          fontSize: 11.0,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatCurrency(item.totalAmount),
                                      style: TextStyle(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.bold,
                                        color: isOverdue
                                            ? AppColors.error
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: badgeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: loan.tenorMonths.clamp(1, 60),
                        separatorBuilder: (_, _) =>
                            const Divider(color: AppColors.border, height: 1),
                        itemBuilder: (ctx, i) {
                          final month = i + 1;
                          final interest =
                              (loan.principalAmount - (monthlyPrincipal * i))
                                  .clamp(0.0, loan.principalAmount) *
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
                                      ? AppColors.success.withValues(
                                          alpha: 0.15,
                                        )
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
