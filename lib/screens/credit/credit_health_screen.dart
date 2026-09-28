import 'package:flutter/material.dart';

import '../../controllers/loan_controller.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình Sức khỏe tín dụng & Điểm CIC (CreditHealthScreen)
class CreditHealthScreen extends StatelessWidget {
  const CreditHealthScreen({super.key});

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
    final loanController = sl<LoanController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Sức khỏe tín dụng & CIC',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: loanController,
        builder: (context, _) {
          final ltv = loanController.portfolioLtvRatio;
          final ltvPercent = (ltv * 100).toStringAsFixed(1);
          final totalRemaining = loanController.totalRemainingPrincipal;
          final totalCollateral = loanController.totalCollateralValue;

          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            children: [
              // 1. Thẻ Điểm tín dụng CIC chính
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Điểm tín dụng cá nhân (CIC)',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: const Text(
                            'Hạng 1 • Rất tốt',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    // Vòng điểm nổi bật
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 140.0,
                            height: 140.0,
                            child: CircularProgressIndicator(
                              value: 745 / 850,
                              strokeWidth: 12.0,
                              backgroundColor: AppColors.primarySoft,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF16A34A),
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                '745',
                                style: TextStyle(
                                  fontSize: 36.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                'Thang điểm: 850',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    const Text(
                      'Khả năng tiếp cận gói vay ưu đãi: 95% • Lãi suất tốt nhất',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // 2. Các chỉ số rủi ro cốt lõi
              const Text(
                'Chỉ số rủi ro tín dụng danh mục',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10.0),

              // Thẻ LTV
              _buildMetricCard(
                title: 'Tỷ lệ Vay / Giá trị tài sản (LTV)',
                value: '$ltvPercent%',
                status: ltv <= 0.7
                    ? 'An toàn (<70%)'
                    : (ltv <= 0.85 ? 'Cảnh báo (70-85%)' : 'Nguy hiểm (>85%)'),
                statusColor: ltv <= 0.7
                    ? AppColors.success
                    : (ltv <= 0.85 ? AppColors.warning : AppColors.error),
                description:
                    'Tổng dư nợ ${_formatCurrency(totalRemaining)} trên tổng định giá tài sản ${_formatCurrency(totalCollateral)}.',
              ),
              const SizedBox(height: 10.0),

              // Thẻ DTI
              _buildMetricCard(
                title: 'Tỷ lệ nợ trên thu nhập (DTI)',
                value: '32.4%',
                status: 'Rất tốt (<40%)',
                statusColor: AppColors.success,
                description:
                    'Chi phí trả nợ hàng tháng chiếm 32.4% tổng thu nhập hàng tháng (25.000.000 đ).',
              ),
              const SizedBox(height: 10.0),

              // Thẻ Lịch sử trả nợ
              _buildMetricCard(
                title: 'Tỷ lệ thanh toán đúng hạn',
                value: '98.5%',
                status: 'Chuẩn mực',
                statusColor: AppColors.success,
                description:
                    'Không phát sinh nợ quá hạn (Nhóm 2 - 5) trong 36 tháng gần nhất.',
              ),
              const SizedBox(height: 16.0),

              // 3. Khối tiện ích tra cứu
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.primary,
                      size: 28.0,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Báo cáo tín dụng điện tử',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 2.0),
                          Text(
                            'Dữ liệu được cập nhật định kỳ từ Trung tâm Thông tin Tín dụng Quốc gia (CIC).',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80.0), // Đệm đáy cho Bottom Nav Bar
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String status,
    required Color statusColor,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12.0,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
