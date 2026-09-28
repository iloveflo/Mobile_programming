import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../controllers/loan_controller.dart';
import '../../models/loan_model.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình L02-01: Quản lý danh mục và danh sách khoản vay (LoanListScreen)
class LoanListScreen extends StatefulWidget {
  final bool isTab;

  const LoanListScreen({super.key, this.isTab = false});

  @override
  State<LoanListScreen> createState() => _LoanListScreenState();
}

class _LoanListScreenState extends State<LoanListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LoanController _loanController = sl<LoanController>();
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    // Tải danh sách khoản vay khi khởi tạo màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loanController.fetchLoans();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFilterChip({
    required String label,
    required LoanStatus status,
    required LoanStatus currentStatus,
  }) {
    final isSelected = status == currentStatus;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => _loanController.setFilterStatus(status),
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primarySoft,
        labelStyle: TextStyle(
          fontSize: 12.0,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primary : AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(
            color: isSelected ? AppColors.primaryLight : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: !widget.isTab,
        leading: widget.isTab
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 20.0,
                ),
                onPressed: () => Navigator.maybePop(context),
              ),
        title: const Text(
          'Danh mục khoản vay',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.document_scanner_outlined,
              color: AppColors.primary,
            ),
            tooltip: 'Tài sản & Quét OCR',
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.loanCollateralOcr);
            },
          ),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        offset: _isFabVisible ? Offset.zero : const Offset(0.0, 2.0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: Padding(
            padding: EdgeInsets.only(bottom: widget.isTab ? 72.0 : 0.0),
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.loanForm);
              },
              backgroundColor: AppColors.primary,
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 22.0,
              ),
              label: const Text(
                'Thêm khoản vay',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.axis == Axis.vertical) {
            if (notification.direction == ScrollDirection.reverse) {
              if (_isFabVisible) {
                setState(() {
                  _isFabVisible = false;
                });
              }
            } else if (notification.direction == ScrollDirection.forward) {
              if (!_isFabVisible) {
                setState(() {
                  _isFabVisible = true;
                });
              }
            }
          }
          return false; // Cho phép notification lan truyền lên MainShellScreen
        },
        child: ListenableBuilder(
          listenable: _loanController,
          builder: (context, _) {
            return RefreshIndicator(
              onRefresh: () => _loanController.fetchLoans(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Thẻ tổng quan danh mục tín dụng
                    PortfolioSummaryCard(
                      totalRemainingPrincipal:
                          _loanController.totalRemainingPrincipal,
                      totalOriginalPrincipal:
                          _loanController.totalOriginalPrincipal,
                      totalPaidAmount: _loanController.totalPaidAmount,
                      paidRatio: _loanController.paidRatio,
                      activeLoansCount: _loanController.activeLoansCount,
                      monthlyCommitment: _loanController.totalMonthlyCommitment,
                    ),
                    const SizedBox(height: 18.0),

                    // 2. Ô tìm kiếm
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            _loanController.setSearchKeyword(val),
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tìm theo tên khoản vay, ngân hàng...',
                          hintStyle: const TextStyle(
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppColors.textSecondary,
                            size: 22.0,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.cancel_rounded,
                                    color: AppColors.textSecondary,
                                    size: 18.0,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _loanController.setSearchKeyword('');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // 3. Thanh tab lọc trạng thái
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Tất cả (${_loanController.loans.length})',
                            status: LoanStatus.all,
                            currentStatus: _loanController.currentFilterStatus,
                          ),
                          _buildFilterChip(
                            label:
                                'Đang vay (${_loanController.loans.where((l) => l.isActive).length})',
                            status: LoanStatus.active,
                            currentStatus: _loanController.currentFilterStatus,
                          ),
                          _buildFilterChip(
                            label:
                                'Đã tất toán (${_loanController.loans.where((l) => l.isClosed).length})',
                            status: LoanStatus.closed,
                            currentStatus: _loanController.currentFilterStatus,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14.0),

                    // 4. Danh sách các khoản vay hoặc Trạng thái Loading / Empty
                    if (_loanController.isLoading &&
                        _loanController.loans.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (_loanController.loans.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 48.0,
                          horizontal: 20.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 56.0,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            const Text(
                              'Chưa tìm thấy khoản vay nào',
                              style: TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            const Text(
                              'Tạo khoản vay mới hoặc thay đổi từ khóa tìm kiếm.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.0,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRouter.loanForm,
                                );
                              },
                              icon: const Icon(Icons.add, size: 18.0),
                              label: const Text('Thêm mới ngay'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _loanController.loans.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12.0),
                        itemBuilder: (context, index) {
                          final loan = _loanController.loans[index];
                          return LoanCard(
                            loan: loan,
                            onTap: () {
                              _loanController.selectLoan(loan);
                              Navigator.pushNamed(
                                context,
                                AppRouter.loanDetail,
                                arguments: {
                                  'loanId': loan.id.toString(),
                                  'loan': loan,
                                },
                              );
                            },
                          );
                        },
                      ),

                    SizedBox(
                      height: widget.isTab ? 140.0 : 80.0,
                    ), // Khoảng trống đảm bảo thẻ cuối cùng không bị che khuất
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
