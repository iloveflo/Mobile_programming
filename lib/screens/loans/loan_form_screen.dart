import 'package:flutter/material.dart';

import '../../controllers/loan_controller.dart';
import '../../mock_data/loan_mock_data.dart';
import '../../models/collateral_model.dart';
import '../../models/loan_model.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình L02-03: Thêm mới & Cập nhật khoản vay (LoanFormScreen)
class LoanFormScreen extends StatefulWidget {
  final LoanModel? initialLoan;
  final Map<String, dynamic>? prefilledData;

  const LoanFormScreen({super.key, this.initialLoan, this.prefilledData});

  @override
  State<LoanFormScreen> createState() => _LoanFormScreenState();
}

class _LoanFormScreenState extends State<LoanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final LoanController _loanController = sl<LoanController>();

  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _rateController;
  late TextEditingController _tenorController;
  late TextEditingController _startDateController;
  late TextEditingController _collateralNameController;
  late TextEditingController _collateralValController;

  String _selectedBank = 'Techcombank';
  String _selectedLoanType = 'MORTGAGE';
  String _selectedCollateralType = 'REAL_ESTATE';
  InterestMethod _selectedMethod = InterestMethod.reducingBalance;
  DateTime _startDate = DateTime.now();
  int _tenorMonths = 24;

  bool _isEdit = false;
  String? _loanIdToEdit;
  String? _loanCodeToEdit;

  final List<double> _quickAmounts = [
    50000000,
    100000000,
    300000000,
    500000000,
    1000000000,
  ];

  final List<int> _quickTenors = [12, 24, 36, 60, 120, 240];

  @override
  void initState() {
    super.initState();
    final loan = widget.initialLoan;
    final prefilled = widget.prefilledData;

    _isEdit = loan != null;
    _loanIdToEdit = loan?.id.toString();
    _loanCodeToEdit = loan?.loanCode;

    // Phân tích thông tin ngân hàng & loại khoản vay
    if (loan != null) {
      _selectedBank = LoanMockData.standardBanks.contains(loan.lenderName)
          ? loan.lenderName
          : LoanMockData.standardBanks.first;
      _selectedLoanType = loan.loanTypeKey;
      _tenorMonths = loan.tenorMonths;
      _startDate = loan.startDate;
    } else if (prefilled != null) {
      final lender = prefilled['lender_name']?.toString() ?? '';
      _selectedBank = LoanMockData.standardBanks.contains(lender)
          ? lender
          : LoanMockData.standardBanks.first;
      final type = prefilled['loan_type']?.toString();
      if (type != null && LoanMockData.loanTypeLabels.containsKey(type)) {
        _selectedLoanType = type;
      } else {
        _selectedLoanType = 'MORTGAGE';
      }
      final parsedTenor =
          int.tryParse(prefilled['tenor_months']?.toString() ?? '24') ?? 24;
      _tenorMonths = parsedTenor;
    } else {
      _selectedBank = 'Techcombank';
      _selectedLoanType = 'MORTGAGE';
      _tenorMonths = 24;
    }

    _nameController = TextEditingController(
      text: loan?.loanName ?? prefilled?['loan_name'] ?? '',
    );
    _amountController = TextEditingController(
      text: loan != null
          ? loan.principalAmount.round().toString()
          : (prefilled?['principal_amount']?.toString() ?? ''),
    );

    // Lãi suất hiển thị dưới dạng phần trăm (ví dụ: 8.5)
    double initialRate = 8.5;
    if (loan != null) {
      initialRate = loan.interestRatePercent;
    } else if (prefilled != null && prefilled['interest_rate'] != null) {
      final r = double.tryParse(prefilled['interest_rate'].toString()) ?? 8.5;
      initialRate = r <= 1.0 ? r * 100.0 : r;
    } else {
      initialRate = LoanMockData.getBenchmarkRate(
        _selectedBank,
        _selectedLoanType,
      );
    }
    _rateController = TextEditingController(
      text: initialRate.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), ''),
    );

    _tenorController = TextEditingController(text: _tenorMonths.toString());
    _startDateController = TextEditingController(
      text:
          '${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}',
    );

    _collateralNameController = TextEditingController();
    _collateralValController = TextEditingController();

    if (loan != null &&
        (loan.interestMethod.contains('ban đầu') ||
            loan.interestMethod == 'FLAT')) {
      _selectedMethod = InterestMethod.flatRate;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && !_isEdit && _nameController.text.isEmpty) {
      final loan = args['loan'] as LoanModel?;
      final prefilled = args['prefilled'] as Map<String, dynamic>?;

      if (loan != null) {
        setState(() {
          _isEdit = true;
          _loanIdToEdit = loan.id.toString();
          _loanCodeToEdit = loan.loanCode;
          _nameController.text = loan.loanName;
          _selectedBank = LoanMockData.standardBanks.contains(loan.lenderName)
              ? loan.lenderName
              : LoanMockData.standardBanks.first;
          _selectedLoanType = loan.loanTypeKey;
          _amountController.text = loan.principalAmount.round().toString();
          final r = loan.interestRatePercent;
          _rateController.text = r
              .toStringAsFixed(1)
              .replaceAll(RegExp(r'\.0$'), '');
          _tenorMonths = loan.tenorMonths;
          _tenorController.text = _tenorMonths.toString();
          _startDate = loan.startDate;
          _startDateController.text = loan.startDateFormatted;
          if (loan.interestMethod.contains('ban đầu') ||
              loan.interestMethod == 'FLAT') {
            _selectedMethod = InterestMethod.flatRate;
          }
        });
      } else if (prefilled != null) {
        setState(() {
          _nameController.text = prefilled['loan_name']?.toString() ?? '';
          final lender = prefilled['lender_name']?.toString() ?? '';
          if (LoanMockData.standardBanks.contains(lender)) {
            _selectedBank = lender;
          }
          final type = prefilled['loan_type']?.toString();
          if (type != null && LoanMockData.loanTypeLabels.containsKey(type)) {
            _selectedLoanType = type;
          }
          _amountController.text =
              prefilled['principal_amount']?.toString() ?? '';
          final r =
              double.tryParse(
                prefilled['interest_rate']?.toString() ?? '8.5',
              ) ??
              8.5;
          _rateController.text = (r <= 1.0 ? r * 100.0 : r)
              .toStringAsFixed(1)
              .replaceAll(RegExp(r'\.0$'), '');
          _tenorMonths =
              int.tryParse(prefilled['tenor_months']?.toString() ?? '24') ?? 24;
          _tenorController.text = _tenorMonths.toString();
          if (prefilled['start_date'] != null) {
            _startDateController.text = prefilled['start_date'].toString();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _rateController.dispose();
    _tenorController.dispose();
    _startDateController.dispose();
    _collateralNameController.dispose();
    _collateralValController.dispose();
    super.dispose();
  }

  double get _currentPrincipal =>
      double.tryParse(
        _amountController.text.replaceAll('.', '').replaceAll(',', '').trim(),
      ) ??
      0.0;
  double get _currentRate =>
      double.tryParse(_rateController.text.trim()) ?? 0.0;
  double get _currentCollateralVal =>
      double.tryParse(
        _collateralValController.text
            .replaceAll('.', '')
            .replaceAll(',', '')
            .trim(),
      ) ??
      0.0;

  DateTime get _calculatedEndDate {
    return DateTime(
      _startDate.year,
      _startDate.month + _tenorMonths,
      _startDate.day,
    );
  }

  String get _calculatedEndDateFormatted {
    final d = _calculatedEndDate;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  double get _currentLtvRatio {
    if (_currentCollateralVal <= 0) return 0.0;
    return (_currentPrincipal / _currentCollateralVal) * 100.0;
  }

  void _updateBenchmarkRate() {
    if (_isEdit) return; // Không tự đè khi đang sửa hợp đồng cũ
    final rate = LoanMockData.getBenchmarkRate(
      _selectedBank,
      _selectedLoanType,
    );
    _rateController.text = rate
        .toStringAsFixed(1)
        .replaceAll(RegExp(r'\.0$'), '');
  }

  void _onTenorChanged(int newTenor) {
    setState(() {
      _tenorMonths = newTenor;
      _tenorController.text = newTenor.toString();
    });
  }

  String _formatAmountLabel(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(amount % 1000000000 == 0 ? 0 : 1)} Tỷ';
    }
    return '${(amount / 1000000).round()} Triệu';
  }

  Future<void> _selectStartDate() async {
    if (_isEdit) return; // Không cho phép đổi ngày giải ngân gốc của hợp đồng

    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate.isAfter(now) ? now : _startDate,
      firstDate: DateTime(2015),
      lastDate: now, // CHẶN CHỌN NGÀY TƯƠNG LAI
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Quy tắc thế chấp: Nếu là MORTGAGE bắt buộc phải có tài sản định giá
    if (_selectedLoanType == 'MORTGAGE') {
      final config = CollateralModel.getConfig(_selectedCollateralType);
      if (_collateralNameController.text.trim().isEmpty) {
        AppSnackBar.showError(
          context,
          'Vay thế chấp yêu cầu phải có thông tin tài sản đảm bảo.',
        );
        return;
      }
      if (_currentCollateralVal < config.minValue) {
        AppSnackBar.showError(
          context,
          'Giá trị định giá cho ${config.displayName} tối thiểu là ${config.minFormatted}.',
        );
        return;
      }
      if (_currentCollateralVal > config.maxValue) {
        AppSnackBar.showError(
          context,
          'Giá trị định giá cho ${config.displayName} tối đa là ${config.maxFormatted}.',
        );
        return;
      }
    }

    // Giới hạn số tiền vay
    if (_currentPrincipal < 5000000) {
      AppSnackBar.showError(
        context,
        'Số tiền vay tối thiểu là 5.000.000 VNĐ (5 triệu).',
      );
      return;
    }
    if (_currentPrincipal > 50000000000) {
      AppSnackBar.showError(
        context,
        'Số tiền vay tối đa là 50.000.000.000 VNĐ (50 tỷ).',
      );
      return;
    }

    // Ma trận sửa: Cảnh báo làm sai lệch lịch phân kỳ cũ
    if (_isEdit) {
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 24.0,
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Cảnh báo thay đổi tài chính',
                  style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Thay đổi các thông số kỳ hạn sẽ làm sai lệch lịch phân kỳ cũ. Bạn cần tính toán lại lịch trả nợ sau khi lưu.',
            style: TextStyle(
              fontSize: 14.0,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Xác nhận lưu'),
            ),
          ],
        ),
      );

      if (shouldSave != true) return;
    }

    final name = _nameController.text.trim();
    final principal = _currentPrincipal;
    final rate = _currentRate;
    final tenor = _tenorMonths;
    final startDateStr = _startDateController.text.trim();
    final methodStr = _selectedMethod == InterestMethod.reducingBalance
        ? 'Dư nợ giảm dần'
        : 'Dư nợ ban đầu';

    final payload = <String, dynamic>{
      'loan_name': name,
      'lender_name': _selectedBank,
      'loan_type': _selectedLoanType,
      'principal_amount': principal,
      'outstanding_amount': principal,
      'interest_rate': rate,
      'tenor_months': tenor,
      'start_date': startDateStr,
      'interest_method': methodStr,
      'status': 'ACTIVE',
    };

    if (_selectedLoanType == 'MORTGAGE') {
      payload['collateral_name'] = _collateralNameController.text.trim();
      payload['collateral_type'] = _selectedCollateralType;
      payload['collateral_value'] = _currentCollateralVal;
    }

    bool success = false;
    if (_isEdit && _loanIdToEdit != null) {
      success = await _loanController.updateLoan(_loanIdToEdit!, payload);
    } else {
      success = await _loanController.createLoan(payload);
    }

    if (mounted && success) {
      AppSnackBar.showSuccess(
        context,
        _isEdit
            ? 'Đã cập nhật khoản vay thành công!'
            : 'Đã tạo mới khoản vay thành công!',
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final benchmarkRate = LoanMockData.getBenchmarkRate(
      _selectedBank,
      _selectedLoanType,
    );
    final ltv = _currentLtvRatio;

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
        title: Text(
          _isEdit ? 'Chỉnh sửa khoản vay' : 'Thêm mới khoản vay',
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thẻ thông tin Hợp đồng nếu ở Edit mode
                if (_isEdit && _loanCodeToEdit != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 10.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 16.0,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'Mã hợp đồng: $_loanCodeToEdit (Cố định pháp lý)',
                          style: const TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                ],

                // 1. Tên khoản vay (Cho phép sửa ở cả 2 chế độ)
                AppTextField(
                  label: 'Tên khoản vay / Mục đích vay *',
                  hint: 'Ví dụ: Vay mua xe VinFast, Vay kinh doanh...',
                  controller: _nameController,
                  prefixIcon: const Icon(
                    Icons.description_outlined,
                    color: AppColors.primary,
                    size: 20.0,
                  ),
                  validator: AppValidators.validateLoanName,
                ),
                const SizedBox(height: 16.0),

                // 2. Đơn vị cho vay / Ngân hàng (Dropdown cố định, KHÔNG cho nhập tự do; KHÓA khi ở Edit Mode)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Ngân hàng / Đơn vị cấp tín dụng *',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_isEdit) ...[
                          const SizedBox(width: 6.0),
                          const Icon(
                            Icons.lock_outline,
                            size: 14.0,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    DropdownButtonFormField<String>(
                      initialValue:
                          LoanMockData.standardBanks.contains(_selectedBank)
                          ? _selectedBank
                          : LoanMockData.standardBanks.first,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _isEdit
                            ? const Color(0xFFF1F5F9)
                            : AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 14.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        prefixIcon: const Icon(
                          Icons.account_balance_outlined,
                          color: AppColors.primary,
                          size: 20.0,
                        ),
                      ),
                      items: LoanMockData.standardBanks.map((bank) {
                        return DropdownMenuItem<String>(
                          value: bank,
                          child: Text(
                            bank,
                            style: TextStyle(
                              color: _isEdit
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _isEdit
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedBank = val;
                                  _updateBenchmarkRate();
                                });
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // 3. Loại khoản vay (Cố định khi Edit)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Loại khoản vay *',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_isEdit) ...[
                          const SizedBox(width: 6.0),
                          const Icon(
                            Icons.lock_outline,
                            size: 14.0,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedLoanType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: _isEdit
                            ? const Color(0xFFF1F5F9)
                            : AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 14.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                          color: AppColors.primary,
                          size: 20.0,
                        ),
                      ),
                      items: LoanMockData.loanTypeLabels.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              color: _isEdit
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _isEdit
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedLoanType = val;
                                  _updateBenchmarkRate();
                                });
                              }
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // 4. Số tiền vay ban đầu
                AppTextField(
                  label: 'Số tiền vay ban đầu (VNĐ) *',
                  hint: 'Ví dụ: 300000000',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(
                    Icons.payments_outlined,
                    color: AppColors.primary,
                    size: 20.0,
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: AppValidators.validateLoanAmount,
                ),
                const SizedBox(height: 4.0),
                const Padding(
                  padding: EdgeInsets.only(left: 4.0),
                  child: Text(
                    'Hạn mức cho phép: 5.000.000 đ – 50.000.000.000 đ (50 tỷ VNĐ)',
                    style: TextStyle(
                      fontSize: 11.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: 8.0),
                  QuickChipSelector<double>(
                    items: _quickAmounts,
                    selectedItem: _quickAmounts.contains(_currentPrincipal)
                        ? _currentPrincipal
                        : null,
                    labelBuilder: (amt) => _formatAmountLabel(amt),
                    onSelected: (amt) {
                      setState(() {
                        _amountController.text = amt.round().toString();
                      });
                    },
                  ),
                ],
                const SizedBox(height: 18.0),

                // 5. Lãi suất (%/năm) - Tự động áp dụng theo ngân hàng & loại vay, cố định không cho sửa tay
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppColors.border),
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
                                Icons.percent_rounded,
                                color: AppColors.primary,
                                size: 18.0,
                              ),
                              SizedBox(width: 6.0),
                              Text(
                                'Lãi suất áp dụng *',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
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
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: AppColors.primaryLight.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            child: Text(
                              '${_currentRate.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}% / năm',
                              style: const TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            size: 14.0,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6.0),
                          Expanded(
                            child: Text(
                              _isEdit
                                  ? 'Lãi suất cố định theo hợp đồng đã ký. Không cho phép sửa đổi.'
                                  : 'Lãi suất được áp dụng tự động theo biểu niêm yết của $_selectedBank (${LoanMockData.loanTypeLabels[_selectedLoanType] ?? 'khoản vay'}: $benchmarkRate%/năm). Cố định theo quy định.',
                              style: const TextStyle(
                                fontSize: 12.0,
                                color: AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18.0),

                // 6. KỲ HẠN VAY (TWO-WAY BINDING: Slider + Presets + Input, MỞ CẢ KHI EDIT)
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kỳ hạn vay (tháng) *',
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              '$_tenorMonths tháng (${(_tenorMonths / 12).toStringAsFixed(_tenorMonths % 12 == 0 ? 0 : 1)} năm)',
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),

                      // Thanh trượt Slider tương tác mượt mà
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.border,
                          thumbColor: AppColors.primary,
                          trackHeight: 4.0,
                        ),
                        child: Slider(
                          value: _tenorMonths.clamp(6, 240).toDouble(),
                          min: 6,
                          max: 240,
                          divisions: 39, // bước nhảy 6 tháng
                          onChanged: (val) => _onTenorChanged(val.round()),
                        ),
                      ),

                      // Presets chọn nhanh
                      QuickChipSelector<int>(
                        items: _quickTenors,
                        selectedItem: _quickTenors.contains(_tenorMonths)
                            ? _tenorMonths
                            : null,
                        labelBuilder: (t) => '$t tháng',
                        onSelected: (t) => _onTenorChanged(t),
                      ),
                      const SizedBox(height: 10.0),

                      // Ngày đáo hạn tự động tính toán thời gian thực
                      Row(
                        children: [
                          const Icon(
                            Icons.event_available_rounded,
                            size: 15.0,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            'Ngày đáo hạn dự kiến: $_calculatedEndDateFormatted',
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18.0),

                // 7. Ngày giải ngân (KHÓA KHI EDIT, CHẶN CHỌN TƯƠNG LAI)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Ngày bắt đầu giải ngân *',
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_isEdit) ...[
                          const SizedBox(width: 6.0),
                          const Icon(
                            Icons.lock_outline,
                            size: 14.0,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    InkWell(
                      onTap: _isEdit ? null : _selectStartDate,
                      borderRadius: BorderRadius.circular(12.0),
                      child: IgnorePointer(
                        child: AppTextField(
                          label: '',
                          hint: 'DD/MM/YYYY',
                          controller: _startDateController,
                          prefixIcon: const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.primary,
                            size: 20.0,
                          ),
                          suffixIcon: _isEdit
                              ? const Icon(
                                  Icons.lock_outline,
                                  size: 18.0,
                                  color: AppColors.textSecondary,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18.0),

                // 8. KHỐI THẨM ĐỊNH TÀI SẢN & KIỂM SOÁT LTV (BẮT BUỘC NẾU VAY THẾ CHẤP)
                if (_selectedLoanType == 'MORTGAGE') ...[
                  Container(
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(
                        color: ltv > 85
                            ? AppColors.error
                            : (ltv > 70 ? AppColors.warning : AppColors.border),
                        width: ltv > 70 ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.shield_rounded,
                              color: AppColors.primary,
                              size: 18.0,
                            ),
                            SizedBox(width: 6.0),
                            Text(
                              'THẨM ĐỊNH TÀI SẢN BẢO ĐẢM (BẮT BUỘC)',
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCollateralType,
                          decoration: InputDecoration(
                            labelText: 'Loại tài sản bảo đảm *',
                            filled: true,
                            fillColor: AppColors.surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 14.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.shield_outlined,
                              color: AppColors.primary,
                              size: 20.0,
                            ),
                          ),
                          items: CollateralModel.typeConfigs.entries.map((e) {
                            return DropdownMenuItem<String>(
                              value: e.key,
                              child: Text(
                                e.value.displayName,
                                style: const TextStyle(fontSize: 13.5),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCollateralType = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12.0),
                        AppTextField(
                          label: 'Tên tài sản bảo đảm (Sổ đỏ, Xe ô tô...) *',
                          hint: 'Ví dụ: Sổ hồng Căn hộ Masteri Thảo Điền',
                          controller: _collateralNameController,
                          prefixIcon: const Icon(
                            Icons.apartment_rounded,
                            color: AppColors.primary,
                            size: 20.0,
                          ),
                          validator: (val) =>
                              AppValidators.validateCollateralName(
                                val,
                                required: _selectedLoanType == 'MORTGAGE',
                              ),
                        ),
                        const SizedBox(height: 12.0),
                        Builder(
                          builder: (context) {
                            final collateralConfig = CollateralModel.getConfig(
                              _selectedCollateralType,
                            );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppTextField(
                                  label:
                                      'Giá trị định giá ban đầu của ngân hàng (VNĐ) *',
                                  hint:
                                      'Theo Chứng thư định giá / Hợp đồng thế chấp',
                                  controller: _collateralValController,
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(
                                    Icons.assessment_outlined,
                                    color: AppColors.primary,
                                    size: 20.0,
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (val) =>
                                      AppValidators.validateCollateralValue(
                                        val,
                                        min: collateralConfig.minValue,
                                        max: collateralConfig.maxValue,
                                        displayName:
                                            collateralConfig.displayName,
                                        minFormatted:
                                            collateralConfig.minFormatted,
                                        maxFormatted:
                                            collateralConfig.maxFormatted,
                                        required:
                                            _selectedLoanType == 'MORTGAGE',
                                      ),
                                ),
                                const SizedBox(height: 4.0),
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: Text(
                                    'Hạn mức định giá cho ${collateralConfig.displayName}: ${collateralConfig.limitRangeText}',
                                    style: const TextStyle(
                                      fontSize: 11.0,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10.0),

                        // Cảnh báo chỉ số LTV
                        if (_currentCollateralVal > 0) ...[
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: ltv > 85
                                  ? AppColors.error.withValues(alpha: 0.1)
                                  : (ltv > 70
                                        ? AppColors.warning.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppColors.success.withValues(
                                            alpha: 0.1,
                                          )),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  ltv > 85
                                      ? Icons.dangerous_rounded
                                      : (ltv > 70
                                            ? Icons.warning_rounded
                                            : Icons.check_circle_rounded),
                                  size: 18.0,
                                  color: ltv > 85
                                      ? AppColors.error
                                      : (ltv > 70
                                            ? AppColors.warning
                                            : AppColors.success),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    ltv > 85
                                        ? 'CẢNH BÁO LTV: ${ltv.toStringAsFixed(1)}% vượt trần cho phép của ngân hàng (85%). Nguy cơ bị từ chối giải ngân!'
                                        : (ltv > 70
                                              ? 'CẢNH BÁO: Khoản vay vượt quá tỷ lệ giải ngân an toàn trên tài sản đảm bảo (LTV: ${ltv.toStringAsFixed(1)}% > 70%).'
                                              : 'Tỷ lệ LTV: ${ltv.toStringAsFixed(1)}% (Mức giải ngân an toàn theo chuẩn ngân hàng).'),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: ltv > 85
                                          ? AppColors.error
                                          : (ltv > 70
                                                ? const Color(0xFFB45309)
                                                : AppColors.success),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18.0),
                ],

                // 9. Phương thức tính lãi
                const Text(
                  'Phương thức tính lãi *',
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8.0),
                InterestMethodCard(
                  method: InterestMethod.reducingBalance,
                  selectedMethod: _selectedMethod,
                  onChanged: (m) => setState(() => _selectedMethod = m),
                ),
                const SizedBox(height: 8.0),
                InterestMethodCard(
                  method: InterestMethod.flatRate,
                  selectedMethod: _selectedMethod,
                  onChanged: (m) => setState(() => _selectedMethod = m),
                ),
                const SizedBox(height: 20.0),

                // 10. Thẻ ước tính thanh toán thời gian thực (MonthlyEstimateCard)
                if (_currentPrincipal > 0 && _tenorMonths > 0) ...[
                  MonthlyEstimateCard(
                    principal: _currentPrincipal,
                    annualInterestRate: _currentRate,
                    tenorMonths: _tenorMonths,
                    interestMethod: _selectedMethod,
                  ),
                  const SizedBox(height: 24.0),
                ],

                // 11. Nút Submit
                ListenableBuilder(
                  listenable: _loanController,
                  builder: (context, _) {
                    return AppPrimaryButton(
                      label: _isEdit
                          ? 'Lưu thay đổi khoản vay'
                          : 'Tạo khoản vay mới',
                      isLoading: _loanController.isLoading,
                      onPressed: _handleSubmit,
                    );
                  },
                ),
                const SizedBox(height: 30.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
