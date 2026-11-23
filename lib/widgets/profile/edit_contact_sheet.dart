import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../widget.dart';

/// Modal BottomSheet chỉnh sửa thông tin định danh & liên hệ
class EditContactSheet extends StatefulWidget {
  final AuthController authController;
  final UserModel? user;

  const EditContactSheet({super.key, required this.authController, this.user});

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
          EditContactSheet(authController: authController, user: user),
    );
  }

  @override
  State<EditContactSheet> createState() => _EditContactSheetState();
}

class _EditContactSheetState extends State<EditContactSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _idCardController;
  late final TextEditingController _addressController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.fullName ?? '');
    _phoneController = TextEditingController(text: widget.user?.phone ?? '');
    _idCardController = TextEditingController(
      text: widget.user?.idCardNumber ?? '',
    );
    _addressController = TextEditingController(
      text: widget.user?.address ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idCardController.dispose();
    _addressController.dispose();
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
              const Text(
                'Cập nhật thông tin định danh & liên hệ',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6.0),
              const Text(
                'Thông tin trên CCCD (Họ tên, Số CCCD, Ngày sinh, Địa chỉ thường trú) được đồng bộ tự động qua Quét & Xác thực eKYC, không thể sửa thủ công.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primary,
                      size: 18.0,
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        (widget.user?.isEkycVerified ?? false)
                            ? 'Dữ liệu CCCD đã được khóa bảo mật theo chuẩn C06.'
                            : 'Vui lòng thực hiện định danh eKYC để tự động điền thông tin từ CCCD.',
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!(widget.user?.isEkycVerified ?? false))
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          EkycVerificationSheet.show(
                            context,
                            authController: widget.authController,
                            user: widget.user,
                          );
                        },
                        child: const Text('Quét CCCD'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              AppTextField(
                label: 'Họ và tên (Theo CCCD)',
                controller: _nameController,
                enabled: false,
              ),
              const SizedBox(height: 14.0),
              AppTextField(
                label: 'Số điện thoại',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: AppValidators.validatePhone,
              ),
              const SizedBox(height: 14.0),
              AppTextField(
                label: 'Số CCCD gắn chip (Theo CCCD)',
                hint: 'Cập nhật qua định danh eKYC',
                controller: _idCardController,
                enabled: false,
                prefixIcon: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 14.0),
              AppTextField(
                label: 'Địa chỉ thường trú (Theo CCCD)',
                hint: 'Cập nhật qua định danh eKYC',
                controller: _addressController,
                enabled: false,
                prefixIcon: const Icon(
                  Icons.home_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 24.0),
              AppPrimaryButton(
                label: 'Lưu số điện thoại',
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  widget.authController.updateCurrentUser(
                    phone: _phoneController.text.trim(),
                  );
                  Navigator.pop(context);
                  AppSnackBar.showSuccess(
                    context,
                    'Đã cập nhật số điện thoại liên hệ thành công!',
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
