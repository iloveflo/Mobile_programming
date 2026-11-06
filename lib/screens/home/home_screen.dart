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
                    child: HomeHeroCard(
                      loanController: _loanController,
                      user: user,
                      isBalanceHidden: _isBalanceHidden,
                      onPlanDebt: () => DebtPlanningSheet.show(context),
                      onViewCashflow: () => CashflowDetailSheet.show(
                        context,
                        user: user,
                        loanController: _loanController,
                      ),
                    ),
                  ),
                ),

                // 3. Quick Action Grid (Phím tắt nghiệp vụ tài chính 2 hàng - 8 chức năng)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                    child: HomeQuickActionGrid(
                      onAddLoan: () =>
                          Navigator.pushNamed(context, AppRouter.loanForm),
                      onViewSchedule: () =>
                          MainShellScreen.switchTab(context, 2),
                      onViewCic: () => MainShellScreen.switchTab(context, 3),
                      onOcr: () => Navigator.pushNamed(
                        context,
                        AppRouter.loanCollateralOcr,
                      ),
                      onInterestCalc: () =>
                          QuickInterestCalculatorDialog.show(context),
                      onSimulation: () =>
                          Navigator.pushNamed(context, AppRouter.simulation),
                      onDebtStrategy: () =>
                          Navigator.pushNamed(context, AppRouter.debtStrategy),
                      onDtiReport: () => DtiReportModal.show(
                        context,
                        user: user,
                        loanController: _loanController,
                      ),
                    ),
                  ),
                ),

                // 4. Khối Cảnh báo Kỳ thanh toán Khẩn cấp (Urgent Due Reminder Banner)
                SliverToBoxAdapter(
                  child: HomeUrgentDueBanner(
                    loanController: _loanController,
                    onPayNow: () => MainShellScreen.switchTab(context, 2),
                  ),
                ),

                // 5. Danh mục Khoản vay Đang hoạt động (Active Loans Horizontal Slider)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                    child: HomeActiveLoansSlider(
                      loanController: _loanController,
                    ),
                  ),
                ),

                // 6. Chỉ số Gánh nặng Nợ DTI (Debt-to-Income Gauge Widget)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0.0),
                    child: HomeDtiGaugeCard(
                      user: user,
                      loanController: _loanController,
                      onTap: () => DtiReportModal.show(
                        context,
                        user: user,
                        loanController: _loanController,
                      ),
                    ),
                  ),
                ),

                // 7. Biểu đồ Dự phóng Dòng tiền Trả nợ (6-Month Cashflow Projection)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 0.0),
                    child: HomeCashflowProjectionCard(
                      loanController: _loanController,
                    ),
                  ),
                ),

                // 8. Cẩm nang Tài chính & Mẹo tăng Điểm Tín dụng (Financial Education Carousel)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(0.0, 20.0, 0.0, 0.0),
                    child: HomeEducationCarousel(),
                  ),
                ),

                // 9. Footer Tiêu chuẩn An ninh & Bản quyền
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 100.0),
                    child: HomeSecurityFooter(),
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
          onPressed: () => CustomerSupportModal.show(context),
        ),
        const SizedBox(width: 4.0),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: const Color(0xFFE2E8F0), height: 1.0),
      ),
    );
  }
}
