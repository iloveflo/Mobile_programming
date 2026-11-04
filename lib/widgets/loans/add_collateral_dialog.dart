import 'package:flutter/material.dart';

import '../../controllers/loan_controller.dart';
import '../../models/collateral_model.dart';
import '../widget.dart';

/// Hộp thoại thêm mới tài sản bảo đảm (Collateral)
class AddCollateralDialog extends StatefulWidget {
  final LoanController loanController;
  final String? loanId;

  const AddCollateralDialog({
    super.key,
    required this.loanController,
    this.loanId,
  });

  /// Phương thức hiển thị dialog
  static Future<void> show(
    BuildContext context, {
    required LoanController loanController,
    String? loanId,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) =>
          AddCollateralDialog(loanController: loanController, loanId: loanId),
    );
  }

  @override
  State<AddCollateralDialog> createState() => _AddCollateralDialogState();
}

class _AddCollateralDialogState extends State<AddCollateralDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _valCtrl = TextEditingController();
  String _type = 'REAL_ESTATE';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valCtrl.dispose();
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
    final config = CollateralModel.getConfig(_type);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      title: const Text(
        'Thêm tài sản bảo đảm',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên tài sản (ví dụ: Sổ đỏ Chung cư Times City) *',
                ),
                validator: AppValidators.validateCollateralName,
              ),
              const SizedBox(height: 12.0),
              DropdownButtonFormField<String>(
                initialValue: _type,
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
                  if (val != null) setState(() => _type = val);
                },
              ),
              const SizedBox(height: 12.0),
              TextFormField(
                controller: _valCtrl,
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  final rawVal = _valCtrl.text
                      .replaceAll('.', '')
                      .replaceAll(',', '')
                      .trim();
                  final val = double.tryParse(rawVal) ?? 0.0;
                  final name = _nameCtrl.text.trim();

                  setState(() => _isLoading = true);
                  final success = await widget.loanController.addCollateral(
                    name: name,
                    type: _type,
                    value: val,
                    loanId: widget.loanId,
                  );

                  if (!context.mounted) return;
                  setState(() => _isLoading = false);

                  if (success) {
                    Navigator.pop(context);
                    AppSnackBar.showSuccess(
                      context,
                      'Đã ghi nhận tài sản "$name" (${_formatCurrency(val)}) thành công!',
                    );
                  } else {
                    AppSnackBar.showError(
                      context,
                      widget.loanController.errorMessage ??
                          'Không thể thêm tài sản.',
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16.0,
                  width: 16.0,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Thêm'),
        ),
      ],
    );
  }
}
