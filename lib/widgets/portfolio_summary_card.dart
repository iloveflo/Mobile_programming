import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Thẻ tổng quan danh mục tín dụng & dư nợ (PortfolioSummaryCard)
/// Nền gradient hoàng gia Deep Blue, hiển thị tiến độ trả nợ tổng thể
class PortfolioSummaryCard extends StatelessWidget {
  /// Tổng dư nợ còn lại hiện tại
  final double totalRemainingPrincipal;

  /// Tổng số tiền gốc ban đầu
  final double totalOriginalPrincipal;

  /// Tổng số tiền gốc đã thanh toán
  final double totalPaidAmount;

  /// Tỷ lệ đã thanh toán (0.0 -> 1.0)
  final double paidRatio;

  /// Số lượng khoản vay đang hoạt động
  final int activeLoansCount;

  /// Ước tính thanh toán kỳ tới
  final double? monthlyCommitment;

  const PortfolioSummaryCard({
    super.key,
    required this.totalRemainingPrincipal,
    required this.totalOriginalPrincipal,
    required this.totalPaidAmount,
    required this.paidRatio,
    this.activeLoansCount = 0,
    this.monthlyCommitment,
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
    final int percentInt = (paidRatio * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Nhãn & Badge số khoản vay active
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.pie_chart_outline_rounded,
                    color: Color(0xFFBFDBFE),
                    size: 18.0,
                  ),
                  SizedBox(width: 6.0),
                  Text(
                    'TỔNG DƯ NỢ HIỆN TẠI',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFBFDBFE),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '$activeLoansCount khoản vay active',
                  style: const TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Số tiền dư nợ lớn
          Text(
            _formatCurrency(totalRemainingPrincipal),
            style: const TextStyle(
              fontSize: 30.0,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16.0),

          // Thanh phần trăm tiến độ trả gốc
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tiến độ trả nợ gốc',
                    style: TextStyle(fontSize: 12.0, color: Color(0xFFBFDBFE)),
                  ),
                  Text(
                    '$percentInt% hoàn thành',
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF86EFAC),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              ClipRRect(
                borderRadius: BorderRadius.circular(6.0),
                child: LinearProgressIndicator(
                  value: paidRatio.clamp(0.0, 1.0),
                  minHeight: 8.0,
                  backgroundColor: const Color(0xFF1E3A8A),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF4ADE80),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18.0),
          const Divider(color: Color(0xFF2563EB), height: 1),
          const SizedBox(height: 14.0),

          // Footer 2 cột: Gốc ban đầu & Đã trả
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tổng gốc ban đầu',
                    style: TextStyle(fontSize: 11.0, color: Color(0xFFBFDBFE)),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    _formatCurrency(totalOriginalPrincipal),
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Đã thanh toán',
                    style: TextStyle(fontSize: 11.0, color: Color(0xFFBFDBFE)),
                  ),
                  const SizedBox(height: 3.0),
                  Text(
                    _formatCurrency(totalPaidAmount),
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF86EFAC),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
