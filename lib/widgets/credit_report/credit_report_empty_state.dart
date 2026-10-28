import 'package:flutter/material.dart';

import '../common/app_colors.dart';

/// Giao diện hiển thị trạng thái chưa có báo cáo tín dụng nào (EX-01)
class CreditReportEmptyState extends StatelessWidget {
  final VoidCallback onGenerateFirstReport;

  const CreditReportEmptyState({
    super.key,
    required this.onGenerateFirstReport,
  });

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
                Icons.folder_open_rounded,
                size: 42.0,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20.0),
            const Text(
              'Chưa có báo cáo tín dụng',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Hệ thống tự động lưu trữ ảnh chụp sức khỏe tài chính định kỳ theo tháng để theo dõi xu hướng.\nBạn có thể chủ động lập kỳ báo cáo đầu tiên ngay bây giờ.',
              style: TextStyle(
                fontSize: 13.0,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              onPressed: onGenerateFirstReport,
              icon: const Icon(Icons.add_chart_rounded, size: 18.0),
              label: const Text('Lập báo cáo kỳ hiện tại'),
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
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
