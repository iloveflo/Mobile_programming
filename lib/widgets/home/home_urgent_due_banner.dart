import 'package:flutter/material.dart';

import '../../controllers/loan_controller.dart';
import '../widget.dart';

/// Banner cảnh báo kỳ thanh toán sắp đến hạn khẩn cấp trên trang chủ
class HomeUrgentDueBanner extends StatelessWidget {
  final LoanController loanController;
  final VoidCallback? onPayNow;

  const HomeUrgentDueBanner({
    super.key,
    required this.loanController,
    this.onPayNow,
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
    final activeLoan =
        loanController.loans.where((l) => l.isActive).firstOrNull ??
        (loanController.loans.isNotEmpty ? loanController.loans.first : null);

    if (activeLoan == null) {
      return const SizedBox.shrink();
    }

    final dueDate = activeLoan.nextDueDate;
    final daysLeft = dueDate.difference(DateTime.now()).inDays.clamp(0, 365);
    final installmentStr = _formatCurrency(
      activeLoan.monthlyInstallmentEstimate,
    );
    final dueDayStr =
        '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: const Color(0xFFFDE68A)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 10.0,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFD97706),
                size: 24.0,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${activeLoan.lenderName} • ${activeLoan.name}',
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    'Kỳ tới: $installmentStr • Hạn đóng $dueDayStr (Còn $daysLeft ngày)',
                    style: const TextStyle(
                      fontSize: 11.0,
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            ElevatedButton(
              onPressed:
                  onPayNow ??
                  () {
                    AppSnackBar.showInfo(
                      context,
                      'Chuyển hướng đến cổng thanh toán ngân hàng đối tác...',
                    );
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 8.0,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Thanh toán',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
