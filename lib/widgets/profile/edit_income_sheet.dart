import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../widget.dart';

/// Modal BottomSheet cập nhật năng lực tài chính, thu nhập & nghề nghiệp
class EditIncomeSheet extends StatefulWidget {
  final AuthController authController;
  final UserModel? user;

  const EditIncomeSheet({super.key, required this.authController, this.user});

  /// Phương thức hiển thị modal tiện ích
  static Future<void> show(
    BuildContext context, {
    required AuthController authController,
    UserModel? user,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) =>
          EditIncomeSheet(authController: authController, user: user),
    );
  }

  @override
  State<EditIncomeSheet> createState() => _EditIncomeSheetState();
}

class _EditIncomeSheetState extends State<EditIncomeSheet> {
  late final TextEditingController _incomeController;
  late final TextEditingController _occupationController;
  late final TextEditingController _workplaceController;
  late final TextEditingController _contractTypeController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _incomeController = TextEditingController(
      text: user?.monthlyIncome != null && user!.monthlyIncome! > 0
          ? user.monthlyIncome!.round().toString()
          : '',
    );
    _occupationController = TextEditingController(text: user?.occupation ?? '');
    _workplaceController = TextEditingController(text: user?.workplace ?? '');
    _contractTypeController = TextEditingController(
      text: user?.contractType ?? '',
    );
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _occupationController.dispose();
    _workplaceController.dispose();
    _contractTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              const Row(
                children: [
                  Icon(Icons.payments_rounded, color: AppColors.primary),
                  SizedBox(width: 8.0),
                  Text(
                    'Năng lực tài chính & Thu nhập',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6.0),
              const Text(
                'Thu nhập thực tế là căn cứ quan trọng để thẩm định tỷ lệ DTI và hạn mức vay tối đa của bạn.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20.0),
              AppTextField(
                label: 'Thu nhập hàng tháng (VNĐ)',
                hint: 'Ví dụ: 25000000',
                controller: _incomeController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(
                  Icons.payments_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                validator: (val) =>
                    AppValidators.validateMonthlyIncome(val, required: false),
              ),
              const SizedBox(height: 14.0),
              AppTextField(
                label: 'Vị trí công việc / Nghề nghiệp',
                hint: 'Ví dụ: Kỹ sư Phần mềm Senior',
                controller: _occupationController,
                validator: (val) {
                  if (val != null &&
                      val.trim().isNotEmpty &&
                      val.trim().length < 2) {
                    return 'Vị trí công việc quá ngắn';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14.0),
              AppTextField(
                label: 'Cơ quan / Đơn vị công tác',
                hint: 'Ví dụ: Tập đoàn Công nghệ FPT',
                controller: _workplaceController,
                validator: (val) {
                  if (val != null &&
                      val.trim().isNotEmpty &&
                      val.trim().length < 2) {
                    return 'Tên cơ quan/đơn vị quá ngắn';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14.0),
              AppTextField(
                label: 'Loại hợp đồng lao động',
                hint: 'Ví dụ: Hợp đồng không xác định thời hạn',
                controller: _contractTypeController,
              ),
              const SizedBox(height: 24.0),
              AppPrimaryButton(
                label: 'Xác nhận cập nhật thu nhập',
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  final rawIncome = _incomeController.text.trim();
                  final newIncome = rawIncome.isNotEmpty
                      ? double.tryParse(rawIncome)
                      : null;
                  widget.authController.updateCurrentUser(
                    monthlyIncome: newIncome,
                    occupation: _occupationController.text.trim().isEmpty
                        ? null
                        : _occupationController.text.trim(),
                    workplace: _workplaceController.text.trim().isEmpty
                        ? null
                        : _workplaceController.text.trim(),
                    contractType: _contractTypeController.text.trim().isEmpty
                        ? null
                        : _contractTypeController.text.trim(),
                  );
                  Navigator.pop(context);
                  AppSnackBar.showSuccess(
                    context,
                    'Đã cập nhật hồ sơ năng lực tài chính thành công!',
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
