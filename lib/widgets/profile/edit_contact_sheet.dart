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
                'Thông tin liên hệ được sử dụng để gửi mã OTP xác thực và đối soát hồ sơ tín dụng.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20.0),
              AppTextField(
                label: 'Họ và tên',
                controller: _nameController,
                validator: AppValidators.validateFullName,
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
                label: 'Số CCCD gắn chip (12 số)',
                hint: 'Nhập 12 số CCCD',
                controller: _idCardController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(
                  Icons.badge_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                validator: (val) =>
                    AppValidators.validateIdCard(val, required: false),
              ),
              const SizedBox(height: 14.0),
              AppTextField(
                label: 'Địa chỉ thường trú / Nơi ở',
                hint: 'Số nhà, tên đường, phường/xã, quận/huyện, tỉnh/TP',
                controller: _addressController,
                prefixIcon: const Icon(
                  Icons.home_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                validator: (val) {
                  if (val != null &&
                      val.trim().isNotEmpty &&
                      val.trim().length < 5) {
                    return 'Địa chỉ cần chi tiết hơn (tối thiểu 5 ký tự)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              AppPrimaryButton(
                label: 'Lưu thay đổi',
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  widget.authController.updateCurrentUser(
                    fullName: _nameController.text.trim(),
                    phone: _phoneController.text.trim(),
                    idCardNumber: _idCardController.text.trim().isEmpty
                        ? null
                        : _idCardController.text.trim(),
                    address: _addressController.text.trim().isEmpty
                        ? null
                        : _addressController.text.trim(),
                  );
                  Navigator.pop(context);
                  AppSnackBar.showSuccess(
                    context,
                    'Đã cập nhật thông tin định danh & liên hệ thành công!',
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
