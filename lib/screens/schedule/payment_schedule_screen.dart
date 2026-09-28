import 'package:flutter/material.dart';

import '../../controllers/loan_controller.dart';
import '../../models/loan_model.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình Lịch trả nợ & Kế hoạch thanh toán định kỳ (PaymentScheduleScreen)
class PaymentScheduleScreen extends StatefulWidget {
  const PaymentScheduleScreen({super.key});

  @override
  State<PaymentScheduleScreen> createState() => _PaymentScheduleScreenState();
}

class _PaymentScheduleScreenState extends State<PaymentScheduleScreen> {
  final LoanController _loanController = sl<LoanController>();
  String _selectedFilter = 'ALL'; // ALL, PENDING, PAID

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

  void _showPaymentConfirmModal(BuildContext context, LoanModel loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (bottomSheetCtx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 24.0,
                  ),
                  const SizedBox(width: 8.0),
                  const Text(
                    'Xác nhận thanh toán kỳ',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(bottomSheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Text(
                'Khoản vay: ${loan.loanName} (${loan.lenderName})',
                style: const TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Số tiền thanh toán dự kiến: ${_formatCurrency(loan.estimatedMonthlyPayment)}',
                style: const TextStyle(
                  fontSize: 14.0,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20.0),
              AppPrimaryButton(
                label: 'Ghi nhận đã thanh toán',
                onPressed: () {
                  Navigator.pop(bottomSheetCtx);
                  AppSnackBar.showSuccess(
                    context,
                    'Đã ghi nhận thanh toán cho hợp đồng ${loan.loanCode}!',
                  );
                },
              ),
              const SizedBox(height: 10.0),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Lịch trả nợ định kỳ',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _loanController,
        builder: (context, _) {
          final loans = _loanController.loans.where((l) => l.isActive).toList();
          final totalMonthly = loans.fold(
            0.0,
            (sum, l) => sum + l.estimatedMonthlyPayment,
          );

          return RefreshIndicator(
            onRefresh: () => _loanController.fetchLoans(),
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              children: [
                // 1. Thẻ tổng quan kỳ thanh toán tháng này
                Container(
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 12.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tổng phải trả trong tháng',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.white70,
                            size: 18.0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        _formatCurrency(totalMonthly),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          '${loans.length} khoản vay đang cần thanh toán kỳ này',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),

                // 2. Bộ lọc trạng thái
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tất cả', 'ALL'),
                      _buildFilterChip('Đang chờ trả', 'PENDING'),
                      _buildFilterChip('Đã hoàn thành', 'PAID'),
                    ],
                  ),
                ),
                const SizedBox(height: 14.0),

                // 3. Danh sách các kỳ thanh toán
                if (loans.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.event_available_rounded,
                          size: 48.0,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 10.0),
                        const Text(
                          'Không có lịch trả nợ nào',
                          style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text(
                          'Các khoản vay đang hoạt động sẽ hiển thị lịch tại đây.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...List.generate(loans.length, (idx) {
                    final loan = loans[idx];
                    final monthlyPrincipal =
                        loan.principalAmount / loan.tenorMonths;
                    final monthlyInterest =
                        loan.estimatedMonthlyPayment - monthlyPrincipal;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8.0),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  color: AppColors.primary,
                                  size: 20.0,
                                ),
                              ),
                              const SizedBox(width: 10.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loan.loanName,
                                      style: const TextStyle(
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${loan.lenderName} • ${loan.loanCode}',
                                      style: const TextStyle(
                                        fontSize: 12.0,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: const Text(
                                  'Chờ thanh toán',
                                  style: TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Gốc + Lãi kỳ này',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(
                                      loan.estimatedMonthlyPayment,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Chi tiết phân bổ',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'Gốc: ${_formatCurrency(monthlyPrincipal)} | Lãi: ${_formatCurrency(monthlyInterest)}',
                                    style: const TextStyle(
                                      fontSize: 11.0,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _showPaymentConfirmModal(context, loan),
                              icon: const Icon(
                                Icons.payment_rounded,
                                size: 16.0,
                              ),
                              label: const Text(
                                'Xác nhận thanh toán',
                                style: TextStyle(fontSize: 13.0),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primaryLight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 80.0), // Đệm đáy cho Bottom Nav Bar
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySoft,
        labelStyle: TextStyle(
          fontSize: 12.0,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(
            color: isSelected ? AppColors.primaryLight : AppColors.border,
          ),
        ),
      ),
    );
  }
}
