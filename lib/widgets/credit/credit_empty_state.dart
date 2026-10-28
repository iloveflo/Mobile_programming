import 'package:flutter/material.dart';

import '../../routes/app_router.dart';
import '../common/app_colors.dart';

/// Widget xử lý ngoại lệ EX-01: Chưa có dữ liệu khoản vay trên hệ thống
class CreditEmptyState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const CreditEmptyState({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              size: 48.0,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18.0),
          const Text(
            'Chưa có dữ liệu khoản vay',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Bạn cần có tối thiểu một khoản vay đang hoạt động hoặc lịch sử thanh toán để hệ thống tiến hành đánh giá sức khỏe tín dụng.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20.0),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.loanForm);
            },
            icon: const Icon(Icons.add_rounded, size: 20.0),
            label: const Text('Thêm khoản vay đầu tiên'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          if (onRefresh != null) ...[
            const SizedBox(height: 10.0),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18.0),
              label: const Text('Kiểm tra lại'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
