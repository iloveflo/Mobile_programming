import 'package:flutter/material.dart';

import '../../controllers/loan_controller.dart';
import '../../models/loan_model.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình L02-02: Chi tiết khoản vay & Quản lý hợp đồng (LoanDetailScreen)
class LoanDetailScreen extends StatefulWidget {
  final String? loanId;

  const LoanDetailScreen({super.key, this.loanId});

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  final LoanController _loanController = sl<LoanController>();
  late String _activeLoanId;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _activeLoanId = widget.loanId ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (_activeLoanId.isEmpty) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        _activeLoanId = (args?['loanId'] as String?) ?? '';
        final passedLoan = args?['loan'] as LoanModel?;
        if (passedLoan != null) {
          _loanController.selectLoan(passedLoan);
        }
      }
      if (_activeLoanId.isNotEmpty) {
        _loanController.getDetail(_activeLoanId);
      }
    }
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

  void _handlePaymentConfirmation(LoanModel loan) {
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
                    Icons.payment_rounded,
                    color: AppColors.primary,
                    size: 24.0,
                  ),
                  const SizedBox(width: 8.0),
                  const Text(
                    'Ghi nhận thanh toán kỳ này',
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
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Số tiền thanh toán:',
                      style: TextStyle(
                        fontSize: 14.0,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _formatCurrency(loan.monthlyInstallmentEstimate),
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              AppPrimaryButton(
                label: 'Xác nhận đã thanh toán',
                onPressed: () async {
                  Navigator.pop(bottomSheetCtx);
                  final newOutstanding =
                      (loan.outstandingAmount - loan.monthlyInstallmentEstimate)
                          .clamp(0.0, loan.principalAmount);
                  final success = await _loanController
                      .updateLoan(loan.id.toString(), {
                        'outstanding_amount': newOutstanding,
                        if (newOutstanding == 0) 'status': 'CLOSED',
                      });
                  if (mounted && success) {
                    AppSnackBar.showSuccess(
                      context,
                      'Đã ghi nhận thanh toán thành công!',
                    );
                  }
                },
              ),
              const SizedBox(height: 10.0),
            ],
          ),
        );
      },
    );
  }

  void _showRepaymentScheduleModal(LoanModel loan) {
    final double monthlyPrincipal = loan.tenorMonths > 0
        ? loan.principalAmount / loan.tenorMonths
        : 0;
    final double monthlyRate = (loan.interestRatePercent / 100) / 12;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (bottomSheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
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
                        onPressed: () => Navigator.pop(bottomSheetCtx),
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
                      itemBuilder: (context, i) {
                        final month = i + 1;
                        final interest =
                            (loan.principalAmount - (monthlyPrincipal * i))
                                .clamp(0.0, loan.principalAmount) *
                            monthlyRate;
                        final total = monthlyPrincipal + interest;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14.0,
                                backgroundColor:
                                    month <=
                                        (loan.progressRatio * loan.tenorMonths)
                                            .round()
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : AppColors.primarySoft,
                                child: Text(
                                  '$month',
                                  style: TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        month <=
                                            (loan.progressRatio *
                                                    loan.tenorMonths)
                                                .round()
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
      },
    );
  }

  void _showEarlyPayoffModal(LoanModel loan) {
    final double principal = loan.outstandingAmount;
    final double normalizedRate = loan.interestRatePercent / 100;
    final double accruedInterest = principal * (normalizedRate / 12);
    final double penaltyRate = loan.earlyPaymentFeeRate > 0
        ? loan.earlyPaymentFeeRate
        : 0.015;
    final double penaltyAmount = principal * penaltyRate;
    final double totalPayoff = principal + accruedInterest + penaltyAmount;

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
                    onPressed: () => Navigator.pop(bottomSheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Quy tắc tất toán: Dư nợ gốc + Lãi phát sinh kỳ này + Phí phạt trả trước hạn.',
                style: TextStyle(
                  fontSize: 13.0,
                  color: AppColors.textSecondary,
                ),
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
                label: 'Xác nhận tất toán trước hạn',
                onPressed: () async {
                  Navigator.pop(bottomSheetCtx);
                  final success = await _loanController.settleLoanEarly(
                    loan.id.toString(),
                  );
                  if (mounted && success) {
                    AppSnackBar.showSuccess(
                      context,
                      'Đã tất toán khoản vay trước hạn thành công! Trạng thái hợp đồng đã đóng.',
                    );
                  }
                },
              ),
              const SizedBox(height: 10.0),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(LoanModel loan) {
    if (!loan.canHardDelete) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.error,
                size: 24.0,
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Không thể xóa khoản vay',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0),
                ),
              ),
            ],
          ),
          content: Text(
            'Khoản vay "${loan.loanName}" đã phát sinh lịch sử thanh toán (${_formatCurrency(loan.paidAmount)}).\n\nTheo quy định quản lý tài chính và ghi nhận tín dụng, bạn không được phép xóa các khoản vay đã có phát sinh giao dịch.',
            style: const TextStyle(
              fontSize: 14.0,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.delete_forever_rounded,
              color: AppColors.error,
              size: 24.0,
            ),
            SizedBox(width: 8.0),
            Expanded(
              child: Text(
                'Xác nhận xóa khoản vay',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17.0),
              ),
            ),
          ],
        ),
        content: Text(
          'Khoản vay "${loan.loanName}" chưa phát sinh bất kỳ khoản thanh toán nào. Bạn có chắc chắn muốn xóa hoàn toàn khỏi hệ thống không? Thao tác này không thể hoàn tác.',
          style: const TextStyle(
            fontSize: 14.0,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await _loanController.removeLoan(
                loan.id.toString(),
              );
              if (mounted && success) {
                AppSnackBar.showSuccess(
                  context,
                  'Đã xóa vĩnh viễn khoản vay thành công!',
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Xác nhận xóa'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.0,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20.0,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Chi tiết hợp đồng vay',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: _loanController,
            builder: (context, _) {
              final loan = _loanController.selectedLoan;
              if (loan == null) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textPrimary,
                ),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.pushNamed(
                      context,
                      AppRouter.loanForm,
                      arguments: {'loan': loan},
                    );
                  } else if (value == 'close') {
                    _showEarlyPayoffModal(loan);
                  } else if (value == 'delete') {
                    _confirmDelete(loan);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18.0,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8.0),
                        Text('Chỉnh sửa thông tin'),
                      ],
                    ),
                  ),
                  if (loan.isActive)
                    const PopupMenuItem(
                      value: 'close',
                      child: Row(
                        children: [
                          Icon(
                            Icons.savings_outlined,
                            size: 18.0,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 8.0),
                          Text('Tất toán trước hạn'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 18.0,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 8.0),
                        Text(
                          'Xóa khoản vay',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _loanController,
        builder: (context, _) {
          final loan = _loanController.selectedLoan;

          if (_loanController.isLoading && loan == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (loan == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off_rounded,
                    size: 48.0,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12.0),
                  const Text(
                    'Không tìm thấy thông tin khoản vay',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  ElevatedButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text('Quay lại danh sách'),
                  ),
                ],
              ),
            );
          }

          final collaterals = _loanController.collaterals;
          final totalCollateralVal = collaterals.fold(
            0.0,
            (sum, c) => sum + c.value,
          );
          final double ltvRatio = totalCollateralVal > 0
              ? (loan.outstandingAmount / totalCollateralVal)
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Thẻ Header khoản vay
                Container(
                  padding: const EdgeInsets.all(18.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              loan.lenderName,
                              style: const TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: loan.statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              loan.statusDisplay,
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                color: loan.statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        loan.loanName,
                        style: const TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'Mã hợp đồng: ${loan.loanCode}',
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 14.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Dư nợ hiện tại',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 3.0),
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
                                'Số tiền gốc ban đầu',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 3.0),
                              Text(
                                _formatCurrency(loan.principalAmount),
                                style: const TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),

                // 2. Thẻ nhắc kỳ thanh toán kế tiếp (nếu còn dư nợ)
                if (loan.isActive)
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.event_available_rounded,
                                  color: AppColors.primary,
                                  size: 20.0,
                                ),
                                SizedBox(width: 8.0),
                                Text(
                                  'Kỳ thanh toán kế tiếp',
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              loan.nextDueDateFormatted,
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Số tiền cần đóng',
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 3.0),
                                Text(
                                  _formatCurrency(
                                    loan.monthlyInstallmentEstimate,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () => _handlePaymentConfirmation(loan),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14.0,
                                  vertical: 10.0,
                                ),
                              ),
                              child: const Text(
                                'Ghi nhận trả',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16.0),

                // 3. Thông số kỹ thuật hợp đồng
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông số hợp đồng',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      _buildDetailRow(
                        'Loại khoản vay',
                        loan.loanTypeDisplayName,
                      ),
                      _buildDetailRow(
                        'Lãi suất áp dụng',
                        loan.interestRateFormatted,
                        valueColor: AppColors.primary,
                      ),
                      _buildDetailRow(
                        'Kỳ hạn vay',
                        '${loan.tenorMonths} tháng',
                      ),
                      _buildDetailRow(
                        'Hình thức tính lãi',
                        loan.interestMethod.toUpperCase().contains('REDUCING')
                            ? 'Dư nợ giảm dần'
                            : 'Dư nợ ban đầu (Phẳng)',
                      ),
                      _buildDetailRow(
                        'Ngày bắt đầu giải ngân',
                        loan.startDateFormatted,
                      ),
                      _buildDetailRow(
                        'Ngày kết thúc dự kiến',
                        loan.endDateFormatted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),

                // 4. Nếu có tài sản bảo đảm gắn kèm
                if (collaterals.isNotEmpty) ...[
                  LtvIndicatorBar(
                    ltvRatio: ltvRatio,
                    outstandingAmount: loan.outstandingAmount,
                    collateralValue: totalCollateralVal,
                  ),
                  const SizedBox(height: 16.0),
                ],

                // 5. Hubs tác vụ nhanh (Quick Action Grid)
                const Text(
                  'TIỆN ÍCH HỢP ĐỒNG',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showRepaymentScheduleModal(loan),
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14.0,
                            horizontal: 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.calendar_month_outlined,
                                color: AppColors.primary,
                                size: 24.0,
                              ),
                              SizedBox(height: 6.0),
                              Text(
                                'Lịch trả nợ',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRouter.loanCollateralOcr,
                          );
                        },
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14.0,
                            horizontal: 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: Color(0xFF0284C7),
                                size: 24.0,
                              ),
                              SizedBox(height: 6.0),
                              Text(
                                'Tài sản & OCR',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showEarlyPayoffModal(loan),
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14.0,
                            horizontal: 10.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.savings_outlined,
                                color: AppColors.success,
                                size: 24.0,
                              ),
                              SizedBox(height: 6.0),
                              Text(
                                'Tất toán sớm',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40.0),
              ],
            ),
          );
        },
      ),
    );
  }
}
