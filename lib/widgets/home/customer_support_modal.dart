import 'package:flutter/material.dart';

import '../widget.dart';

/// Modal BottomSheet hỗ trợ khách hàng 24/7 (Hotline, Email tư vấn)
class CustomerSupportModal extends StatelessWidget {
  const CustomerSupportModal({super.key});

  /// Phương thức hiển thị modal
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => const CustomerSupportModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.support_agent_rounded,
                color: AppColors.primary,
                size: 26.0,
              ),
              const SizedBox(width: 10.0),
              const Text(
                'Hỗ trợ khách hàng 24/7',
                style: TextStyle(
                  fontSize: 17.0,
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
          const SizedBox(height: 14.0),
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.phone_in_talk_rounded,
                      color: AppColors.primary,
                      size: 20.0,
                    ),
                    SizedBox(width: 10.0),
                    Text(
                      'Tổng đài Hotline: ',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '1900 6868 (Miễn phí)',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.0),
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                      size: 20.0,
                    ),
                    SizedBox(width: 10.0),
                    Text(
                      'Email tư vấn: ',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'support@fincredit.vn',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14.0),
          const Text(
            'Đội ngũ chuyên viên FinCredit luôn túc trực hỗ trợ giải đáp phương thức tính lãi, tra cứu thông tin hợp đồng và hướng dẫn thanh toán.',
            style: TextStyle(
              fontSize: 12.0,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
