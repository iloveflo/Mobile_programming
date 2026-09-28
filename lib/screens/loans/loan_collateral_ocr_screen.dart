import 'package:flutter/material.dart';

import '../../controllers/loan_controller.dart';
import '../../models/collateral_model.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
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
  bool _isScanning = false;
  String _selectedDocumentType = 'Hợp đồng tín dụng Techcombank';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loanController.fetchCollaterals(widget.loanId);
    });
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
    setState(() {
      _isScanning = true;
    });

    final result = await _loanController.processOcr('sample_contract_scan.jpg');

    if (mounted) {
      setState(() {
        _isScanning = false;
        _ocrResult = result;
      });
      if (result != null) {
        AppSnackBar.showSuccess(
          context,
          'Bóc tách tài liệu hợp đồng thành công!',
        );
      }
    }
  }

  void _showAddCollateralDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    String type = 'REAL_ESTATE';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (innerCtx, setDialogState) {
          final config = CollateralModel.getConfig(type);

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            title: const Text(
              'Thêm tài sản bảo đảm',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText:
                            'Tên tài sản (ví dụ: Sổ đỏ Chung cư Times City) *',
                      ),
                      validator: AppValidators.validateCollateralName,
                    ),
                    const SizedBox(height: 12.0),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Loại tài sản bảo đảm *',
                      ),
                      items: CollateralModel.typeConfigs.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => type = val);
                      },
                    ),
                    const SizedBox(height: 12.0),
                    TextFormField(
                      controller: valCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Giá trị định giá (VNĐ) *',
                        helperText: 'Hạn mức: ${config.limitRangeText}',
                        helperMaxLines: 2,
                      ),
                      validator: (val) => AppValidators.validateCollateralValue(
                        val,
                        min: config.minValue,
                        max: config.maxValue,
                        displayName: config.displayName,
                        minFormatted: config.minFormatted,
                        maxFormatted: config.maxFormatted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }
                  final rawVal = valCtrl.text
                      .replaceAll('.', '')
                      .replaceAll(',', '')
                      .trim();
                  final val = double.tryParse(rawVal) ?? 0.0;
                  final name = nameCtrl.text.trim();

                  Navigator.pop(dialogCtx);
                  final success = await _loanController.addCollateral(
                    name: name,
                    type: type,
                    value: val,
                    loanId: widget.loanId,
                  );

                  if (!mounted) {
                    return;
                  }
                  if (success) {
                    AppSnackBar.showSuccess(
                      context,
                      'Đã ghi nhận tài sản "$name" (${_formatCurrency(val)}) thành công!',
                    );
                  } else {
                    AppSnackBar.showError(
                      context,
                      _loanController.errorMessage ?? 'Không thể thêm tài sản.',
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Thêm'),
              ),
            ],
          );
        },
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
        final totalCollateralVal = _loanController.totalCollateralValue > 0
            ? _loanController.totalCollateralValue
            : collaterals.fold(0.0, (sum, c) => sum + c.value);
        final double ltv = _loanController.portfolioLtvRatio;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh LTV tổng thể
              LtvIndicatorBar(
                ltvRatio: ltv,
                outstandingAmount: _loanController.totalRemainingPrincipal,
                collateralValue: totalCollateralVal,
              ),
              const SizedBox(height: 18.0),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'DANH SÁCH TÀI SẢN BẢO ĐẢM',
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.8,
                    ),
                  ),
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
      child: Row(
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
        ],
      ),
    );
  }

  // ================= TAB 2: QUÉT & BÓC TÁCH OCR =================
  Widget _buildOcrTab() {
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
                  'Chọn tài liệu hợp đồng quét mẫu:',
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8.0),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDocumentType,
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
                      value: 'Hợp đồng tín dụng Techcombank',
                      child: Text(
                        'Hợp đồng tín dụng Techcombank (Mua nhà)',
                        style: TextStyle(fontSize: 13.0),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Hợp đồng vay tiêu dùng MBBank',
                      child: Text(
                        'Hợp đồng tiêu dùng MBBank (Mua xe)',
                        style: TextStyle(fontSize: 13.0),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Sao kê thẻ tín dụng VIB',
                      child: Text(
                        'Sao kê thẻ tín dụng VIB Super Card',
                        style: TextStyle(fontSize: 13.0),
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedDocumentType = val);
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
                border: Border.all(color: AppColors.primaryLight, width: 1.5),
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
                            'Kết quả bóc tách (Review)',
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
                    _ocrResult!['contract_number']?.toString() ?? 'HD-2026/089',
                  ),
                  _buildReviewRow(
                    'Tên khoản vay',
                    _ocrResult!['loan_name']?.toString() ??
                        'Vay mua căn hộ Masteri',
                  ),
                  _buildReviewRow(
                    'Tổ chức cấp tín dụng',
                    _ocrResult!['lender_name']?.toString() ?? 'Techcombank',
                  ),
                  _buildReviewRow(
                    'Số tiền giải ngân',
                    _formatCurrency(
                      _ocrResult!['principal_amount'] ?? 1500000000,
                    ),
                    isHighlight: true,
                  ),
                  _buildReviewRow(
                    'Lãi suất năm',
                    '${_ocrResult!['interest_rate'] ?? 9.2}% / năm',
                  ),
                  _buildReviewRow(
                    'Kỳ hạn vay',
                    '${_ocrResult!['tenor_months'] ?? 120} tháng',
                  ),
                  _buildReviewRow(
                    'Ngày ký kết',
                    _ocrResult!['start_date']?.toString() ?? '15/09/2026',
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
                  const SizedBox(height: 16.0),

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
  }

  Widget _buildReviewRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              color: isHighlight ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
