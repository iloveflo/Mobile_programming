import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/loan_controller.dart';
import '../../controllers/payment_schedule_controller.dart';
import '../../models/loan_model.dart';
import '../../models/payment_schedule_model.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình Lịch thanh toán định kỳ & Nhắc nợ (Mục 5: Xem lịch thanh toán)
class PaymentScheduleScreen extends StatefulWidget {
  const PaymentScheduleScreen({super.key});

  @override
  State<PaymentScheduleScreen> createState() => _PaymentScheduleScreenState();
}

class _PaymentScheduleScreenState extends State<PaymentScheduleScreen> {
  late final PaymentScheduleController _scheduleController;
  late final LoanController _loanController;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _scheduleController = sl<PaymentScheduleController>();
    _loanController = sl<LoanController>();
    _authController = sl<AuthController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = _authController.currentUser?.userId;
      _scheduleController.loadSchedules(userId: userId);
      _scheduleController.loadNotifications(userId: userId);
      if (_loanController.loans.isEmpty) {
        _loanController.fetchLoans();
      }
    });
  }

  void _handlePaySchedule(PaymentScheduleModel schedule) async {
    final success = await _scheduleController.markAsPaid(
      schedule.id,
      userId: _authController.currentUser?.userId,
    );

    if (!mounted) return;

    if (success) {
      AppSnackBar.showSuccess(
        context,
        'Đã ghi nhận thanh toán hoàn tất cho Kỳ ${schedule.installmentNumber}!',
      );
    } else {
      AppSnackBar.showError(
        context,
        _scheduleController.errorMessage ??
            'Không thể ghi nhận thanh toán kỳ này.',
      );
    }
  }

  void _showScheduleDetail(PaymentScheduleModel schedule) {
    final loan = _findLoan(schedule.loanId);
    ScheduleDetailSheet.show(
      context,
      schedule: schedule,
      loanName: loan?.name,
      onPay: () => _handlePaySchedule(schedule),
    );
  }

  LoanModel? _findLoan(int loanId) {
    return _loanController.loans.cast<LoanModel?>().firstWhere(
      (l) => l?.id == loanId,
      orElse: () => null,
    );
  }

  void _openPreferences() {
    final pref = _scheduleController.preference;
    if (pref == null) return;

    final user = _authController.currentUser;
    NotificationPreferenceSheet.show(
      context,
      currentPreference: pref,
      userEmail: user?.email,
      userPhone: user?.phone,
      onSave: (newPref) async {
        final success = await _scheduleController.updatePreference(
          newPref,
          userEmail: user?.email,
          userPhone: user?.phone,
        );
        if (!mounted) return false;

        if (success) {
          AppSnackBar.showSuccess(
            context,
            'Đã cập nhật cấu hình nhắc nợ thành công!',
          );
          return true;
        } else {
          AppSnackBar.showError(
            context,
            _scheduleController.errorMessage ??
                'Không thể lưu cài đặt nhắc nợ.',
          );
          return false;
        }
      },
    );
  }

  void _openNotifications() {
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
          _showScheduleDetail(_scheduleController.selectedSchedule!);
        } else {
          AppSnackBar.showError(
            context,
            _scheduleController.errorMessage ??
                'Không tìm thấy kỳ thanh toán liên kết.',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Lịch thanh toán định kỳ',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded, color: AppColors.primary),
            tooltip: 'Đồng bộ lịch & nhắc nợ',
            onPressed: () async {
              final count = await _scheduleController.syncSchedules(
                userId: _authController.currentUser?.userId,
              );
              if (!mounted) return;
              AppSnackBar.showSuccess(
                this.context,
                'Đã đồng bộ lịch và làm mới $count thông báo nhắc nợ!',
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _scheduleController,
        builder: (context, _) {
          if (_scheduleController.isLoading &&
              _scheduleController.schedules.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // EX-02: Lỗi phân quyền truy cập
          if (_scheduleController.exceptionCode == 'EX-02') {
            return _buildErrorState(
              icon: Icons.gpp_bad_rounded,
              iconColor: AppColors.error,
              title: 'Không có quyền truy cập',
              message:
                  _scheduleController.errorMessage ??
                  'Bạn không có quyền truy xuất lịch thanh toán của tài khoản khác.',
              actionLabel: 'Thử lại',
              onAction: () => _scheduleController.loadSchedules(
                userId: _authController.currentUser?.userId,
              ),
            );
          }

          // EX-06: Lỗi kết nối hoặc cơ sở dữ liệu
          if (_scheduleController.exceptionCode == 'EX-06' &&
              _scheduleController.schedules.isEmpty) {
            return _buildErrorState(
              icon: Icons.cloud_off_rounded,
              iconColor: AppColors.error,
              title: 'Sự cố kết nối hệ thống',
              message:
                  _scheduleController.errorMessage ??
                  'Không thể tải dữ liệu lịch thanh toán. Vui lòng thử lại sau.',
              actionLabel: 'Thử lại ngay',
              onAction: () => _scheduleController.loadSchedules(
                userId: _authController.currentUser?.userId,
              ),
            );
          }

          // EX-01: Chưa có lịch phân kỳ nào
          if (_scheduleController.isEmptyState) {
            return RefreshIndicator(
              onRefresh: () => _scheduleController.loadSchedules(
                userId: _authController.currentUser?.userId,
              ),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: ScheduleEmptyState(
                    onAddLoan: () =>
                        Navigator.pushNamed(context, AppRouter.loanForm),
                  ),
                ),
              ),
            );
          }

          final schedules = _scheduleController.filteredSchedules;

          return RefreshIndicator(
            onRefresh: () => _scheduleController.loadSchedules(
              userId: _authController.currentUser?.userId,
            ),
            color: AppColors.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              children: [
                // 1. Thẻ tổng quan nghĩa vụ tài chính tháng này & phím tắt
                ScheduleSummaryCard(
                  currentMonthDueAmount:
                      _scheduleController.currentMonthDueAmount,
                  upcomingCount: _scheduleController.upcomingCount,
                  overdueCount: _scheduleController.overdueCount,
                  paidCount: _scheduleController.paidCount,
                  onOpenPreferences: _openPreferences,
                  onOpenNotifications: _openNotifications,
                ),
                const SizedBox(height: 18.0),

                // 2. Bộ lọc trạng thái kỳ thanh toán (ALL, UPCOMING, OVERDUE, PAID)
                _buildFilterChips(),
                const SizedBox(height: 14.0),

                // 3. Tiêu đề danh sách
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'KẾ HOẠCH TRẢ NỢ CHI TIẾT',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${schedules.length} kỳ',
                      style: const TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),

                // 4. Danh sách các thẻ kỳ thanh toán
                if (schedules.isEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    alignment: Alignment.center,
                    child: const Text(
                      'Không có kỳ thanh toán nào phù hợp với bộ lọc.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13.0,
                      ),
                    ),
                  ),
                ] else ...[
                  ...schedules.map((schedule) {
                    final loan = _findLoan(schedule.loanId);
                    return PaymentScheduleCard(
                      schedule: schedule,
                      loanName: loan?.name,
                      onTap: () => _showScheduleDetail(schedule),
                      onPay: () => _handlePaySchedule(schedule),
                    );
                  }),
                ],
                const SizedBox(
                  height: 80.0,
                ), // Đệm đáy cho Bottom Navigation Bar
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'key': 'ALL', 'label': 'Tất cả'},
      {'key': 'UPCOMING', 'label': 'Sắp đến hạn'},
      {'key': 'OVERDUE', 'label': 'Quá hạn'},
      {'key': 'PAID', 'label': 'Đã hoàn tất'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _scheduleController.currentFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(f['label']!),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
              onSelected: (_) => _scheduleController.setFilter(f['key']!),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorState({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54.0, color: iconColor),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13.0,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
