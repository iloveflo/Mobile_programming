import 'package:flutter/material.dart';

import '../../controllers/loan_controller.dart';
import '../../models/user_model.dart';

/// Thẻ tổng quan dư nợ tài chính Hero Card ở đầu trang chủ
class HomeHeroCard extends StatelessWidget {
  final LoanController loanController;
  final UserModel? user;
  final ValueNotifier<bool> isBalanceHidden;
  final VoidCallback onPlanDebt;
  final VoidCallback onViewCashflow;

  const HomeHeroCard({
    super.key,
    required this.loanController,
    required this.user,
    required this.isBalanceHidden,
    required this.onPlanDebt,
    required this.onViewCashflow,
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
    final double outstanding = loanController.totalRemainingPrincipal;
    final double paidRatio = loanController.paidRatio;
    final int percentInt = (paidRatio * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D47A1).withValues(alpha: 0.28),
            blurRadius: 16.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề & Nút Ẩn/Hiện con mắt (Tối ưu với ValueNotifier)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TỔNG DƯ NỢ HIỆN TẠI',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFFBFDBFE),
                ),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: isBalanceHidden,
                builder: (context, isHidden, _) {
                  return InkWell(
                    onTap: () {
                      isBalanceHidden.value = !isHidden;
                    },
                    borderRadius: BorderRadius.circular(20.0),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isHidden
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18.0,
                            color: const Color(0xFFBFDBFE),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            isHidden ? 'Hiện' : 'Ẩn',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFBFDBFE),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 6.0),

          // Số dư hiển thị
          ValueListenableBuilder<bool>(
            valueListenable: isBalanceHidden,
            builder: (context, isHidden, _) {
              return Text(
                isHidden ? '•••••••• đ' : _formatCurrency(outstanding),
                style: const TextStyle(
                  fontSize: 27.0,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              );
            },
          ),
          const SizedBox(height: 14.0),

          // Thanh tiến độ trả nợ tổng thể
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ danh mục: Đã trả $percentInt%',
                style: const TextStyle(
                  fontSize: 12.0,
                  color: Color(0xFFE0E7FF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              // Chip Điểm CIC mô phỏng
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 3.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 13.0,
                      color: user?.cicScore != null
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      user?.cicScore != null
                          ? '${user!.cicScore} • Rất tốt'
                          : 'Chưa có CIC',
                      style: const TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.0),
            child: LinearProgressIndicator(
              value: paidRatio,
              minHeight: 6.0,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF60A5FA),
              ),
            ),
          ),

          const SizedBox(height: 18.0),
          const Divider(height: 1.0, color: Colors.white24),
          const SizedBox(height: 14.0),

          // 2 nút CTA nhanh màu trắng trong thẻ
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPlanDebt,
                  icon: const Icon(
                    Icons.calendar_month_outlined,
                    size: 16.0,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Lập kế hoạch trả',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onViewCashflow,
                  icon: const Icon(
                    Icons.analytics_outlined,
                    size: 16.0,
                    color: Color(0xFF0D47A1),
                  ),
                  label: const Text(
                    'Thống kê dòng tiền',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0D47A1),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    backgroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
