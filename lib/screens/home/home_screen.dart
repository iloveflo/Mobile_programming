import 'dart:math';
import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/loan_controller.dart';
import '../../controllers/payment_schedule_controller.dart';
import '../../models/loan_model.dart';
import '../../models/user_model.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';
import '../main_shell_screen.dart';

/// Màn hình Trang chủ FinCredit (HomeScreen) - FinTech High Performance Dashboard
/// Thiết kế giao diện đa tầng với CustomScrollView + Slivers mượt mà,
/// Hero Credit Health Card, Quick Action Grid 8 phím tắt, Cảnh báo khẩn cấp,
/// Horizontal Active Loans Slider, Thước đo DTI, Biểu đồ dự phóng dòng tiền 6 tháng,
/// Cẩm nang tài chính và Footer an ninh bảo mật.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = sl<AuthController>();
  final LoanController _loanController = sl<LoanController>();
  final PaymentScheduleController _scheduleController =
      sl<PaymentScheduleController>();

  /// Sử dụng ValueNotifier cho trạng thái ẩn/hiện số dư để tránh setState toàn bộ màn hình
  final ValueNotifier<bool> _isBalanceHidden = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_loanController.loans.isEmpty && !_loanController.isLoading) {
        _loanController.fetchLoans();
      }
      if (_authController.activeSessions.isEmpty) {
        _authController.loadSessions();
      }
      final userId = _authController.currentUser?.userId;
      _scheduleController.loadNotifications(userId: userId);
      _scheduleController.loadSchedules(userId: userId);
    });
  }

  @override
  void dispose() {
    _isBalanceHidden.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Chào buổi sáng';
    } else if (hour < 18) {
      return 'Chào buổi chiều';
    } else {
      return 'Chào buổi tối';
    }
  }

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

  void _showNotificationSheet(BuildContext context) {
    NotificationListSheet.show(
      context,
      notifications: _scheduleController.notifications,
      onSelectSchedule: (scheduleId) async {
        final success = await _scheduleController.selectSchedule(
          scheduleId,
          userId: _authController.currentUser?.userId,
        );
        if (!mounted) return;

        if (success && _scheduleController.selectedSchedule != null) {
          final schedule = _scheduleController.selectedSchedule!;
          final loan = _loanController.loans.cast<LoanModel?>().firstWhere(
            (l) => l?.id == schedule.loanId,
            orElse: () => null,
          );

          ScheduleDetailSheet.show(
            this.context,
            schedule: schedule,
            loanName: loan?.name,
            onPay: () async {
              Navigator.pop(this.context);
              await _scheduleController.markAsPaid(
                schedule.id,
                userId: _authController.currentUser?.userId,
              );
              if (mounted) {
                AppSnackBar.showSuccess(
                  this.context,
                  'Đã ghi nhận thanh toán thành công!',
                );
              }
            },
          );
        } else if (_scheduleController.errorMessage != null && mounted) {
          AppSnackBar.showError(
            this.context,
            _scheduleController.errorMessage!,
          );
        }
      },
    );
  }

  void _showSupportModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => Padding(
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
                  onPressed: () => Navigator.pop(ctx),
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
      ),
    );
  }

  void _showInterestCalculatorDialog(BuildContext context) {
    final amountController = TextEditingController(text: '100000000');
    final rateController = TextEditingController(text: '8.5');
    final monthsController = TextEditingController(text: '24');
    double estimatedMonthly = 4545000;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void calculate() {
              final double p = double.tryParse(amountController.text) ?? 0;
              final double r =
                  (double.tryParse(rateController.text) ?? 0) / 100;
              final int m = int.tryParse(monthsController.text) ?? 12;
              if (p > 0 && m > 0) {
                final double monthlyRate = r / 12;
                final double res = (p / m) + (p * monthlyRate);
                setDialogState(() {
                  estimatedMonthly = res;
                });
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              title: const Row(
                children: [
                  Icon(Icons.calculate_rounded, color: AppColors.primary),
                  SizedBox(width: 8.0),
                  Text(
                    'Máy tính lãi suất nhanh',
                    style: TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền vay (VNĐ)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => calculate(),
                    ),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Lãi suất (%/năm)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => calculate(),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: TextField(
                            controller: monthsController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Kỳ hạn (tháng)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (_) => calculate(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Ước tính trả hàng tháng:',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            _formatCurrency(estimatedMonthly),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Đóng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSimulationRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.0,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDtiReportModal(
    BuildContext context,
    UserModel? user,
    LoanController loanController,
  ) {
    final double income = user?.monthlyIncome ?? 0.0;
    final double commitment = loanController.totalMonthlyCommitment;
    final double dtiRatio = income > 0 ? (commitment / income) * 100 : 0.0;
    final double netCashFlow = income - commitment;
    final activeLoans = loanController.loans.where((l) => l.isActive).toList();

    final String tierTitle;
    final String tierSubtitle;
    final Color themeColor;
    final Color badgeBg;
    final IconData tierIcon;

    if (income <= 0 && commitment <= 0) {
      tierTitle = 'CHƯA GHI NHẬN NỢ & THU NHẬP';
      tierSubtitle =
          'Bạn hiện chưa có khoản nợ nào và chưa thiết lập thu nhập hàng tháng';
      themeColor = const Color(0xFF16A34A);
      badgeBg = const Color(0xFFDCFCE7);
      tierIcon = Icons.verified_user_rounded;
    } else if (income <= 0 && commitment > 0) {
      tierTitle = 'CHƯA CẬP NHẬT THU NHẬP';
      tierSubtitle =
          'Vui lòng cập nhật thu nhập hàng tháng để hệ thống tính toán chính xác tỷ lệ DTI';
      themeColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFEF3C7);
      tierIcon = Icons.warning_amber_rounded;
    } else if (dtiRatio <= 30) {
      tierTitle = 'VÙNG AN TOÀN TUYỆT ĐỐI';
      tierSubtitle =
          'Gánh nặng nợ ở mức thấp, khả năng hấp thụ và chịu tải tài chính tối ưu';
      themeColor = const Color(0xFF16A34A);
      badgeBg = const Color(0xFFDCFCE7);
      tierIcon = Icons.verified_user_rounded;
    } else if (dtiRatio <= 40) {
      tierTitle = 'VÙNG TIÊU CHUẨN AN TOÀN';
      tierSubtitle =
          'DTI nằm trong ngưỡng vàng của các ngân hàng thương mại (dưới 40%)';
      themeColor = const Color(0xFF0891B2);
      badgeBg = const Color(0xFFCFFAFE);
      tierIcon = Icons.health_and_safety_rounded;
    } else if (dtiRatio <= 50) {
      tierTitle = 'VÙNG CẢNH BÁO ÁP LỰC';
      tierSubtitle =
          'Nghĩa vụ trả nợ tiệm cận 50% thu nhập, cần kiểm soát chi tiêu chặt chẽ';
      themeColor = const Color(0xFFD97706);
      badgeBg = const Color(0xFFFEF3C7);
      tierIcon = Icons.warning_amber_rounded;
    } else {
      tierTitle = 'VÙNG RỦI RO CAO • BÁO ĐỘNG ĐỎ';
      tierSubtitle =
          'Nghĩa vụ trả nợ vượt quá mức an toàn, nguy cơ thâm hụt và mất thanh khoản';
      themeColor = const Color(0xFFDC2626);
      badgeBg = const Color(0xFFFEE2E2);
      tierIcon = Icons.dangerous_rounded;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Icon(
                      Icons.pie_chart_outline_rounded,
                      color: themeColor,
                      size: 22.0,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Báo cáo Tỷ lệ Gánh nặng Nợ (DTI)',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.0),
                        Text(
                          'Debt-to-Income Ratio • Tiêu chuẩn thẩm định tín dụng',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Hero Card: Chỉ số DTI & Đánh giá rủi ro
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: themeColor.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(tierIcon, size: 18.0, color: themeColor),
                            const SizedBox(width: 6.0),
                            Text(
                              tierTitle,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: themeColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Tiêu chuẩn: < 40%',
                          style: TextStyle(
                            fontSize: 11.0,
                            color: themeColor.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${dtiRatio.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 34.0,
                            fontWeight: FontWeight.w900,
                            color: themeColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Text(
                            tierSubtitle,
                            style: TextStyle(
                              fontSize: 12.0,
                              color: themeColor.withValues(alpha: 0.85),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),

                    // Thước đo 4 phân tầng
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 30,
                            child: Container(
                              height: 8.0,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 2.0),
                          Expanded(
                            flex: 10,
                            child: Container(
                              height: 8.0,
                              color: const Color(0xFF0891B2),
                            ),
                          ),
                          const SizedBox(width: 2.0),
                          Expanded(
                            flex: 10,
                            child: Container(
                              height: 8.0,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 2.0),
                          Expanded(
                            flex: 50,
                            child: Container(
                              height: 8.0,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0% (Tối ưu)',
                          style: TextStyle(
                            fontSize: 10.0,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        Text(
                          '40% (Ngưỡng)',
                          style: TextStyle(
                            fontSize: 10.0,
                            color: Color(0xFF0891B2),
                          ),
                        ),
                        Text(
                          '50% (Cảnh báo)',
                          style: TextStyle(
                            fontSize: 10.0,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        Text(
                          '100%+ (Rất rủi ro)',
                          style: TextStyle(
                            fontSize: 10.0,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Bảng Cân đối Thu chi & Dòng tiền ròng
              const Text(
                'Cân đối Thu nhập & Nghĩa vụ Hàng tháng',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10.0),
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildSimulationRow(
                      'Thu nhập xác nhận:',
                      income > 0
                          ? _formatCurrency(income)
                          : 'Chưa cập nhật (0 đ)',
                      AppColors.primary,
                    ),
                    const Divider(height: 14.0),
                    _buildSimulationRow(
                      'Tổng nghĩa vụ trả nợ/tháng:',
                      _formatCurrency(commitment),
                      dtiRatio > 50
                          ? const Color(0xFFDC2626)
                          : AppColors.textPrimary,
                    ),
                    const Divider(height: 14.0),
                    _buildSimulationRow(
                      netCashFlow >= 0
                          ? 'Dòng tiền thặng dư tự do:'
                          : 'Dòng tiền thâm hụt hàng tháng:',
                      (netCashFlow >= 0 ? '+ ' : '- ') +
                          _formatCurrency(netCashFlow.abs()),
                      netCashFlow >= 0
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18.0),

              // Bóc tách cơ cấu nợ theo từng hợp đồng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cơ cấu Nợ đóng góp vào DTI',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${activeLoans.length} khoản vay',
                    style: const TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              if (activeLoans.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: const Center(
                    child: Text(
                      'Không có khoản vay nào đang hoạt động.',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              else
                ...activeLoans.map((loan) {
                  final monthlyEst = loan.monthlyInstallmentEstimate;
                  final sharePercent = income > 0
                      ? (monthlyEst / income) * 100
                      : 0.0;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36.0,
                          height: 36.0,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Icon(
                            loan.isCreditCard
                                ? Icons.credit_card_rounded
                                : Icons.account_balance_rounded,
                            size: 18.0,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loan.loanName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                '${loan.lender ?? "FinCredit"} • ${loan.loanTypeDisplayName}',
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatCurrency(monthlyEst),
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2.0),
                            Text(
                              '${sharePercent.toStringAsFixed(1)}% thu nhập',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: sharePercent > 40
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 16.0),

              // Khuyến nghị chuyên gia FinCredit
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_rounded,
                          size: 18.0,
                          color: themeColor,
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          'Khuyến nghị Chiến lược FinCredit',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                            color: themeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    if (income <= 0 && commitment <= 0) ...[
                      Text(
                        'Bạn chưa có khoản nợ nào và chưa cập nhật thu nhập hàng tháng. Hồ sơ tài chính của bạn đang ở trạng thái an toàn, không có áp lực chi trả nợ.',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: themeColor,
                          height: 1.4,
                        ),
                      ),
                    ] else if (income <= 0 && commitment > 0) ...[
                      Text(
                        'Bạn đang có nghĩa vụ trả nợ ${_formatCurrency(commitment)}/tháng nhưng chưa cập nhật thu nhập. Vui lòng cập nhật thu nhập tại mục Hồ sơ cá nhân để nhận đánh giá tỷ lệ DTI chính xác.',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: themeColor,
                          height: 1.4,
                        ),
                      ),
                    ] else if (dtiRatio > 50) ...[
                      Text(
                        'Tỷ lệ DTI của bạn đang ở mức rất cao (${dtiRatio.toStringAsFixed(1)}%). Tổng nghĩa vụ trả nợ hàng tháng (${_formatCurrency(commitment)}) đã vượt qua thu nhập xác nhận (${_formatCurrency(income)}), dẫn đến thâm hụt tài chính nghiêm trọng.',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: themeColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      _buildAdviceBullet(
                        '1. Tái cơ cấu kỳ hạn vay:',
                        'Thương lượng kéo dài kỳ hạn của các khoản vay lớn (ví dụ Vay mua căn hộ) để giảm áp lực trả nợ mỗi tháng.',
                        themeColor,
                      ),
                      _buildAdviceBullet(
                        '2. Áp dụng phương pháp Avalanche:',
                        'Tập trung trả dứt điểm các khoản nợ có lãi suất cao nhất (như thẻ tín dụng 24%/năm) trước để cắt giảm dòng tiền trả lãi.',
                        themeColor,
                      ),
                      _buildAdviceBullet(
                        '3. Đóng băng các khoản nợ mới:',
                        'Tuyệt đối không sử dụng thêm thẻ tín dụng hoặc mở thêm hạn mức tín dụng mới cho đến khi DTI giảm về dưới 40%.',
                        themeColor,
                      ),
                    ] else if (dtiRatio > 40) ...[
                      Text(
                        'Tỷ lệ DTI của bạn (${dtiRatio.toStringAsFixed(1)}%) đang tiệm cận mức rủi ro (vượt ngưỡng tiêu chuẩn 40%). Cần chủ động cắt giảm chi tiêu không thiết yếu và tăng tốc tất toán các khoản nợ nhỏ.',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: themeColor,
                          height: 1.4,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Tỷ lệ DTI của bạn (${dtiRatio.toStringAsFixed(1)}%) nằm dưới ngưỡng 40%. Đây là mức tài chính an toàn cao, tạo điều kiện thuận lợi khi thẩm định hồ sơ giải ngân mới và duy trì điểm CIC cao.',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: themeColor,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // 2 Nút CTA chiến lược
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(context, AppRouter.simulation);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        side: BorderSide(color: themeColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: Text(
                        'Mô phỏng cơ cấu nợ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(context, AppRouter.debtStrategy);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: const Text(
                        'Tối ưu chiến lược nợ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdviceBullet(String title, String desc, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 11.5,
                  color: color.withValues(alpha: 0.95),
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDebtPlanningSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: AppColors.primary,
                    size: 22.0,
                  ),
                ),
                const SizedBox(width: 10.0),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kế hoạch & Tối ưu Trả nợ',
                        style: TextStyle(
                          fontSize: 17.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2.0),
                      Text(
                        'Chọn công cụ quản trị nghĩa vụ nợ thông minh',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 18.0),

            // Lựa chọn 1: Chiến lược tối ưu trả nợ (Snowball / Avalanche)
            _buildPlanningOptionCard(
              context: ctx,
              title: 'Chiến lược tối ưu trả nợ (Debt Strategy)',
              subtitle:
                  'Áp dụng thuật toán Snowball (dư nợ nhỏ trước) hoặc Avalanche (lãi suất cao trước) để tiết kiệm tối đa tiền lãi và rút ngắn thời gian trả nợ.',
              badge: 'Khuyên dùng • Tiết kiệm lãi',
              badgeColor: const Color(0xFF16A34A),
              icon: Icons.auto_graph_rounded,
              color: const Color(0xFF2563EB),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRouter.debtStrategy);
              },
            ),
            const SizedBox(height: 12.0),

            // Lựa chọn 2: Mô phỏng kịch bản trả nợ (Simulation)
            _buildPlanningOptionCard(
              context: ctx,
              title: 'Mô phỏng kịch bản trả nợ (Simulation)',
              subtitle:
                  'Dự toán chính xác số tiền lãi tiết kiệm được khi trả thêm định kỳ, tất toán trước hạn hoặc kiểm tra tác động khi lãi suất thị trường thay đổi.',
              badge: 'Dự toán tài chính',
              badgeColor: const Color(0xFF7C3AED),
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFE11D48),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, AppRouter.simulation);
              },
            ),
            const SizedBox(height: 12.0),

            // Lựa chọn 3: Xem lịch phân kỳ thanh toán
            _buildPlanningOptionCard(
              context: ctx,
              title: 'Lịch phân kỳ thanh toán định kỳ',
              subtitle:
                  'Xem toàn bộ lịch trả nợ của từng hợp đồng, các kỳ sắp đến hạn, lịch sử thanh toán và biên lai định kỳ.',
              badge: 'Kỳ hạn chi tiết',
              badgeColor: const Color(0xFF0891B2),
              icon: Icons.calendar_month_outlined,
              color: const Color(0xFF0D9488),
              onTap: () {
                Navigator.pop(ctx);
                MainShellScreen.switchTab(context, 2); // Tab Lịch trả nợ
              },
            ),
            const SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanningOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: Colors.white, size: 22.0),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6.0),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14.0,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showCashflowDetailSheet(
    BuildContext context,
    UserModel? user,
    LoanController loanController,
  ) {
    final double income = user?.monthlyIncome ?? 0.0;
    final double commitment = loanController.totalMonthlyCommitment;
    final double netCashflow = income - commitment;
    final double absorptionRate = income > 0
        ? (commitment / income) * 100
        : 0.0;
    final bool isSurplus = netCashflow >= 0;
    final activeLoans = loanController.loans.where((l) => l.isActive).toList();

    // Tính toán dự phóng 6 tháng dựa trên dữ liệu thực tế từ các khoản vay
    final now = DateTime.now();
    final List<String> months = [];
    final List<double> values = []; // đơn vị triệu đồng

    for (int i = 0; i < 6; i++) {
      final monthDate = DateTime(now.year, now.month + i, 1);
      months.add('T${monthDate.month.toString().padLeft(2, '0')}');

      double monthPayment = 0.0;
      for (final loan in activeLoans) {
        final effectiveEndDate =
            loan.endDate ??
            DateTime(
              loan.startDate.year,
              loan.startDate.month + loan.termMonths,
              loan.startDate.day,
            );
        final isMonthActive =
            monthDate.isBefore(effectiveEndDate) ||
            (monthDate.year == effectiveEndDate.year &&
                monthDate.month <= effectiveEndDate.month);

        if (isMonthActive) {
          if (loan.interestMethod == 'REDUCING_BALANCE' &&
              loan.termMonths > 0) {
            final double principalPortion =
                loan.principalAmount / loan.termMonths;
            final double estimatedRemaining =
                (loan.outstandingAmount - (principalPortion * i)).clamp(
                  0.0,
                  loan.principalAmount,
                );
            final double monthlyInterest =
                estimatedRemaining * (loan.interestRate / 12.0);
            monthPayment += (principalPortion + monthlyInterest);
          } else {
            monthPayment += loan.monthlyInstallmentEstimate;
          }
        }
      }
      values.add(double.parse((monthPayment / 1000000.0).toStringAsFixed(1)));
    }

    final double totalProjectedMillion = values.fold(0.0, (sum, v) => sum + v);
    final double maxVal = values.isEmpty
        ? 1.0
        : (values.reduce(max) > 0 ? values.reduce(max) * 1.2 : 1.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Icon(
                      Icons.analytics_rounded,
                      color: Color(0xFF0D47A1),
                      size: 22.0,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thống kê & Dự phóng Dòng tiền',
                          style: TextStyle(
                            fontSize: 17.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2.0),
                        Text(
                          'Phân tích khả năng hấp thụ nợ & thanh khoản hàng tháng',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // 3 Thẻ KPI Dòng tiền
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isSurplus
                        ? [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)]
                        : [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: isSurplus
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isSurplus
                              ? 'Dòng tiền thặng dư'
                              : 'Dòng tiền thâm hụt',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: isSurplus
                                ? const Color(0xFF166534)
                                : const Color(0xFF991B1B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 3.0,
                          ),
                          decoration: BoxDecoration(
                            color: isSurplus
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            isSurplus ? 'DƯƠNG (+)' : 'ÂM (-)',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    Row(
                      children: [
                        Text(
                          _formatCurrency(netCashflow.abs()),
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.w800,
                            color: isSurplus
                                ? const Color(0xFF166534)
                                : const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          isSurplus ? '/ tháng tự do' : '/ tháng thiếu hụt',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: isSurplus
                                ? const Color(0xFF166534)
                                : const Color(0xFF991B1B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14.0),

              // Bảng cân đối thu chi hàng tháng
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildCashflowRow(
                      'Dòng tiền vào (Thu nhập xác nhận):',
                      income > 0
                          ? '+ ${_formatCurrency(income)}'
                          : '0 đ (Chưa cập nhật)',
                      const Color(0xFF16A34A),
                      Icons.arrow_downward_rounded,
                    ),
                    const Divider(height: 14.0),
                    _buildCashflowRow(
                      'Dòng tiền ra (Tổng nghĩa vụ trả nợ):',
                      '- ${_formatCurrency(commitment)}',
                      const Color(0xFFDC2626),
                      Icons.arrow_upward_rounded,
                    ),
                    const Divider(height: 14.0),
                    _buildCashflowRow(
                      'Tỷ lệ hấp thụ dòng tiền (DTI):',
                      '${absorptionRate.toStringAsFixed(1)}%',
                      absorptionRate > 50
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0891B2),
                      Icons.pie_chart_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18.0),

              // Biểu đồ dự phóng dòng tiền 6 tháng
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Dự phóng dòng tiền chi trả (6 tháng)',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    totalProjectedMillion > 0
                        ? 'Tổng: ${totalProjectedMillion.toStringAsFixed(1)} tr'
                        : 'Tổng: 0 đ',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: totalProjectedMillion <= 0
                    ? Container(
                        height: 110.0,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.event_available_outlined,
                              size: 34.0,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(height: 6.0),
                            Text(
                              'Không có nghĩa vụ trả nợ trong 6 tháng tới',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox(
                        height: 130.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(months.length, (idx) {
                            final heightFactor = (values[idx] / maxVal).clamp(
                              0.1,
                              1.0,
                            );
                            final isCurrent = idx == 0;

                            return Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${values[idx]}tr',
                                  style: TextStyle(
                                    fontSize: 10.0,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isCurrent
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6.0),
                                Container(
                                  width: 28.0,
                                  height: 80.0 * heightFactor,
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? AppColors.primary
                                        : const Color(0xFF93C5FD),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6.0),
                                Text(
                                  months[idx],
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isCurrent
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
              ),
              const SizedBox(height: 16.0),

              // Đánh giá chuyên gia FinCredit
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: isSurplus
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: isSurplus
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isSurplus
                          ? Icons.check_circle_outline_rounded
                          : Icons.lightbulb_outline_rounded,
                      size: 20.0,
                      color: isSurplus
                          ? const Color(0xFF166534)
                          : const Color(0xFF92400E),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        isSurplus
                            ? (income <= 0 && commitment <= 0
                                  ? 'Lời khuyên FinCredit: Bạn chưa phát sinh nghĩa vụ nợ nào. Hãy cập nhật thu nhập hàng tháng để FinCredit tư vấn các phương án tích lũy và đầu tư tối ưu.'
                                  : 'Lời khuyên FinCredit: Bạn đang duy trì dòng tiền thặng dư ${_formatCurrency(netCashflow)}/tháng. Hãy trích lập tối thiểu 20% dòng tiền thặng dư vào quỹ tích lũy dự phòng trước khi đầu tư.')
                            : 'Cảnh báo FinCredit: Dòng tiền của bạn đang bị thâm hụt do nghĩa vụ nợ lớn hơn thu nhập hàng tháng. Hãy cân nhắc kéo dài kỳ hạn vay hoặc trả dứt nợ thẻ tín dụng sớm nhất để tái lập thế cân bằng.',
                        style: TextStyle(
                          fontSize: 12.0,
                          height: 1.4,
                          color: isSurplus
                              ? const Color(0xFF166534)
                              : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // 2 Nút CTA
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        MainShellScreen.switchTab(context, 2);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: const Text(
                        'Xem lịch trả nợ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(context, AppRouter.debtStrategy);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      child: const Text(
                        'Tối ưu dòng tiền',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashflowRow(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16.0, color: color),
        const SizedBox(width: 6.0),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showArticleModal(BuildContext context, String title, String summary) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                const SizedBox(width: 8.0),
                const Text(
                  'Cẩm nang FinCredit',
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              summary,
              style: const TextStyle(
                fontSize: 13.0,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_authController, _loanController]),
      builder: (context, _) {
        final user = _authController.currentUser;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFD),
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // 1. SliverAppBar (Header thông minh & Tinh tế)
                _buildSliverHeader(context, user),

                // 2. Hero Card: Tổng quan Dư nợ & Điểm Sức khỏe Tín dụng
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 0.0),
                    child: _buildHeroCreditCard(context, _loanController, user),
                  ),
                ),

                // 3. Quick Action Grid (Phím tắt nghiệp vụ tài chính 2 hàng - 8 chức năng)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                    child: _buildQuickActionGrid(
                      context,
                      user,
                      _loanController,
                    ),
                  ),
                ),

                // 4. Khối Cảnh báo Kỳ thanh toán Khẩn cấp (Urgent Due Reminder Banner)
                SliverToBoxAdapter(
                  child: _buildUrgentDueReminder(context, _loanController),
                ),

                // 5. Danh mục Khoản vay Đang hoạt động (Active Loans Horizontal Slider)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                    child: _buildActiveLoansSlider(context, _loanController),
                  ),
                ),

                // 6. Chỉ số Gánh nặng Nợ DTI (Debt-to-Income Gauge Widget)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0.0),
                    child: _buildDtiGaugeCard(context, user, _loanController),
                  ),
                ),

                // 7. Biểu đồ Dự phóng Dòng tiền Trả nợ (6-Month Cashflow Projection)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0.0),
                    child: _buildCashflowProjectionCard(
                      context,
                      _loanController,
                    ),
                  ),
                ),

                // 8. Cẩm nang Tài chính & Mẹo tăng Điểm Tín dụng (Financial Education Carousel)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                    child: _buildEducationCarousel(context),
                  ),
                ),

                // 9. Footer Tiêu chuẩn An ninh & Bản quyền
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 100.0),
                    child: _buildSecurityFooter(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= 1. Sliver Header (AppBar) =================
  Widget _buildSliverHeader(BuildContext context, UserModel? user) {
    final String initialLetter = (user?.fullName.isNotEmpty == true)
        ? user!.fullName.substring(0, 1).toUpperCase()
        : 'U';

    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      toolbarHeight: 68.0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20.0,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              initialLetter,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_greeting,',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 1.0),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        (user?.fullName.isNotEmpty == true)
                            ? user!.fullName
                            : 'Khách hàng FinCredit',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6.0,
                        vertical: 2.0,
                      ),
                      decoration: BoxDecoration(
                        color: (user?.isEkycVerified ?? false)
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (user?.isEkycVerified ?? false)
                                ? Icons.verified_rounded
                                : Icons.shield_outlined,
                            size: 11.0,
                            color: (user?.isEkycVerified ?? false)
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 3.0),
                          Text(
                            (user?.isEkycVerified ?? false)
                                ? 'Đã xác thực CIC'
                                : 'Chưa xác thực eKYC',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: (user?.isEkycVerified ?? false)
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Chuông thông báo kèm chấm đỏ số lượng đồng bộ từ PaymentScheduleController
        ListenableBuilder(
          listenable: _scheduleController,
          builder: (context, _) {
            final notifCount = _scheduleController.notifications.length;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textPrimary,
                    size: 24.0,
                  ),
                  tooltip: 'Thông báo',
                  onPressed: () => _showNotificationSheet(context),
                ),
                if (notifCount > 0)
                  Positioned(
                    right: 8.0,
                    top: 12.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 2.0,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16.0,
                        minHeight: 16.0,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        notifCount > 99 ? '99+' : '$notifCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 9.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        // Trợ giúp / CSKH (TUYỆT ĐỐI KHÔNG CÓ LOGOUT Ở ĐÂY)
        IconButton(
          icon: const Icon(
            Icons.headset_mic_outlined,
            color: AppColors.textPrimary,
            size: 23.0,
          ),
          tooltip: 'Trợ giúp & CSKH',
          onPressed: () => _showSupportModal(context),
        ),
        const SizedBox(width: 4.0),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
      ),
    );
  }

  // ================= 2. Hero Card: Tổng quan Dư nợ & Điểm CIC =================
  Widget _buildHeroCreditCard(
    BuildContext context,
    LoanController loanController,
    UserModel? user,
  ) {
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
                valueListenable: _isBalanceHidden,
                builder: (context, isHidden, _) {
                  return InkWell(
                    onTap: () {
                      _isBalanceHidden.value = !isHidden;
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
            valueListenable: _isBalanceHidden,
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
                  onPressed: () => _showDebtPlanningSheet(context),
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
                  onPressed: () =>
                      _showCashflowDetailSheet(context, user, loanController),
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

  // ================= 3. Quick Action Grid (4x2 = 8 Phím tắt) =================
  Widget _buildQuickActionGrid(
    BuildContext context,
    UserModel? user,
    LoanController loanController,
  ) {
    final actions = [
      _QuickActionItem(
        icon: Icons.add_circle_outline_rounded,
        label: 'Thêm\nkhoản vay',
        color: const Color(0xFF0D47A1),
        onTap: () => Navigator.pushNamed(context, AppRouter.loanForm),
      ),
      _QuickActionItem(
        icon: Icons.calendar_month_outlined,
        label: 'Lịch trả\nnợ tới',
        color: const Color(0xFF0284C7),
        onTap: () => MainShellScreen.switchTab(context, 2),
      ),
      _QuickActionItem(
        icon: Icons.shield_outlined,
        label: 'Tra cứu\nCIC',
        color: const Color(0xFF059669),
        onTap: () => MainShellScreen.switchTab(context, 3),
      ),
      _QuickActionItem(
        icon: Icons.document_scanner_outlined,
        label: 'Quét hợp\nđồng OCR',
        color: const Color(0xFFD97706),
        onTap: () => Navigator.pushNamed(context, AppRouter.loanCollateralOcr),
      ),
      _QuickActionItem(
        icon: Icons.calculate_outlined,
        label: 'Máy tính\nlãi suất',
        color: const Color(0xFF7C3AED),
        onTap: () => _showInterestCalculatorDialog(context),
      ),
      _QuickActionItem(
        icon: Icons.trending_up_rounded,
        label: 'Mô phỏng\ntrả nợ',
        color: const Color(0xFFE11D48),
        onTap: () => Navigator.pushNamed(context, AppRouter.simulation),
      ),
      _QuickActionItem(
        icon: Icons.auto_graph_rounded,
        label: 'Tối ưu\ntrả nợ',
        color: const Color(0xFF2563EB),
        onTap: () => Navigator.pushNamed(context, AppRouter.debtStrategy),
      ),
      _QuickActionItem(
        icon: Icons.pie_chart_outline_rounded,
        label: 'Báo cáo\nDTI',
        color: const Color(0xFF0891B2),
        onTap: () => _showDtiReportModal(context, user, loanController),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < 4; i++)
                Expanded(child: _buildQuickActionButton(actions[i])),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 4; i < 8; i++)
                Expanded(child: _buildQuickActionButton(actions[i])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(_QuickActionItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(item.icon, color: item.color, size: 22.0),
            ),
            const SizedBox(height: 6.0),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 4. Khối Cảnh báo Kỳ thanh toán Khẩn cấp =================
  Widget _buildUrgentDueReminder(
    BuildContext context,
    LoanController loanController,
  ) {
    final activeLoan =
        loanController.loans.where((l) => l.isActive).firstOrNull ??
        (loanController.loans.isNotEmpty ? loanController.loans.first : null);

    if (activeLoan == null) {
      return const SizedBox.shrink();
    }

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
                  () {
                    final dueDate = activeLoan.nextDueDate;
                    final daysLeft = dueDate
                        .difference(DateTime.now())
                        .inDays
                        .clamp(0, 365);
                    final installmentStr = _formatCurrency(
                      activeLoan.monthlyInstallmentEstimate,
                    );
                    final dueDayStr =
                        '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}';
                    return Text(
                      'Kỳ tới: $installmentStr • Hạn đóng $dueDayStr (Còn $daysLeft ngày)',
                      style: const TextStyle(
                        fontSize: 11.0,
                        color: Color(0xFFB45309),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  }(),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            ElevatedButton(
              onPressed: () {
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

  // ================= 5. Horizontal Active Loans Slider =================
  Widget _buildActiveLoansSlider(
    BuildContext context,
    LoanController loanController,
  ) {
    final activeLoans = loanController.loans.where((l) => l.isActive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Khoản vay đang theo dõi (${activeLoans.length})',
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  MainShellScreen.switchTab(context, 1); // Tab Khoản vay
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  children: [
                    Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18.0,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10.0),
        if (activeLoans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 10.0,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 24.0,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  const Text(
                    'Chưa có khoản vay nào đang theo dõi',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  const Text(
                    'Thêm khoản vay đầu tiên để bắt đầu theo dõi tiến độ trả nợ, dư nợ và tối ưu lãi suất.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.loanForm);
                    },
                    icon: const Icon(Icons.add_rounded, size: 18.0),
                    label: const Text(
                      'Tạo khoản vay mới',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 9.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 165.0,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              scrollDirection: Axis.horizontal,
              itemCount: activeLoans.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12.0),
              itemBuilder: (context, index) {
                final loan = activeLoans[index];
                return _buildMiniLoanCard(context, loan);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMiniLoanCard(BuildContext context, LoanModel loan) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRouter.loanDetail,
          arguments: {'loanId': loan.id.toString()},
        );
      },
      borderRadius: BorderRadius.circular(14.0),
      child: Container(
        width: 260.0,
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 10.0,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 3.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    loan.lenderName,
                    style: const TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  loan.interestRateFormatted,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loan.name,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Dư nợ: ${_formatCurrency(loan.outstandingAmount)}',
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: LinearProgressIndicator(
                    value: loan.progressRatio,
                    minHeight: 5.0,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Trả ${(loan.progressRatio * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '~${_formatCurrency(loan.monthlyInstallmentEstimate)}/tháng',
                      style: const TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= 6. Chỉ số Gánh nặng Nợ DTI =================
  Widget _buildDtiGaugeCard(
    BuildContext context,
    UserModel? user,
    LoanController loanController,
  ) {
    final double income = user?.monthlyIncome ?? 0.0;
    final double commitment = loanController.totalMonthlyCommitment;
    final double dtiPercent = income > 0 ? (commitment / income) * 100 : 0.0;

    final String statusLabel;
    final Color statusColor;
    final Color statusBg;
    final String analysisText;

    if (income <= 0 && commitment <= 0) {
      statusLabel = '0.0% • AN TOÀN';
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFDCFCE7);
      analysisText =
          'Phân tích FinCredit: Bạn chưa có khoản nợ nào. Hãy cập nhật thu nhập hàng tháng để hệ thống phân tích sức khỏe tài chính toàn diện.';
    } else if (income <= 0 && commitment > 0) {
      statusLabel = 'CHƯA CẬP NHẬT THU NHẬP';
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
      analysisText =
          'Phân tích FinCredit: Nghĩa vụ trả nợ hiện tại là ${_formatCurrency(commitment)}/tháng nhưng chưa ghi nhận thu nhập để tính tỷ lệ DTI.';
    } else if (dtiPercent <= 30) {
      statusLabel = '${dtiPercent.toStringAsFixed(1)}% • AN TOÀN CAO';
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFDCFCE7);
      analysisText =
          'Phân tích FinCredit: DTI ở mức rất thấp (${dtiPercent.toStringAsFixed(1)}%). Dòng tiền tự do dồi dào, hồ sơ tín dụng xuất sắc.';
    } else if (dtiPercent <= 40) {
      statusLabel = '${dtiPercent.toStringAsFixed(1)}% • TIÊU CHUẨN';
      statusColor = const Color(0xFF0891B2);
      statusBg = const Color(0xFFCFFAFE);
      analysisText =
          'Phân tích FinCredit: Thu nhập hàng tháng đủ khả năng chi trả các nghĩa vụ tài chính trong ngưỡng an toàn chuẩn mực (< 40%).';
    } else if (dtiPercent <= 50) {
      statusLabel = '${dtiPercent.toStringAsFixed(1)}% • CẢNH BÁO';
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3C7);
      analysisText =
          'Phân tích FinCredit: Nghĩa vụ trả nợ chiếm ${dtiPercent.toStringAsFixed(1)}% thu nhập. Nên kiểm soát chi tiêu và tránh mở thêm khoản vay mới.';
    } else {
      statusLabel = '${dtiPercent.toStringAsFixed(1)}% • RỦI RO CAO';
      statusColor = const Color(0xFFDC2626);
      statusBg = const Color(0xFFFEE2E2);
      analysisText =
          'Phân tích FinCredit: Cảnh báo áp lực trả nợ nặng (${dtiPercent.toStringAsFixed(1)}% thu nhập). Cần lên kế hoạch tái cơ cấu hoặc dùng chiến lược tối ưu nợ ngay.';
    }

    return InkWell(
      onTap: () => _showDtiReportModal(context, user, loanController),
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 10.0,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      'Chỉ số gánh nặng nợ (DTI)',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 4.0),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18.0,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 3.0,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Thước đo phân tầng 4 dải màu
            ClipRRect(
              borderRadius: BorderRadius.circular(6.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 30,
                    child: Container(
                      height: 8.0,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 2.0),
                  Expanded(
                    flex: 10,
                    child: Container(
                      height: 8.0,
                      color: const Color(0xFF0891B2),
                    ),
                  ),
                  const SizedBox(width: 2.0),
                  Expanded(
                    flex: 10,
                    child: Container(
                      height: 8.0,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 2.0),
                  Expanded(
                    flex: 50,
                    child: Container(
                      height: 8.0,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6.0),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '0% (An toàn)',
                  style: TextStyle(fontSize: 10.0, color: Color(0xFF16A34A)),
                ),
                Text(
                  '40% (Ngưỡng)',
                  style: TextStyle(fontSize: 10.0, color: Color(0xFF0891B2)),
                ),
                Text(
                  '100% (Rủi ro)',
                  style: TextStyle(fontSize: 10.0, color: Color(0xFFDC2626)),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Text(
              analysisText,
              style: const TextStyle(
                fontSize: 12.0,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 7. Biểu đồ Dự phóng Dòng tiền Trả nợ (6 Tháng) =================
  Widget _buildCashflowProjectionCard(
    BuildContext context,
    LoanController loanController,
  ) {
    final activeLoans = loanController.loans.where((l) => l.isActive).toList();

    // Tính toán dự phóng 6 tháng dựa trên dữ liệu thực tế từ các khoản vay
    final now = DateTime.now();
    final List<String> months = [];
    final List<double> values = []; // đơn vị triệu đồng

    for (int i = 0; i < 6; i++) {
      final monthDate = DateTime(now.year, now.month + i, 1);
      months.add('T${monthDate.month.toString().padLeft(2, '0')}');

      double monthPayment = 0.0;
      for (final loan in activeLoans) {
        final effectiveEndDate =
            loan.endDate ??
            DateTime(
              loan.startDate.year,
              loan.startDate.month + loan.termMonths,
              loan.startDate.day,
            );
        final isMonthActive =
            monthDate.isBefore(effectiveEndDate) ||
            (monthDate.year == effectiveEndDate.year &&
                monthDate.month <= effectiveEndDate.month);

        if (isMonthActive) {
          if (loan.interestMethod == 'REDUCING_BALANCE' &&
              loan.termMonths > 0) {
            final double principalPortion =
                loan.principalAmount / loan.termMonths;
            final double estimatedRemaining =
                (loan.outstandingAmount - (principalPortion * i)).clamp(
                  0.0,
                  loan.principalAmount,
                );
            final double monthlyInterest =
                estimatedRemaining * (loan.interestRate / 12.0);
            monthPayment += (principalPortion + monthlyInterest);
          } else {
            monthPayment += loan.monthlyInstallmentEstimate;
          }
        }
      }
      values.add(double.parse((monthPayment / 1000000.0).toStringAsFixed(1)));
    }

    final double totalProjectedMillion = values.fold(0.0, (sum, v) => sum + v);
    final double maxVal = values.isEmpty
        ? 1.0
        : (values.reduce(max) > 0 ? values.reduce(max) * 1.2 : 1.0);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dự phóng dòng tiền trả nợ (6 tháng)',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                totalProjectedMillion > 0
                    ? 'Tổng: ${totalProjectedMillion.toStringAsFixed(1)} tr'
                    : 'Tổng: 0 đ',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Các cột biểu đồ trực quan
          if (totalProjectedMillion <= 0)
            Container(
              height: 100.0,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.event_available_outlined,
                    size: 32.0,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 6.0),
                  Text(
                    'Không có nghĩa vụ trả nợ trong 6 tháng tới',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 120.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(months.length, (idx) {
                  final heightFactor = (values[idx] / maxVal).clamp(0.1, 1.0);
                  final isCurrent = idx == 0;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${values[idx]}tr',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Container(
                        width: 28.0,
                        height: 75.0 * heightFactor,
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primary
                              : const Color(0xFF93C5FD).withValues(alpha: 0.6),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6.0),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        months[idx],
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // ================= 8. Cẩm nang Tài chính Carousel =================
  Widget _buildEducationCarousel(BuildContext context) {
    final articles = [
      _ArticleItem(
        tag: 'Mẹo tiết kiệm',
        title: 'Cách đàm phán giảm 1-2% lãi suất vay khi biên độ thả nổi tăng',
        summary:
            'Chủ động đề xuất xem xét lại lịch sử trả nợ đúng hạn với cán bộ tín dụng và đăng ký gói bảo hiểm liên kết để hưởng ưu đãi biên độ tốt nhất.',
        icon: Icons.savings_outlined,
        color: const Color(0xFF0D47A1),
      ),
      _ArticleItem(
        tag: 'Quản lý tài chính',
        title: 'Quy tắc 50/30/20: Cân đối chi tiêu gia đình và trả nợ đúng hạn',
        summary:
            '50% cho nhu cầu thiết yếu, 30% cho mong muốn cá nhân và 20% dành riêng cho tích lũy khẩn cấp cùng kế hoạch tất toán nợ gốc sớm.',
        icon: Icons.pie_chart_outline_rounded,
        color: const Color(0xFF059669),
      ),
      _ArticleItem(
        tag: 'Tín dụng CIC',
        title:
            'Những điều cần tránh để không bị phân loại sang nợ nhóm 2 trở lên',
        summary:
            'Chậm trả quá 10 ngày sẽ tự động nhảy nhóm nợ CIC trên toàn quốc, ảnh hưởng đến việc xét duyệt vay vốn và hạn mức thẻ tín dụng trong 3 năm.',
        icon: Icons.security_rounded,
        color: const Color(0xFFD97706),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Cẩm nang tài chính & Tín dụng',
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10.0),
        SizedBox(
          height: 145.0,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: articles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12.0),
            itemBuilder: (context, index) {
              final art = articles[index];
              return InkWell(
                onTap: () => _showArticleModal(context, art.title, art.summary),
                borderRadius: BorderRadius.circular(14.0),
                child: Container(
                  width: 250.0,
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x060F172A),
                        blurRadius: 8.0,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(art.icon, size: 18.0, color: art.color),
                          const SizedBox(width: 6.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: art.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              art.tag,
                              style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                color: art.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        art.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const Row(
                        children: [
                          Text(
                            'Đọc ngay',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14.0,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= 9. Footer Tiêu chuẩn An ninh & Bản quyền =================
  Widget _buildSecurityFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Row(
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
          const SizedBox(height: 6.0),
          const Text(
            'Mã hóa đường truyền TLS 1.3 • Lưu trữ phân tán AES-256 • Chuẩn CIC SBV',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.0,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6.0),
          const Text(
            'Phiên bản v1.0.0-beta • Bản quyền © 2026 FinCredit Inc.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _ArticleItem {
  final String tag;
  final String title;
  final String summary;
  final IconData icon;
  final Color color;

  const _ArticleItem({
    required this.tag,
    required this.title,
    required this.summary,
    required this.icon,
    required this.color,
  });
}
