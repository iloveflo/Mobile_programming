import 'package:flutter/material.dart';

import '../common/app_colors.dart';

/// Giao diện hiển thị trạng thái tài khoản chưa có lịch phân kỳ thanh toán nào (EX-01)
class ScheduleEmptyState extends StatelessWidget {
  final VoidCallback onAddLoan;

  const ScheduleEmptyState({super.key, required this.onAddLoan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.0,
              height: 80.0,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                size: 40.0,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Chưa có lịch phân kỳ trả nợ',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Tài khoản của bạn chưa ghi nhận kế hoạch trả nợ nào.\nHãy tạo hợp đồng vay mới để hệ thống tự động thiết lập lịch thanh toán và cảnh báo nhắc nợ.',
              style: TextStyle(
                fontSize: 13.0,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              onPressed: onAddLoan,
              icon: const Icon(Icons.add_rounded, size: 20.0),
              label: const Text('Thêm khoản vay mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22.0,
                  vertical: 12.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
