import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/simulation_controller.dart';
import '../../models/simulation_model.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/common/app_colors.dart';
import '../../widgets/common/app_snack_bar.dart';
import '../../widgets/simulation/simulation_comparison_table.dart';
import '../../widgets/simulation/simulation_history_sheet.dart';
import '../../widgets/simulation/simulation_input_card.dart';
import '../../widgets/simulation/simulation_notice_card.dart';
import '../../widgets/simulation/simulation_scenario_selector.dart';

/// Màn hình Nghiệp vụ Mô phỏng Trả nợ FinCredit (SimulationScreen)
class SimulationScreen extends StatefulWidget {
  final int? initialLoanId;

  const SimulationScreen({super.key, this.initialLoanId});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  late final SimulationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.I<SimulationController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUserId = sl<AuthController>().currentUser?.userId ?? 1;
      _controller.loadData(
        preferredLoanId: widget.initialLoanId,
        userId: currentUserId,
      );
    });
  }

  void _showSaveScenarioDialog() {
    final comp = _controller.comparisonResult;
    final loan = _controller.selectedLoan;
    if (comp == null || loan == null) return;

    final textController = TextEditingController(
      text: '${comp.scenarioType.title} - ${loan.name}',
    );

    showDialog<String>(
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
                Icons.bookmark_add_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Lưu kịch bản tham khảo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kịch bản sẽ được lưu vào danh mục tham khảo cá nhân và không ảnh hưởng đến khoản vay thực tế.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                labelText: 'Tên kịch bản gợi nhớ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Hủy bỏ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(textController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Lưu kịch bản'),
          ),
        ],
      ),
    ).then((customName) async {
      if (customName != null && customName.isNotEmpty && mounted) {
        final currentUserId = sl<AuthController>().currentUser?.userId ?? 1;
        final success = await _controller.saveCurrentSimulation(
          customName: customName,
          userId: currentUserId,
        );
        if (mounted) {
          if (success) {
            AppSnackBar.showSuccess(
              context,
              'Đã lưu kịch bản mô phỏng tham khảo thành công!',
            );
          } else {
            // EX-05: Sự cố Backend / Database
            AppSnackBar.showError(
              context,
              _controller.errorMessage ?? 'Sự cố lưu trữ kịch bản.',
            );
          }
        }
      }
    });
  }

  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SimulationHistorySheet(
        simulations: _controller.savedSimulations,
        onDelete: (id) {
          _controller.deleteSimulation(id);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final comp = _controller.comparisonResult;
        final loan = _controller.selectedLoan;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text(
              'Mô phỏng trả nợ',
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
                icon: Badge(
                  isLabelVisible: _controller.savedSimulations.isNotEmpty,
                  label: Text('${_controller.savedSimulations.length}'),
                  child: const Icon(
                    Icons.bookmarks_outlined,
                    color: AppColors.primary,
                  ),
                ),
                tooltip: 'Kịch bản đã lưu',
                onPressed: _showHistoryModal,
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                ),
                tooltip: 'Làm mới',
                onPressed: () =>
                    _controller.loadData(preferredLoanId: widget.initialLoanId),
              ),
            ],
          ),
          body: _buildBody(comp, loan),
          bottomNavigationBar: _buildBottomBar(comp),
        );
      },
    );
  }

  Widget _buildBody(SimulationComparisonResult? comp, loan) {
    if (_controller.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Đang tải dữ liệu khoản vay và chạy mô phỏng...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    // EX-01: Không có khoản vay khả dụng
    if (_controller.exceptionCode == 'EX-01' ||
        _controller.validLoans.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Nhắc nhở nguyên tắc bảo toàn dữ liệu (Mục 1, 3, 13)
          const SimulationNoticeCard(),
          const SizedBox(height: 16),

          // 2. Chọn 4 kịch bản (Mục 6)
          SimulationScenarioSelector(
            selectedScenario: _controller.selectedScenario,
            onScenarioChanged: (s) => _controller.selectScenario(s),
          ),
          const SizedBox(height: 16),

          // 3. Nhập tham số & Chọn khoản vay
          if (loan != null)
            SimulationInputCard(
              availableLoans: _controller.validLoans,
              selectedLoan: loan,
              onLoanChanged: (l) => _controller.selectLoan(l),
              scenario: _controller.selectedScenario,
              extraPayment: _controller.extraPayment,
              onExtraPaymentChanged: (val) => _controller.setExtraPayment(val),
              newMonthlyPayment: _controller.newMonthlyPayment,
              onNewMonthlyPaymentChanged: (val) =>
                  _controller.setNewMonthlyPayment(val),
              newInterestRate: _controller.newInterestRate,
              onNewInterestRateChanged: (val) =>
                  _controller.setNewInterestRate(val),
              earlyPayoffMonths: _controller.earlyPayoffMonths,
              onEarlyPayoffMonthsChanged: (val) =>
                  _controller.setEarlyPayoffMonths(val),
              earlyPaymentFeeRate: _controller.earlyPaymentFeeRate,
              onEarlyPaymentFeeRateChanged: (val) =>
                  _controller.setEarlyPaymentFeeRate(val),
              errorMessage: _controller.errorMessage,
              exceptionCode: _controller.exceptionCode,
            ),
          const SizedBox(height: 20),

          // Cảnh báo EX-02 hoặc EX-04 nếu có
          if (_controller.exceptionCode == 'EX-02' &&
              _controller.errorMessage != null)
            _buildErrorCard(_controller.errorMessage!, 'EX-02'),
          if (_controller.exceptionCode == 'EX-04' &&
              _controller.errorMessage != null)
            _buildErrorCard(_controller.errorMessage!, 'EX-04'),

          // 4. Bảng đối chiếu kịch bản mô phỏng và kế hoạch hiện tại (Mục 11)
          if (comp != null) SimulationComparisonTable(comparison: comp),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildBottomBar(SimulationComparisonResult? comp) {
    if (_controller.isLoading ||
        _controller.validLoans.isEmpty ||
        comp == null) {
      return const SizedBox.shrink();
    }

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
                    comp.scenarioType.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    comp.totalCostDifference > 0
                        ? 'Tiết kiệm ~${(comp.totalCostDifference / 1000000).toStringAsFixed(1)} triệu đ'
                        : 'Mô phỏng tham khảo',
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
            ElevatedButton.icon(
              onPressed: _controller.isSaving ? null : _showSaveScenarioDialog,
              icon: _controller.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.bookmark_add_outlined, size: 18),
              label: const Text('Lưu kịch bản'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
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

  Widget _buildEmptyState() {
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
                Icons.calculate_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chưa có khoản vay để mô phỏng',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Hệ thống cần ít nhất một khoản vay đang hoạt động để làm dữ liệu cơ sở chạy các kịch bản mô phỏng.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRouter.loanForm),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tạo khoản vay mới'),
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

  Widget _buildErrorCard(String msg, String code) {
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
              'Lỗi $code: $msg',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
