import 'package:flutter/material.dart';

import '../common/app_colors.dart';

/// Thẻ hiển thị một chỉ số thành phần trong CreditProfile
/// Xử lý đặc thù EX-02: Nếu giá trị null, hiển thị trạng thái "Chưa thể tính" cùng nút bổ sung dữ liệu
class CreditMetricCard extends StatelessWidget {
  final String title;
  final String? value;
  final String status;
  final Color statusColor;
  final String description;
  final IconData icon;
  final bool isMissingData;
  final String? missingHint;
  final VoidCallback? onAddMissingData;
  final VoidCallback? onTap;

  const CreditMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.status,
    required this.statusColor,
    required this.description,
    required this.icon,
    this.isMissingData = false,
    this.missingHint,
    this.onAddMissingData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isMissingData
                ? AppColors.warning.withValues(alpha: 0.5)
                : AppColors.border,
            width: isMissingData ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dòng 1: Icon + Tên chỉ số + Badge trạng thái
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Icon(icon, size: 20.0, color: statusColor),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4.0),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18.0,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Dòng 2: Giá trị chỉ số
            if (isMissingData)
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16.0,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6.0),
                  const Text(
                    'Chưa thể tính (Thiếu dữ liệu đầu vào)',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              )
            else
              Text(
                value ?? '--',
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                  letterSpacing: -0.5,
                ),
              ),
            const SizedBox(height: 6.0),

            // Dòng 3: Mô tả diễn giải
            Text(
              description,
              style: const TextStyle(
                fontSize: 12.0,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),

            // Nút xử lý ngoại lệ EX-02: Bổ sung dữ liệu
            if (isMissingData && onAddMissingData != null) ...[
              const SizedBox(height: 10.0),
              InkWell(
                onTap: onAddMissingData,
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 16.0,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        missingHint ?? 'Bổ sung thông tin ngay',
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
