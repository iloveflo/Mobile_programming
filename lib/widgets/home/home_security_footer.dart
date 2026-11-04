import 'package:flutter/material.dart';
import '../widget.dart';

class HomeSecurityFooter extends StatelessWidget {
  const HomeSecurityFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: 18.0,
                color: AppColors.primary,
              ),
              SizedBox(width: 8.0),
              Text(
                'FinCredit Security Standard',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.0),
          Text(
            'Mã hóa đường truyền TLS 1.3 • Lưu trữ phân tán AES-256 • Chuẩn CIC SBV',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.0,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          SizedBox(height: 6.0),
          Text(
            'Phiên bản v1.0.0-beta • Bản quyền © 2026 FinCredit Inc.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
