import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/debt_strategy_controller.dart';
import '../../models/debt_strategy_model.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/common/app_colors.dart';
import '../../widgets/common/app_snack_bar.dart';
import '../../widgets/debt_strategy/active_plan_banner.dart';
import '../../widgets/debt_strategy/debt_comparison_view.dart';
import '../../widgets/debt_strategy/debt_overview_card.dart';
import '../../widgets/debt_strategy/debt_priority_list.dart';
import '../../widgets/debt_strategy/debt_strategy_selector.dart';

/// Màn hình Nghiệp vụ Tối ưu Trả nợ FinCredit (Snowball & Avalanche)
class DebtStrategyScreen extends StatefulWidget {
  const DebtStrategyScreen({super.key});

  @override
  State<DebtStrategyScreen> createState() => _DebtStrategyScreenState();
}

class _DebtStrategyScreenState extends State<DebtStrategyScreen> {
  late final DebtStrategyController _controller;
  bool _isComparing = false;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I<DebtStrategyController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = sl<AuthController>().currentUser?.userId;
      _controller.loadData(userId: currentUserId);
    });
  }

  void _showConfirmApplyDialog(DebtStrategyPlanResult plan) {
    final bool isChanging =
        _controller.hasActivePlan &&
        _controller.activeAppliedStrategy?.strategyType !=
            plan.strategyType.code;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.verified_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isChanging
                    ? 'Thay đổi chiến lược trả nợ'
                    : 'Áp dụng kế hoạch tối ưu',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isChanging
                  ? 'Bạn có muốn chuyển đổi sang chiến lược ${plan.strategyType.title}? Kế hoạch cũ sẽ được đóng lại và kế hoạch mới sẽ được kích hoạt.'
                  : 'Bạn có muốn áp dụng kế hoạch tối ưu ${plan.strategyType.title} vào thực tế không?',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nguyên tắc bảo toàn dữ liệu (Mục 12):',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hệ thống tuyệt đối không tự ý can thiệp hay sửa đổi số tiền vay gốc, lãi suất hay lịch sử trả nợ đã tạo.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // EX-06: Người dùng hủy áp dụng
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Xác nhận áp dụng'),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && mounted) {
        final currentUserId = sl<AuthController>().currentUser?.userId ?? 1;
        final success = await _controller.applySelectedStrategy(
          userId: currentUserId,
        );
        if (mounted) {
          if (success) {
            AppSnackBar.showSuccess(
              context,
              'Đã kích hoạt kế hoạch ${plan.strategyType.title} thành công!',
            );
          } else {
            // EX-05: Sự cố Database / Lưu trữ
            AppSnackBar.showError(
              context,
              _controller.errorMessage ??
                  'Không thể lưu kế hoạch tối ưu (EX-05).',
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final plan = _controller.currentSelectedPlan;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Tối ưu trả nợ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            backgroundColor: AppColors.surface,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                ),
                tooltip: 'Làm mới dữ liệu',
                onPressed: () => _controller.loadData(),
              ),
            ],
          ),
          body: _buildBody(plan),
          bottomNavigationBar: _buildBottomActionBar(plan),
        );
      },
    );
  }

  Widget _buildBody(DebtStrategyPlanResult? plan) {
    if (_controller.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Đang phân tích các khoản nợ & mô phỏng thuật toán...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // EX-01: Không có khoản nợ
    if (_controller.exceptionCode == 'EX-01' ||
        _controller.validLoans.isEmpty) {
      return _buildEmptyDebtState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner kế hoạch đang active trong thực tế (Mục 11.4)
          if (_controller.hasActivePlan &&
              _controller.activeAppliedStrategy != null)
            ActivePlanBanner(
              activeStrategy: _controller.activeAppliedStrategy!,
              primaryTarget: plan?.primaryTarget,
              onChangeStrategy: () {
                setState(() {
                  _isComparing = true;
                });
              },
            ),

          // Cảnh báo EX-02 nếu có khoản nợ thiếu dữ liệu
          if (_controller.exceptionCode == 'EX-02' &&
              _controller.invalidLoans.isNotEmpty)
            _buildWarningBanner(
              'Cảnh báo EX-02: Có ${_controller.invalidLoans.length} khoản nợ thiếu dữ liệu đã được loại khỏi mô phỏng.',
            ),

          // Cảnh báo lỗi EX-04 nếu thuật toán gặp sự cố
          if (_controller.exceptionCode == 'EX-04' &&
              _controller.errorMessage != null)
            _buildErrorBanner(_controller.errorMessage!),

          // 1. Tổng quan các khoản nợ (Mục 6)
          DebtOverviewCard(
            totalDebts: _controller.totalDebtsCount,
            totalOutstanding: _controller.totalOutstandingDebt,
            averageInterestRate: _controller.weightedAverageInterestRate,
          ),
          const SizedBox(height: 16),

          // 2. Bộ chọn chiến lược & điều chỉnh trả thêm
          DebtStrategySelector(
            selectedType: _controller.selectedStrategyType,
            isComparing: _isComparing,
            onTypeChanged: (type) {
              setState(() => _isComparing = false);
              _controller.setStrategyType(type);
            },
            onToggleCompare: () {
              setState(() => _isComparing = !_isComparing);
            },
            extraPayment: _controller.extraMonthlyPayment,
            onExtraPaymentChanged: (val) {
              _controller.setExtraMonthlyPayment(val);
            },
          ),
          const SizedBox(height: 20),

          // 3. Nội dung: Chế độ So sánh hoặc Danh sách Kế hoạch
          if (_isComparing &&
              _controller.snowballPlan != null &&
              _controller.avalanchePlan != null)
            DebtComparisonView(
              snowballPlan: _controller.snowballPlan!,
              avalanchePlan: _controller.avalanchePlan!,
              onSelectAndApply: (type) {
                _controller.setStrategyType(type);
                setState(() => _isComparing = false);
                final selected = _controller.currentSelectedPlan;
                if (selected != null) {
                  _showConfirmApplyDialog(selected);
                }
              },
            )
          else if (plan != null)
            DebtPriorityList(plan: plan),

          const SizedBox(height: 80), // Padding cho Bottom Action Bar
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(DebtStrategyPlanResult? plan) {
    if (_controller.isLoading ||
        _controller.validLoans.isEmpty ||
        plan == null) {
      return const SizedBox.shrink();
    }

    final bool isAlreadyActive =
        _controller.hasActivePlan &&
        _controller.activeAppliedStrategy?.strategyType ==
            plan.strategyType.code;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.strategyType.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    plan.interestSaved > 0
                        ? 'Tiết kiệm ~${(plan.interestSaved / 1000000).toStringAsFixed(1)} triệu đ lãi'
                        : 'Hoàn thành trong ${plan.totalMonths} tháng',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _controller.isApplying
                  ? null
                  : () => _showConfirmApplyDialog(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAlreadyActive
                    ? AppColors.success
                    : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _controller.isApplying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isAlreadyActive ? 'Đang kích hoạt' : 'Áp dụng kế hoạch',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDebtState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.credit_score_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có khoản nợ nào cần tối ưu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tất cả các khoản vay của bạn đã được tất toán (EX-03) hoặc chưa có dữ liệu nợ trong hệ thống.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRouter.loanForm);
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm khoản vay mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _controller.loadData(),
            child: const Text(
              'Thử lại',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
