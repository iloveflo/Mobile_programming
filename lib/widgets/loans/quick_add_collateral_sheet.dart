import 'package:flutter/material.dart';

import '../../controllers/loan_controller.dart';
import '../../models/collateral_model.dart';
import '../widget.dart';

/// Modal BottomSheet thêm nhanh tài sản bảo đảm trong quá trình tạo khoản vay
class QuickAddCollateralSheet extends StatefulWidget {
  final LoanController loanController;
  final ValueChanged<CollateralModel> onCollateralAdded;

  const QuickAddCollateralSheet({
    super.key,
    required this.loanController,
    required this.onCollateralAdded,
  });

  /// Phương thức hiển thị modal
  static Future<void> show(
    BuildContext context, {
    required LoanController loanController,
    required ValueChanged<CollateralModel> onCollateralAdded,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => QuickAddCollateralSheet(
        loanController: loanController,
        onCollateralAdded: onCollateralAdded,
      ),
    );
  }

  @override
  State<QuickAddCollateralSheet> createState() =>
      _QuickAddCollateralSheetState();
}

class _QuickAddCollateralSheetState extends State<QuickAddCollateralSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _valCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedType = 'REAL_ESTATE';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valCtrl.dispose();
    _descCtrl.dispose();
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

  @override
  Widget build(BuildContext context) {
    final config =
        CollateralModel.typeConfigs[_selectedType] ??
        CollateralModel.typeConfigs['REAL_ESTATE']!;

    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Icon(
                      Icons.add_home_work_rounded,
                      color: AppColors.primary,
                      size: 22.0,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Đăng ký tài sản bảo đảm mới',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Định giá ngay để nâng hạn mức tín dụng',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18.0),

              // Loại tài sản
              const Text(
                'Loại tài sản',
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6.0),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                items: CollateralModel.typeConfigs.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value.displayName),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
                  }
                },
              ),
              const SizedBox(height: 14.0),

              // Tên tài sản
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Tên / Mã nhận dạng tài sản',
                  hintText: 'Ví dụ: Sổ hồng căn hộ Landmark 81',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  prefixIcon: const Icon(
                    Icons.drive_file_rename_outline,
                    size: 20.0,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên tài sản';
                  }
                  if (val.trim().length < 3) {
                    return 'Tên tài sản quá ngắn (tối thiểu 3 ký tự)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14.0),

              // Giá trị ước tính
              TextFormField(
                controller: _valCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Giá trị định giá ước tính (VNĐ)',
                  hintText: 'Ví dụ: 2500000000',
                  helperText:
                      'Hạn mức ${config.displayName}: ${config.limitRangeText}',
                  helperMaxLines: 2,
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  prefixIcon: const Icon(
                    Icons.monetization_on_outlined,
                    size: 20.0,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập giá trị định giá';
                  }
                  final numVal = double.tryParse(
                    val.replaceAll('.', '').replaceAll(',', ''),
                  );
                  if (numVal == null) {
                    return 'Giá trị định giá không hợp lệ';
                  }
                  if (numVal < config.minValue) {
                    return 'Định giá tối thiểu là ${config.minFormatted}';
                  }
                  if (numVal > config.maxValue) {
                    return 'Định giá tối đa là ${config.maxFormatted}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14.0),

              // Mô tả
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Mô tả chi tiết tài sản (tùy chọn)',
                  hintText:
                      'Ví dụ: Cavet xe chính chủ, thế chấp giải ngân khoản vay...',
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 12.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  prefixIcon: const Icon(Icons.notes_rounded, size: 20.0),
                ),
              ),
              const SizedBox(height: 20.0),

              // Nút xác nhận lưu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          final rawVal = _valCtrl.text
                              .replaceAll('.', '')
                              .replaceAll(',', '');
                          final val = double.tryParse(rawVal) ?? 0.0;
                          final name = _nameCtrl.text.trim();
                          final desc = _descCtrl.text.trim();

                          setState(() => _isLoading = true);

                          final success = await widget.loanController
                              .addCollateral(
                                name: name,
                                type: _selectedType,
                                value: val,
                                description: desc.isNotEmpty ? desc : null,
                              );

                          if (!context.mounted) return;
                          setState(() => _isLoading = false);

                          if (success &&
                              widget.loanController.collaterals.isNotEmpty) {
                            final created =
                                widget.loanController.collaterals.first;
                            Navigator.pop(context);
                            widget.onCollateralAdded(created);
                            AppSnackBar.showSuccess(
                              context,
                              'Đã đăng ký tài sản "$name" (${_formatCurrency(val)}) thành công!',
                            );
                          } else {
                            AppSnackBar.showError(
                              context,
                              widget.loanController.errorMessage ??
                                  'Không thể thêm tài sản.',
                            );
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(
                          height: 20.0,
                          width: 20.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Lưu & Sử dụng tài sản này',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
