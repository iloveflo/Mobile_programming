import 'dart:io';

import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/loan_controller.dart';
import '../../models/collateral_model.dart';
import '../../repositories/interfaces/storage_repository.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../services/collateral_scanner_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/loan_contract_scanner_service.dart';
import '../../widgets/widget.dart';

/// Màn hình L02-04: Quản lý Tài sản bảo đảm & Bóc tách hợp đồng bằng OCR (LoanCollateralOcrScreen)
class LoanCollateralOcrScreen extends StatefulWidget {
  final String? loanId;

  const LoanCollateralOcrScreen({super.key, this.loanId});

  @override
  State<LoanCollateralOcrScreen> createState() =>
      _LoanCollateralOcrScreenState();
}

class _LoanCollateralOcrScreenState extends State<LoanCollateralOcrScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LoanController _loanController = sl<LoanController>();

  Map<String, dynamic>? _ocrResult;
  String? _localImagePath;
  bool _isScanning = false;
  bool _hasConnectionError = false;
  String? _connectionErrorMessage;
  String _selectedDocumentCategory =
      LoanContractScannerService.categoryLoanContract;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (_hasConnectionError) {
      setState(() {
        _hasConnectionError = false;
        _connectionErrorMessage = null;
      });
    }
    await _loanController.fetchCollaterals(widget.loanId);
    if (!mounted) return;
    if (_loanController.errorMessage != null) {
      setState(() {
        _hasConnectionError = true;
        _connectionErrorMessage = _loanController.errorMessage;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  IconData _getCollateralIcon(String type) {
    switch (type.toUpperCase()) {
      case 'REAL_ESTATE':
        return Icons.apartment_rounded;
      case 'VEHICLE':
        return Icons.directions_car_rounded;
      case 'SAVINGS':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Future<void> _handleScanOcr() async {
    final imageUploadService = sl<ImageUploadService>();
    final contractScanner = sl<LoanContractScannerService>();

    // 1. Cho phép người dùng chụp ảnh hợp đồng từ Camera hoặc chọn từ Thư viện
    final pickedFile = await imageUploadService.pickImageOnly(
      context,
      title: 'Chụp hoặc chọn ảnh hợp đồng',
    );
    if (pickedFile == null) return;

    setState(() {
      _isScanning = true;
    });

    try {
      // 2. Quét OCR ngay trên thiết bị bằng Google ML Kit (chưa tải lên R2 cho đến khi tạo khoản vay thành công)
      LoanContractScanResult? localScan;
      try {
        localScan = await contractScanner.scanContractImage(
          pickedFile.path,
          documentCategory: _selectedDocumentCategory,
        );
      } catch (_) {}

      final Map<String, dynamic>? mergedResult =
          (localScan != null && localScan.isValid)
          ? {
              ...localScan.toPrefilledMap(),
              'local_contract_image_path': pickedFile.path,
            }
          : null;

      if (!mounted) return;
      if (mergedResult == null) {
        setState(() {
          _isScanning = false;
        });
        AppSnackBar.showError(
          context,
          'Không nhận diện được thông tin hợp đồng từ ảnh. Vui lòng chụp lại rõ nét hơn.',
        );
        return;
      }

      setState(() {
        _isScanning = false;
        _ocrResult = mergedResult;
        _localImagePath = pickedFile.path;
      });
      AppSnackBar.showSuccess(
        context,
        'Đã bóc tách thông tin hợp đồng thành công!',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        AppSnackBar.showError(
          context,
          'Lỗi khi quét hợp đồng: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    }
  }

  void _showAddCollateralDialog() {
    QuickAddCollateralSheet.show(
      context,
      loanController: _loanController,
      loanId: widget.loanId,
      onCollateralAdded: (_) {
        _loanController.fetchCollaterals(widget.loanId);
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20.0,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Tài sản thế chấp & OCR',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3.0,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.0,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.shield_outlined, size: 20.0),
              text: 'Tài sản bảo đảm',
            ),
            Tab(
              icon: Icon(Icons.document_scanner_outlined, size: 20.0),
              text: 'Bóc tách OCR',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCollateralTab(), _buildOcrTab()],
      ),
    );
  }

  // ================= TAB 1: TÀI SẢN BẢO ĐẢM =================
  Widget _buildCollateralTab() {
    return ListenableBuilder(
      listenable: _loanController,
      builder: (context, _) {
        final collaterals = _loanController.collaterals;
        if (_hasConnectionError && !_loanController.isLoading) {
          return ConnectionErrorView(
            message: _connectionErrorMessage,
            onRetry: _loadInitialData,
          );
        }
        final totalCollateralVal = _loanController.totalCollateralValue > 0
            ? _loanController.totalCollateralValue
            : collaterals.fold(0.0, (sum, c) => sum + c.value);
        double outstandingForLtv = _loanController.portfolioSecuredDebt;
        double ltv = _loanController.portfolioLtvRatio;
        if (widget.loanId != null) {
          final targetLoan = _loanController.loans
              .where((l) => l.id.toString() == widget.loanId)
              .firstOrNull;
          if (targetLoan != null) {
            outstandingForLtv = targetLoan.outstandingAmount;
            ltv = totalCollateralVal > 0
                ? (outstandingForLtv / totalCollateralVal).clamp(0.0, 2.0)
                : 0.0;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh LTV tổng thể
              LtvIndicatorBar(
                ltvRatio: ltv,
                outstandingAmount: outstandingForLtv,
                collateralValue: totalCollateralVal,
                debtLabel: widget.loanId == null ? 'Dư nợ có TSBĐ' : 'Dư nợ',
              ),
              const SizedBox(height: 18.0),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'DANH SÁCH TÀI SẢN BẢO ĐẢM',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  TextButton.icon(
                    onPressed: _showAddCollateralDialog,
                    icon: const Icon(Icons.add, size: 16.0),
                    label: const Text(
                      'Thêm tài sản',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              if (collaterals.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 36.0,
                    horizontal: 20.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 48.0,
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12.0),
                      const Text(
                        'Chưa có tài sản bảo đảm nào',
                        style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      const Text(
                        'Bạn chưa đăng ký tài sản thế chấp nào cho các khoản vay.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      OutlinedButton.icon(
                        onPressed: _showAddCollateralDialog,
                        icon: const Icon(Icons.add, size: 16.0),
                        label: const Text('Thêm tài sản ngay'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
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
                  itemCount: collaterals.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10.0),
                  itemBuilder: (context, index) {
                    final item = collaterals[index];
                    return _buildCollateralCard(item);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollateralCard(CollateralModel item) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primarySoft,
                child: Icon(
                  _getCollateralIcon(item.type),
                  color: AppColors.primary,
                  size: 22.0,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Loại: ${item.typeDisplay} • Định giá: ${item.valuationDateFormatted}',
                      style: const TextStyle(
                        fontSize: 11.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _formatCurrency(item.value),
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Xóa tài sản bảo đảm',
                visualDensity: VisualDensity.compact,
                onPressed: () => _handleDeleteCollateral(item),
                icon: const Icon(
                  Icons.delete_forever_outlined,
                  color: AppColors.error,
                  size: 20.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          const Divider(height: 1.0, color: AppColors.border),
          const SizedBox(height: 8.0),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.0,
              runSpacing: 6.0,
              children: [
                if (!item.hasLegalDocument) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 4.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () => _handleUploadCollateralDocument(item),
                    icon: const Icon(
                      Icons.upload_file_outlined,
                      size: 14.0,
                      color: AppColors.textSecondary,
                    ),
                    label: const Text(
                      'Tải giấy tờ',
                      style: TextStyle(
                        fontSize: 11.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 5.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.gpp_bad_outlined,
                          size: 13.0,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 4.0),
                        Flexible(
                          child: Text(
                            'Chưa đủ thẩm quyền thế chấp',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 4.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onPressed: () {
                      AppDocumentViewerModal.show(
                        context,
                        title: 'Giấy tờ pháp lý: ${item.name}',
                        fileKey: item.legalDocumentUrl!,
                        documentType: 'Giấy chứng nhận tài sản bảo đảm',
                        ocrDetails: {
                          'asset_name': item.name,
                          'loai_tai_san': item.typeDisplay,
                          'valuation_amount': item.value,
                          'ngay_dinh_gia': item.valuationDateFormatted,
                        },
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 14.0),
                    label: const Text(
                      'Xem giấy tờ',
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4.0),
                  IconButton(
                    tooltip: 'Xóa giấy tờ khỏi R2',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _handleDeleteCollateralDocument(item),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18.0,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteCollateral(CollateralModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài sản bảo đảm?'),
        content: Text(
          'Bạn có chắc muốn xóa tài sản "${item.name}"? Nếu tài sản không đang thế chấp cho khoản vay hiệu lực, cả ảnh giấy tờ trên R2 cũng sẽ bị xóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa tài sản'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await _loanController.deleteCollateral(item.id);
    if (!mounted) return;
    if (ok) {
      AppSnackBar.showSuccess(
        context,
        'Đã xóa tài sản "${item.name}" và dọn sạch giấy tờ trên R2.',
      );
    } else {
      AppSnackBar.showError(
        context,
        _loanController.errorMessage ?? 'Không thể xóa tài sản này.',
      );
    }
  }

  Future<void> _handleDeleteCollateralDocument(CollateralModel item) async {
    final docKey = item.legalDocumentUrl;
    if (docKey == null || docKey.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giấy tờ tài sản?'),
        content: Text(
          'Bạn có chắc muốn xóa giấy tờ pháp lý của "${item.name}" khỏi Cloudflare R2?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await sl<StorageRepository>().deleteFile(docKey);
      await _loanController.fetchCollaterals(widget.loanId);
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Đã xóa giấy tờ khỏi R2 thành công!');
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        'Không thể xóa giấy tờ: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  Future<void> _handleUploadCollateralDocument(CollateralModel item) async {
    final user = sl.isRegistered<AuthController>()
        ? sl<AuthController>().currentUser
        : null;
    if (user == null ||
        !user.isEkycVerified ||
        user.idCardNumber == null ||
        user.idCardNumber!.trim().length != 12) {
      AppSnackBar.showError(
        context,
        'Vui lòng xác thực định danh eKYC CCCD ở Hồ sơ cá nhân trước khi tải giấy tờ tài sản.',
      );
      return;
    }

    final imageUploadService = sl<ImageUploadService>();
    final picked = await imageUploadService.pickImageOnly(
      context,
      title: 'Chụp / Chọn giấy tờ pháp lý: ${item.name}',
    );
    if (picked == null || !mounted) return;

    try {
      await CollateralScannerService().scanAndVerify(
        picked.path,
        assetType: item.type,
        expectedIdCardNumber: user.idCardNumber!,
        expectedOwnerName: user.fullName,
      );

      final result = await imageUploadService.uploadPickedFile(
        picked,
        folder: 'legal-documents',
        filePrefix: 'asset_${item.id}',
        isPublic: false,
        metadata: {'asset_id': item.id, 'name': item.name},
      );
      if (!mounted) return;
      if (result.isSuccess) {
        await _loanController.fetchCollaterals(widget.loanId);
        if (!mounted) return;
        AppSnackBar.showSuccess(
          context,
          'Kiểm định & tải lên giấy tờ "${item.name}" thành công!',
        );
      } else if (result.errorMessage != null) {
        AppSnackBar.showError(context, result.errorMessage!);
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ================= TAB 2: QUÉT & BÓC TÁCH OCR =================
  Widget _buildOcrTab() {
    return ListenableBuilder(
      listenable: _loanController,
      builder: (context, _) {
        if (_hasConnectionError && !_loanController.isLoading) {
          return ConnectionErrorView(
            message: _connectionErrorMessage,
            onRetry: _loadInitialData,
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner giới thiệu công nghệ
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0xFF334155),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF38BDF8),
                        size: 22.0,
                      ),
                    ),
                    SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Document OCR Scanner',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2.0),
                          Text(
                            'Tự động nhận diện hợp đồng tín dụng ngân hàng, bóc tách dư nợ, lãi suất và lịch trả nợ.',
                            style: TextStyle(
                              fontSize: 11.0,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Chọn mẫu tài liệu mô phỏng
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chọn loại chứng từ cần bóc tách:',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedDocumentCategory,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 10.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value:
                              LoanContractScannerService.categoryLoanContract,
                          child: Text(
                            'Hợp đồng tín dụng / Vay vốn ngân hàng',
                            style: TextStyle(fontSize: 13.0),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: LoanContractScannerService
                              .categoryCreditCardStatement,
                          child: Text(
                            'Sao kê / Hợp đồng thẻ tín dụng',
                            style: TextStyle(fontSize: 13.0),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedDocumentCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14.0),
                    AppPrimaryButton(
                      label: 'Bắt đầu quét & bóc tách AI',
                      isLoading: _isScanning,
                      onPressed: _handleScanOcr,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18.0),

              // Kết quả bóc tách OCR
              if (_ocrResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: AppColors.primaryLight,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: AppColors.success,
                                size: 20.0,
                              ),
                              SizedBox(width: 6.0),
                              Text(
                                'Kết quả bóc tách',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 3.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              'Độ tin cậy: ${((_ocrResult!['confidence_score'] ?? 0.96) * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 10.0),

                      _buildReviewRow(
                        'Mã hợp đồng',
                        _ocrResult!['contract_number']?.toString() ??
                            'Chưa nhận diện được',
                      ),
                      _buildReviewRow(
                        'Tên khoản vay',
                        _ocrResult!['loan_name']?.toString() ??
                            'Chưa nhận diện được',
                      ),
                      _buildReviewRow(
                        'Tổ chức cấp tín dụng',
                        (_ocrResult!['lender_name'] ?? _ocrResult!['lender'])
                                ?.toString() ??
                            'Chưa nhận diện được',
                      ),
                      _buildReviewRow(
                        'Số tiền giải ngân',
                        _ocrResult!['principal_amount'] is num
                            ? _formatCurrency(
                                _ocrResult!['principal_amount'] as num,
                              )
                            : 'Chưa nhận diện được',
                        isHighlight: _ocrResult!['principal_amount'] is num,
                      ),
                      _buildReviewRow(
                        'Lãi suất năm',
                        _ocrResult!['interest_rate'] != null
                            ? '${_ocrResult!['interest_rate']}% / năm'
                            : 'Chưa nhận diện được',
                      ),
                      _buildReviewRow(
                        'Kỳ hạn vay',
                        (_ocrResult!['tenor_months'] ??
                                    _ocrResult!['term_months']) !=
                                null
                            ? '${_ocrResult!['tenor_months'] ?? _ocrResult!['term_months']} tháng'
                            : 'Chưa nhận diện được',
                      ),
                      _buildReviewRow(
                        'Ngày ký kết',
                        _ocrResult!['start_date']?.toString() ??
                            'Chưa nhận diện được',
                      ),
                      if (_ocrResult!['collateral_hint'] != null)
                        _buildReviewRow(
                          'Tài sản bảo đảm gợi ý',
                          _ocrResult!['collateral_hint'].toString(),
                        ),

                      const SizedBox(height: 16.0),
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16.0,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                'Vui lòng kiểm tra lại thông tin trước khi áp dụng vào biểu mẫu tạo khoản vay.',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14.0),

                      // Nút xem bản scan hợp đồng gốc (ảnh nội bộ trên thiết bị, chưa tải lên R2)
                      if (_localImagePath != null) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 14.0,
                              ),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  insetPadding: const EdgeInsets.all(16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          16.0,
                                          12.0,
                                          8.0,
                                          8.0,
                                        ),
                                        child: Row(
                                          children: [
                                            const Expanded(
                                              child: Text(
                                                'Bản scan hợp đồng gốc',
                                                style: TextStyle(
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.close),
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Flexible(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12.0,
                                            0.0,
                                            12.0,
                                            12.0,
                                          ),
                                          child: InteractiveViewer(
                                            child: Image.file(
                                              File(_localImagePath!),
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18.0,
                            ),
                            label: const Text(
                              'Xem bản scan hợp đồng gốc',
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12.0),
                      ],

                      // Nút chuyển dữ liệu sang Form
                      AppPrimaryButton(
                        label: 'Điền tự động vào Form tạo khoản vay',
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRouter.loanForm,
                            arguments: {'prefilled': _ocrResult},
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30.0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReviewRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w700,
                color: isHighlight ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
