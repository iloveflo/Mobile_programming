import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/loan_controller.dart';
import '../../models/collateral_model.dart';
import '../../models/loan_model.dart';
import '../../routes/app_router.dart';
import '../../service_locator.dart';
import '../../services/image_upload_service.dart';
import '../../widgets/widget.dart';
import '../main_shell_screen.dart';

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
  CollateralModel? _selectedExistingCollateral;
  InterestMethod _selectedMethod = InterestMethod.reducingBalance;
  DateTime _startDate = DateTime.now();
  int _tenorMonths = 24;

  bool _isEdit = false;
  LoanModel? _editingLoan;
  String? _loanIdToEdit;
  String? _loanCodeToEdit;
  bool _connectionError = false;
  String? _connectionErrorMessage;
  bool _isSubmitting = false;

  bool get _hasPayments => _isEdit && (_editingLoan?.paidAmount ?? 0) > 0;

  List<CollateralModel> get _availableCollaterals {
    final list = _loanController.collaterals
        .where((c) => c.hasLegalDocument)
        .toList();
    final selected = _selectedExistingCollateral;
    if (selected != null && !list.any((c) => c.id == selected.id)) {
      list.insert(0, selected);
    }
    return list;
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

  String _formatRate(double rate) {
    return rate == rate.roundToDouble()
        ? rate.round().toString()
        : rate.toStringAsFixed(1);
  }

  final List<double> _quickAmounts = [
    50000000,
    100000000,
    300000000,
    500000000,
    1000000000,
  ];

  final List<int> _quickTenors = [12, 24, 36, 60, 120, 240];
  String? _collateralHintFromOcr;
  String? _prefilledContractFileKey;
  String? _prefilledLocalContractImagePath;

  bool get _requiresCollateral =>
      _selectedLoanType == 'MORTGAGE' ||
      _selectedLoanType == 'CAR' ||
      (_collateralHintFromOcr != null &&
          _collateralHintFromOcr!.trim().isNotEmpty);

  DateTime? _parsePrefilledDate(dynamic rawDate) {
    if (rawDate == null) return null;
    final text = rawDate.toString().trim();
    if (text.isEmpty) return null;
    final slashParts = RegExp(
      r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})$',
    ).firstMatch(text);
    if (slashParts != null) {
      final d = int.tryParse(slashParts.group(1)!);
      final m = int.tryParse(slashParts.group(2)!);
      final y = int.tryParse(slashParts.group(3)!);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }
    return DateTime.tryParse(text);
  }

  @override
  void initState() {
    super.initState();
    final loan = widget.initialLoan;
    final prefilled = widget.prefilledData;

    _isEdit = loan != null;
    _editingLoan = loan;
    _loanIdToEdit = loan?.id.toString();
    _loanCodeToEdit = loan?.loanCode;

    // Phân tích thông tin ngân hàng & loại khoản vay
    if (loan != null) {
      _selectedBank = LoanModel.standardBanks.contains(loan.lenderName)
          ? loan.lenderName
          : LoanModel.standardBanks.first;
      _selectedLoanType = loan.loanTypeKey;
      _tenorMonths = loan.tenorMonths;
      _startDate = loan.startDate;
    } else if (prefilled != null) {
      final lender =
          (prefilled['lender_name'] ?? prefilled['lender'])?.toString() ?? '';
      _selectedBank = LoanModel.standardBanks.contains(lender)
          ? lender
          : LoanModel.standardBanks.first;
      final type = prefilled['loan_type']?.toString();
      if (type != null && LoanModel.loanTypeLabels.containsKey(type)) {
        _selectedLoanType = type;
      } else {
        _selectedLoanType = 'MORTGAGE';
      }
      final parsedTenor =
          int.tryParse(
            (prefilled['tenor_months'] ?? prefilled['term_months'])
                    ?.toString() ??
                '24',
          ) ??
          24;
      _tenorMonths = parsedTenor.clamp(6, 240);
      final parsedStart = _parsePrefilledDate(prefilled['start_date']);
      if (parsedStart != null) {
        _startDate = parsedStart;
      }
      final hint = prefilled['collateral_hint']?.toString().trim();
      if (hint != null && hint.isNotEmpty) {
        _collateralHintFromOcr = hint;
      }
      final fileKey = prefilled['contract_file_key']?.toString().trim();
      if (fileKey != null && fileKey.isNotEmpty) {
        _prefilledContractFileKey = fileKey;
      }
      final localPath = prefilled['local_contract_image_path']
          ?.toString()
          .trim();
      if (localPath != null && localPath.isNotEmpty) {
        _prefilledLocalContractImagePath = localPath;
      }
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
      initialRate = LoanModel.getBenchmarkRate(
        _selectedBank,
        _selectedLoanType,
      );
    }
    _rateController = TextEditingController(text: _formatRate(initialRate));

    _tenorController = TextEditingController(text: _tenorMonths.toString());
    _startDateController = TextEditingController(
      text:
          '${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}',
    );

    _collateralNameController = TextEditingController(
      text: _collateralHintFromOcr ?? '',
    );
    _collateralValController = TextEditingController();

    if (loan != null &&
        (loan.interestMethod.contains('ban đầu') ||
            loan.interestMethod == 'FLAT')) {
      _selectedMethod = InterestMethod.flatRate;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadCollateralsForForm();
    });
  }

  Future<void> _preloadCollateralsForForm() async {
    if (_connectionError) {
      setState(() {
        _connectionError = false;
        _connectionErrorMessage = null;
      });
    }
    CollateralModel? linkedToLoan;
    if (_isEdit && _loanIdToEdit != null) {
      await _loanController.fetchCollaterals(_loanIdToEdit);
      if (!mounted) return;
      if (_loanController.errorMessage != null) {
        setState(() {
          _connectionError = true;
          _connectionErrorMessage = _loanController.errorMessage;
        });
        return;
      }
      if (_loanController.collaterals.isNotEmpty) {
        linkedToLoan = _loanController.collaterals.first;
      }
    }
    await _loanController.fetchCollaterals();
    if (!mounted) return;
    if (_loanController.errorMessage != null) {
      setState(() {
        _connectionError = true;
        _connectionErrorMessage = _loanController.errorMessage;
      });
      return;
    }

    final collaterals = _availableCollaterals;
    CollateralModel? matched = linkedToLoan;
    if (matched != null) {
      for (final c in collaterals) {
        if (c.id == matched!.id) {
          matched = c;
          break;
        }
      }
    } else if (_selectedExistingCollateral == null && collaterals.isNotEmpty) {
      final initialName = _collateralNameController.text.trim();
      if (initialName.isNotEmpty) {
        final lowerHint = initialName.toLowerCase();
        for (final c in collaterals) {
          final lowerName = c.name.toLowerCase();
          if (lowerName == lowerHint ||
              lowerName.contains(lowerHint) ||
              lowerHint.contains(lowerName)) {
            matched = c;
            break;
          }
        }
      }
    }
    if (matched != null) {
      final selectedMatched = matched;
      setState(() {
        _selectedExistingCollateral = selectedMatched;
        _collateralNameController.text = selectedMatched.name;
        _collateralValController.text = selectedMatched.value
            .round()
            .toString();
      });
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
          _editingLoan = loan;
          _loanIdToEdit = loan.id.toString();
          _loanCodeToEdit = loan.loanCode;
          _nameController.text = loan.loanName;
          _selectedBank = LoanModel.standardBanks.contains(loan.lenderName)
              ? loan.lenderName
              : LoanModel.standardBanks.first;
          _selectedLoanType = loan.loanTypeKey;
          _amountController.text = loan.principalAmount.round().toString();
          final r = loan.interestRatePercent;
          _rateController.text = _formatRate(r);
          _tenorMonths = loan.tenorMonths;
          _tenorController.text = _tenorMonths.toString();
          _startDate = loan.startDate;
          _startDateController.text = loan.startDateFormatted;
          if (loan.interestMethod.contains('ban đầu') ||
              loan.interestMethod == 'FLAT') {
            _selectedMethod = InterestMethod.flatRate;
          }
        });
        _preloadCollateralsForForm();
      } else if (prefilled != null) {
        setState(() {
          _nameController.text = prefilled['loan_name']?.toString() ?? '';
          final lender =
              (prefilled['lender_name'] ?? prefilled['lender'])?.toString() ??
              '';
          if (LoanModel.standardBanks.contains(lender)) {
            _selectedBank = lender;
          }
          final type = prefilled['loan_type']?.toString();
          if (type != null && LoanModel.loanTypeLabels.containsKey(type)) {
            _selectedLoanType = type;
          }
          _amountController.text =
              prefilled['principal_amount']?.toString() ?? '';
          final r =
              double.tryParse(
                prefilled['interest_rate']?.toString() ?? '8.5',
              ) ??
              8.5;
          _rateController.text = _formatRate(r <= 1.0 ? r * 100.0 : r);
          _tenorMonths =
              (int.tryParse(
                        (prefilled['tenor_months'] ?? prefilled['term_months'])
                                ?.toString() ??
                            '24',
                      ) ??
                      24)
                  .clamp(6, 240);
          _tenorController.text = _tenorMonths.toString();
          final parsedStart = _parsePrefilledDate(prefilled['start_date']);
          if (parsedStart != null) {
            _startDate = parsedStart;
            _startDateController.text =
                '${parsedStart.day.toString().padLeft(2, '0')}/${parsedStart.month.toString().padLeft(2, '0')}/${parsedStart.year}';
          } else if (prefilled['start_date'] != null) {
            _startDateController.text = prefilled['start_date'].toString();
          }
          final hint = prefilled['collateral_hint']?.toString().trim();
          if (hint != null && hint.isNotEmpty) {
            _collateralHintFromOcr = hint;
            if (_selectedExistingCollateral == null) {
              _collateralNameController.text = hint;
            }
          }
          final fileKey = prefilled['contract_file_key']?.toString().trim();
          if (fileKey != null && fileKey.isNotEmpty) {
            _prefilledContractFileKey = fileKey;
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
    final existingSecured = _isEdit
        ? 0.0
        : (_selectedExistingCollateral?.totalSecuredDebt ?? 0.0);
    return ((_currentPrincipal + existingSecured) / _currentCollateralVal) *
        100.0;
  }

  double get _currentMaxLtvPercent =>
      (_selectedExistingCollateral?.effectiveMaxLtv ??
          CollateralModel.maxLtvForType(
            _selectedLoanType == 'CAR' ? 'VEHICLE' : 'REAL_ESTATE',
          )) *
      100.0;

  void _updateBenchmarkRate() {
    if (_isEdit) return; // Không tự đè khi đang sửa hợp đồng cũ
    final rate = LoanModel.getBenchmarkRate(_selectedBank, _selectedLoanType);
    _rateController.text = _formatRate(rate);
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

  void _showQuickAddCollateralSheet() {
    QuickAddCollateralSheet.show(
      context,
      loanController: _loanController,
      onCollateralAdded: (created) {
        setState(() {
          _selectedExistingCollateral = created;
          _collateralNameController.text = created.name;
          _collateralValController.text = created.value.round().toString();
        });
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Nếu khoản vay đã phát sinh thanh toán -> chỉ gửi tên khoản vay & ngân hàng/tổ chức cho vay
    if (_hasPayments && _loanIdToEdit != null) {
      final success = await _loanController.updateLoan(_loanIdToEdit!, {
        'loan_name': _nameController.text.trim(),
        'lender_name': _selectedBank,
      });
      if (mounted && success) {
        AppSnackBar.showSuccess(
          context,
          'Đã cập nhật thông tin hành chính khoản vay thành công!',
        );
        Navigator.pop(context);
      } else if (mounted) {
        AppSnackBar.showError(
          context,
          _loanController.errorMessage ??
              'Không thể lưu khoản vay. Vui lòng kiểm tra lại thông tin.',
        );
      }
      return;
    }

    // Quy tắc thế chấp: Bắt buộc chọn tài sản bảo đảm từ danh mục tài sản hiện có của người dùng
    if (_requiresCollateral) {
      if (_selectedExistingCollateral == null) {
        AppSnackBar.showError(
          context,
          'Vui lòng chọn một tài sản thế chấp từ danh mục tài sản hiện có của bạn.',
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
      if (!mounted) return;
    }

    final name = _nameController.text.trim();
    final principal = _currentPrincipal;
    final rate = _currentRate;
    final tenor = _tenorMonths;
    final startDateStr =
        '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
    final methodCode = _selectedMethod == InterestMethod.reducingBalance
        ? 'REDUCING_BALANCE'
        : 'FLAT';

    final payload = <String, dynamic>{
      'loan_name': name,
      'lender_name': _selectedBank,
      'loan_type': _selectedLoanType,
      'loan_type_code': _selectedLoanType,
      'principal_amount': principal,
      'interest_rate': rate,
      'term_months': tenor,
      'start_date': startDateStr,
      'interest_method': methodCode,
      'interest_calculation_method': methodCode,
      'status': _isEdit ? (_editingLoan?.status ?? 'ACTIVE') : 'ACTIVE',
    };

    if (!_isEdit &&
        _prefilledContractFileKey != null &&
        _prefilledContractFileKey!.isNotEmpty) {
      payload['contract_file_key'] = _prefilledContractFileKey;
    }

    if (_requiresCollateral && _selectedExistingCollateral != null) {
      final maxLtvPct = _currentMaxLtvPercent;
      if (!_isEdit && _currentLtvRatio > maxLtvPct) {
        AppSnackBar.showError(
          context,
          'Tổng dư nợ bảo đảm (${_currentLtvRatio.toStringAsFixed(1)}%) vượt trần LTV tối đa ${maxLtvPct.round()}% cho loại tài sản này (Điều 296 BLDS 2015).',
        );
        return;
      }
      payload['collateral_id'] = _selectedExistingCollateral!.id;
      payload['collateral_name'] = _selectedExistingCollateral!.name;
      payload['collateral_type'] = _selectedExistingCollateral!.type;
      payload['collateral_value'] = _selectedExistingCollateral!.value;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      bool success = false;
      if (_isEdit && _loanIdToEdit != null) {
        success = await _loanController.updateLoan(_loanIdToEdit!, payload);
      } else {
        success = await _loanController.createLoan(payload);
      }

      if (mounted && success) {
        // Chỉ tải ảnh hợp đồng OCR lên R2 sau khi đã tạo khoản vay thành công
        if (!_isEdit &&
            _prefilledLocalContractImagePath != null &&
            _loanController.loans.isNotEmpty &&
            sl.isRegistered<ImageUploadService>()) {
          final newLoanId = _loanController.loans.first.id.toString();
          final uploadRes = await sl<ImageUploadService>().uploadPickedFile(
            XFile(_prefilledLocalContractImagePath!),
            folder: 'contracts',
            filePrefix: 'contract_loan_$newLoanId',
            isPublic: false,
            metadata: {'loan_id': newLoanId},
          );
          if (!uploadRes.isSuccess && mounted) {
            AppSnackBar.showError(
              context,
              'Đã tạo khoản vay, nhưng chưa tải được ảnh hợp đồng lên R2.',
            );
            Navigator.pop(context);
            return;
          }
        }
        if (!mounted) return;
        AppSnackBar.showSuccess(
          context,
          _isEdit
              ? 'Đã cập nhật khoản vay thành công!'
              : 'Đã tạo mới khoản vay thành công!',
        );
        Navigator.pop(context);
      } else if (mounted) {
        AppSnackBar.showError(
          context,
          _loanController.errorMessage ??
              'Không thể lưu khoản vay. Vui lòng kiểm tra lại thông tin.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  List<String> _getMissingProfileFields() {
    if (_isEdit || !sl.isRegistered<AuthController>()) return const [];
    final user = sl<AuthController>().currentUser;
    if (user == null) return const [];

    final missing = <String>[];
    if (!user.isEkycVerified) {
      missing.add('Xác thực định danh eKYC (chụp 2 mặt CCCD gắn chip)');
    }
    if (user.idCardNumber == null || user.idCardNumber!.trim().length != 12) {
      missing.add('Số CCCD gắn chip (12 chữ số)');
    }
    if (user.fullName.trim().isEmpty) {
      missing.add('Họ và tên theo CCCD');
    }
    if (user.dateOfBirth == null) {
      missing.add('Ngày sinh theo CCCD');
    }
    if (user.address == null || user.address!.trim().isEmpty) {
      missing.add('Địa chỉ thường trú theo CCCD');
    }
    if (user.phone == null || user.phone!.trim().isEmpty) {
      missing.add('Số điện thoại liên hệ');
    }
    if (user.monthlyIncome == null || user.monthlyIncome! <= 0) {
      missing.add('Thu nhập ròng hàng tháng');
    }
    return missing;
  }

  @override
  Widget build(BuildContext context) {
    final missingFields = _getMissingProfileFields();
    if (missingFields.isNotEmpty) {
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
            'Yêu cầu hoàn tất hồ sơ',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 64.0,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'Chưa đủ điều kiện tạo khoản vay',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Vui lòng cập nhật đầy đủ thông tin cá nhân và xác thực eKYC CCCD tại trang Hồ sơ cá nhân trước khi khởi tạo khoản vay mới:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.0,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: missingFields
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 16.0,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 24.0),
                AppPrimaryButton(
                  label: 'Đi tới Hồ sơ cá nhân',
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MainShellScreen(initialIndex: 4),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    final benchmarkRate = LoanModel.getBenchmarkRate(
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
        child: _connectionError
            ? ConnectionErrorView(
                message: _connectionErrorMessage,
                onRetry: _preloadCollateralsForForm,
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
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
                              Expanded(
                                child: Text(
                                  _hasPayments
                                      ? 'Mã hợp đồng: $_loanCodeToEdit (Đã có thanh toán — chỉ sửa tên khoản vay)'
                                      : 'Mã hợp đồng: $_loanCodeToEdit (Cố định pháp lý)',
                                  style: const TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
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
                              const Flexible(
                                child: Text(
                                  'Ngân hàng / Đơn vị cấp tín dụng *',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
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
                            isExpanded: true,
                            initialValue:
                                LoanModel.standardBanks.contains(_selectedBank)
                                ? _selectedBank
                                : LoanModel.standardBanks.first,
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
                                Icons.account_balance_outlined,
                                color: AppColors.primary,
                                size: 20.0,
                              ),
                            ),
                            items: LoanModel.standardBanks.map((bank) {
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
                              const Flexible(
                                child: Text(
                                  'Loại khoản vay *',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
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
                            isExpanded: true,
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
                                Icons.category_outlined,
                                color: AppColors.primary,
                                size: 20.0,
                              ),
                            ),
                            items: LoanModel.loanTypeLabels.entries.map((
                              entry,
                            ) {
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
                        enabled: !_hasPayments,
                        keyboardType: TextInputType.number,
                        prefixIcon: const Icon(
                          Icons.payments_outlined,
                          color: AppColors.primary,
                          size: 20.0,
                        ),
                        suffixIcon: _hasPayments
                            ? const Icon(
                                Icons.lock_outline,
                                size: 18.0,
                                color: AppColors.textSecondary,
                              )
                            : null,
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
                          selectedItem:
                              _quickAmounts.contains(_currentPrincipal)
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
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8.0,
                                runSpacing: 6.0,
                                children: [
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.percent_rounded,
                                        color: AppColors.primary,
                                        size: 18.0,
                                      ),
                                      SizedBox(width: 6.0),
                                      Flexible(
                                        child: Text(
                                          'Lãi suất áp dụng *',
                                          style: TextStyle(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
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
                                        color: AppColors.primaryLight
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Text(
                                      '${_formatRate(_currentRate)}% / năm',
                                      style: const TextStyle(
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                                        : 'Lãi suất được áp dụng tự động theo biểu niêm yết của $_selectedBank (${LoanModel.loanTypeLabels[_selectedLoanType] ?? 'khoản vay'}: $benchmarkRate%/năm). Cố định theo quy định.',
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
                            SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8.0,
                                runSpacing: 6.0,
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
                                onChanged: _hasPayments
                                    ? null
                                    : (val) => _onTenorChanged(val.round()),
                              ),
                            ),

                            // Presets chọn nhanh
                            if (!_hasPayments)
                              QuickChipSelector<int>(
                                items: _quickTenors,
                                selectedItem:
                                    _quickTenors.contains(_tenorMonths)
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
                                Expanded(
                                  child: Text(
                                    'Ngày đáo hạn dự kiến: $_calculatedEndDateFormatted',
                                    style: const TextStyle(
                                      fontSize: 12.0,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
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
                              const Flexible(
                                child: Text(
                                  'Ngày bắt đầu giải ngân *',
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
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
                            onTap: _hasPayments ? null : _selectStartDate,
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
                                suffixIcon: _hasPayments
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

                      // 8. KHỐI THẨM ĐỊNH TÀI SẢN & KIỂM SOÁT LTV (ÁP DỤNG CHO VAY THẾ CHẤP, VAY MUA XE & HỢP ĐỒNG CÓ TÀI SẢN BẢO ĐẢM)
                      if (_requiresCollateral) ...[
                        ListenableBuilder(
                          listenable: _loanController,
                          builder: (context, _) {
                            final collaterals = _availableCollaterals;
                            final isCollateralEmpty = collaterals.isEmpty;

                            // Đảm bảo id đang chọn còn tồn tại trong danh mục thực tế
                            final int? selectedId =
                                collaterals.any(
                                  (c) =>
                                      c.id == _selectedExistingCollateral?.id,
                                )
                                ? _selectedExistingCollateral?.id
                                : null;

                            return Container(
                              padding: const EdgeInsets.all(14.0),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14.0),
                                border: Border.all(
                                  color: ltv > 85
                                      ? AppColors.error
                                      : (ltv > 70
                                            ? AppColors.warning
                                            : AppColors.border),
                                  width: ltv > 70 ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Expanded(
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.shield_rounded,
                                              color: AppColors.primary,
                                              size: 18.0,
                                            ),
                                            SizedBox(width: 6.0),
                                            Expanded(
                                              child: Text(
                                                'THẨM ĐỊNH TÀI SẢN THẾ CHẤP',
                                                style: TextStyle(
                                                  fontSize: 12.0,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                  letterSpacing: 0.5,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isCollateralEmpty &&
                                          !_hasPayments) ...[
                                        const SizedBox(width: 8.0),
                                        TextButton.icon(
                                          style: TextButton.styleFrom(
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0,
                                            ),
                                          ),
                                          onPressed:
                                              _showQuickAddCollateralSheet,
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 14.0,
                                          ),
                                          label: const Text(
                                            'Thêm mới',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6.0),
                                  const Text(
                                    'Chọn tài sản bảo đảm đã được ngân hàng định giá trong danh mục tài sản cá nhân của bạn:',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12.0),

                                  if (isCollateralEmpty) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20.0,
                                        horizontal: 16.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(
                                          12.0,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFE2E8F0),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10.0),
                                            decoration: BoxDecoration(
                                              color: AppColors.primarySoft,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.real_estate_agent_outlined,
                                              size: 28.0,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(height: 10.0),
                                          const Text(
                                            'Chưa có tài sản bảo đảm trong danh mục',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          const Text(
                                            'Khoản vay thế chấp yêu cầu phải có tài sản bảo đảm đã được định giá. Hãy đăng ký tài sản của bạn để tiếp tục.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.textSecondary,
                                              height: 1.35,
                                            ),
                                          ),
                                          const SizedBox(height: 14.0),
                                          ElevatedButton.icon(
                                            onPressed:
                                                _showQuickAddCollateralSheet,
                                            icon: const Icon(
                                              Icons.add_rounded,
                                              size: 16.0,
                                            ),
                                            label: const Text(
                                              'Đăng ký tài sản thế chấp',
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.primary,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16.0,
                                                    vertical: 10.0,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              elevation: 0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    if (_collateralHintFromOcr != null &&
                                        _selectedExistingCollateral ==
                                            null) ...[
                                      Container(
                                        width: double.infinity,
                                        margin: const EdgeInsets.only(
                                          bottom: 10.0,
                                        ),
                                        padding: const EdgeInsets.all(10.0),
                                        decoration: BoxDecoration(
                                          color: AppColors.primarySoft,
                                          borderRadius: BorderRadius.circular(
                                            10.0,
                                          ),
                                          border: Border.all(
                                            color: AppColors.primaryLight
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.document_scanner_outlined,
                                              size: 16.0,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 8.0),
                                            Expanded(
                                              child: Text(
                                                'OCR hợp đồng phát hiện tài sản: "$_collateralHintFromOcr". Hãy chọn tài sản đã xác thực bên dưới hoặc bấm "Đăng ký tài sản mới" để quét giấy tờ chính chủ.',
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppColors.primary,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    DropdownButtonFormField<int>(
                                      isExpanded: true,
                                      initialValue: selectedId,
                                      decoration: InputDecoration(
                                        labelText: 'Chọn tài sản thế chấp *',
                                        hintText:
                                            '-- Chọn từ tài sản hiện có --',
                                        filled: true,
                                        fillColor: AppColors.surface,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 14.0,
                                              vertical: 12.0,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.0,
                                          ),
                                          borderSide: const BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.real_estate_agent_outlined,
                                          color: AppColors.primary,
                                          size: 20.0,
                                        ),
                                      ),
                                      selectedItemBuilder: (context) {
                                        return collaterals.map((c) {
                                          return Align(
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              c.name,
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          );
                                        }).toList();
                                      },
                                      items: collaterals.map((c) {
                                        return DropdownMenuItem<int>(
                                          value: c.id,
                                          child: Text(
                                            '${c.name} (${_formatCurrency(c.value)})',
                                            style: const TextStyle(
                                              fontSize: 13.0,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: _hasPayments
                                          ? null
                                          : (val) {
                                              if (val != null) {
                                                final matched = collaterals
                                                    .firstWhere(
                                                      (c) => c.id == val,
                                                    );
                                                setState(() {
                                                  _selectedExistingCollateral =
                                                      matched;
                                                  _collateralNameController
                                                          .text =
                                                      matched.name;
                                                  _collateralValController
                                                      .text = matched.value
                                                      .round()
                                                      .toString();
                                                });
                                              }
                                            },
                                      validator: (val) {
                                        if (_hasPayments) return null;
                                        if (_requiresCollateral &&
                                            _selectedExistingCollateral ==
                                                null) {
                                          return 'Vui lòng chọn một tài sản từ danh mục hiện có';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 8.0),
                                    SizedBox(
                                      width: double.infinity,
                                      child: Wrap(
                                        alignment: WrapAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 6.0,
                                        runSpacing: 4.0,
                                        children: [
                                          const Text(
                                            'Cần thêm tài sản khác?',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8.0,
                                                  ),
                                            ),
                                            onPressed:
                                                _showQuickAddCollateralSheet,
                                            icon: const Icon(
                                              Icons.add_circle_outline,
                                              size: 14.0,
                                            ),
                                            label: const Text(
                                              'Đăng ký tài sản mới',
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (_selectedExistingCollateral != null) ...[
                                    const SizedBox(height: 10.0),
                                    Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySoft.withValues(
                                          alpha: 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          10.0,
                                        ),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 3.0,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        6.0,
                                                      ),
                                                ),
                                                child: Text(
                                                  _selectedExistingCollateral!
                                                      .typeDisplay,
                                                  style: const TextStyle(
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                'Định giá: ${_selectedExistingCollateral!.valuationDateFormatted}',
                                                style: const TextStyle(
                                                  fontSize: 11.0,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            _selectedExistingCollateral!.name,
                                            style: const TextStyle(
                                              fontSize: 14.0,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4.0),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Giá trị thẩm định ngân hàng:',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              Text(
                                                _formatCurrency(
                                                  _selectedExistingCollateral!
                                                      .value,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 14.0,
                                                  fontWeight: FontWeight.w800,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8.0),
                                          if (_selectedExistingCollateral!
                                              .hasLegalDocument)
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  side: const BorderSide(
                                                    color: AppColors.primary,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.0,
                                                        ),
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 6.0,
                                                      ),
                                                ),
                                                onPressed: () {
                                                  AppDocumentViewerModal.show(
                                                    context,
                                                    title:
                                                        'Hồ sơ pháp lý: ${_selectedExistingCollateral!.name}',
                                                    fileKey:
                                                        _selectedExistingCollateral!
                                                            .legalDocumentUrl!,
                                                    documentType:
                                                        'Giấy chứng nhận tài sản bảo đảm',
                                                    ocrDetails: {
                                                      'asset_name':
                                                          _selectedExistingCollateral!
                                                              .name,
                                                      'loai_tai_san':
                                                          _selectedExistingCollateral!
                                                              .typeDisplay,
                                                      'valuation_amount':
                                                          _selectedExistingCollateral!
                                                              .value,
                                                      'ngay_dinh_gia':
                                                          _selectedExistingCollateral!
                                                              .valuationDateFormatted,
                                                    },
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.visibility_outlined,
                                                  size: 14.0,
                                                ),
                                                label: const Text(
                                                  'Xem giấy tờ pháp lý tài sản',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            )
                                          else
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10.0,
                                                    vertical: 8.0,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFEF3C7),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFFDE68A,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.info_outline,
                                                    size: 16.0,
                                                    color: Color(0xFFD97706),
                                                  ),
                                                  const SizedBox(width: 8.0),
                                                  const Expanded(
                                                    child: Text(
                                                      'Chưa có giấy tờ pháp lý số hóa',
                                                      style: TextStyle(
                                                        fontSize: 11.5,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFF92400E,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton.icon(
                                                    style: TextButton.styleFrom(
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6.0,
                                                          ),
                                                    ),
                                                    onPressed: () {
                                                      Navigator.pushNamed(
                                                        context,
                                                        AppRouter
                                                            .loanCollateralOcr,
                                                      ).then((_) {
                                                        _loanController
                                                            .fetchCollaterals();
                                                      });
                                                    },
                                                    icon: const Icon(
                                                      Icons.upload_file,
                                                      size: 14.0,
                                                    ),
                                                    label: const Text(
                                                      'Tải lên',
                                                      style: TextStyle(
                                                        fontSize: 11.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10.0),

                                  // Cảnh báo chỉ số LTV theo loại tài sản (TT 39/2016/TT-NHNN & Điều 296 BLDS 2015)
                                  if (_currentCollateralVal > 0) ...[
                                    Builder(
                                      builder: (context) {
                                        final maxLtvPct = _currentMaxLtvPercent;
                                        final isOverCap = ltv > maxLtvPct;
                                        final isWarning =
                                            ltv > 70 && !isOverCap;
                                        final badgeColor = isOverCap
                                            ? AppColors.error
                                            : (isWarning
                                                  ? AppColors.warning
                                                  : AppColors.success);
                                        return Container(
                                          padding: const EdgeInsets.all(10.0),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isOverCap
                                                    ? Icons.dangerous_rounded
                                                    : (isWarning
                                                          ? Icons
                                                                .warning_rounded
                                                          : Icons
                                                                .check_circle_rounded),
                                                size: 18.0,
                                                color: badgeColor,
                                              ),
                                              const SizedBox(width: 8.0),
                                              Expanded(
                                                child: Text(
                                                  isOverCap
                                                      ? 'VƯỢT TRẦN LTV: Tổng dư nợ bảo đảm ${ltv.toStringAsFixed(1)}% vượt giới hạn tối đa ${maxLtvPct.round()}% của loại tài sản này!'
                                                      : (isWarning
                                                            ? 'CẢNH BÁO: Tỷ lệ LTV ${ltv.toStringAsFixed(1)}% (trần tối đa ${maxLtvPct.round()}%).'
                                                            : 'Tỷ lệ LTV: ${ltv.toStringAsFixed(1)}% / tối đa ${maxLtvPct.round()}% (An toàn theo chuẩn ngân hàng VN).'),
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w600,
                                                    color: isWarning
                                                        ? const Color(
                                                            0xFFB45309,
                                                          )
                                                        : badgeColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
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
                        onChanged: _hasPayments
                            ? (_) {}
                            : (m) => setState(() => _selectedMethod = m),
                      ),
                      const SizedBox(height: 8.0),
                      InterestMethodCard(
                        method: InterestMethod.flatRate,
                        selectedMethod: _selectedMethod,
                        onChanged: _hasPayments
                            ? (_) {}
                            : (m) => setState(() => _selectedMethod = m),
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
                            isLoading:
                                _isSubmitting || _loanController.isLoading,
                            onPressed: _isSubmitting ? null : _handleSubmit,
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
