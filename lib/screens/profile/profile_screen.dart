import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/loan_controller.dart';
import '../../models/bank_account_model.dart';
import '../../models/user_model.dart';
import '../../routes/app_router.dart';
import '../../screens/main_shell_screen.dart';
import '../../service_locator.dart';
import '../../widgets/widget.dart';

/// Màn hình Quản lý Hồ sơ Cá nhân & Năng lực Tài chính (ProfileScreen)
/// Thiết kế chuẩn FinTech không hardcode dữ liệu: Mọi thông tin phản ánh trực tiếp
/// từ UserModel & LoanController, sẵn sàng kết nối API Backend thực tế.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Tiện ích format tiền tệ VNĐ
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

  // Tiện ích che bảo mật số CCCD: 0792 0100 ****
  String _maskIdCard(String idCard) {
    final clean = idCard.replaceAll(' ', '');
    if (clean.length < 8) {
      return idCard;
    }
    final firstPart = clean.substring(0, 4);
    final midPart = clean.substring(4, clean.length >= 8 ? 8 : clean.length);
    return '$firstPart $midPart ****';
  }

  // Tiện ích che số tài khoản: •••• 8888
  String _maskAccountNumber(String accountNum) {
    final clean = accountNum.replaceAll(' ', '');
    if (clean.length <= 4) {
      return clean;
    }
    final last4 = clean.substring(clean.length - 4);
    return '•••• $last4';
  }

  // ================= 1. Modal Đổi Mật Khẩu =================
  void _showChangePasswordBottomSheet(
    BuildContext context,
    AuthController authController,
  ) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String passwordValue = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 20.0,
                bottom:
                    MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24.0,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Thanh gạt modal
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
                        'Đổi mật khẩu tài khoản',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      const Text(
                        'Mật khẩu mới cần đáp ứng tiêu chuẩn an toàn bảo mật FinCredit.',
                        style: TextStyle(
                          fontSize: 13.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // Mật khẩu hiện tại
                      AppTextField(
                        label: 'Mật khẩu hiện tại',
                        hint: 'Nhập mật khẩu hiện tại',
                        controller: currentPasswordController,
                        isPassword: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Vui lòng nhập mật khẩu hiện tại';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Mật khẩu mới
                      AppTextField(
                        label: 'Mật khẩu mới',
                        hint: 'Tối thiểu 8 ký tự, gồm chữ cái & chữ số',
                        controller: newPasswordController,
                        isPassword: true,
                        onChanged: (val) {
                          setSheetState(() {
                            passwordValue = val;
                          });
                        },
                        validator: (val) {
                          final err = AppValidators.validatePassword(val);
                          if (err != null) return err;
                          if (val == currentPasswordController.text) {
                            return 'Mật khẩu mới không được trùng mật khẩu hiện tại';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 6.0),
                      PasswordStrengthMeter(password: passwordValue),
                      const SizedBox(height: 16.0),

                      // Xác nhận mật khẩu mới
                      AppTextField(
                        label: 'Xác nhận mật khẩu mới',
                        hint: 'Nhập lại mật khẩu mới',
                        controller: confirmPasswordController,
                        isPassword: true,
                        validator: (val) =>
                            AppValidators.validateConfirmPassword(
                              val,
                              newPasswordController.text,
                            ),
                      ),
                      const SizedBox(height: 24.0),

                      // Nút xác nhận đổi mật khẩu
                      AppPrimaryButton(
                        label: 'Xác nhận đổi mật khẩu',
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          Navigator.pop(bottomSheetContext);
                          final ok = await authController.changePassword(
                            currentPassword: currentPasswordController.text,
                            newPassword: newPasswordController.text,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          if (ok) {
                            AppSnackBar.showSuccess(
                              context,
                              'Đổi mật khẩu thành công!',
                            );
                          } else {
                            AppSnackBar.showError(
                              context,
                              authController.errorMessage ??
                                  'Đổi mật khẩu thất bại.',
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= 2. Modal Chỉnh Sửa Thông Tin Liên Hệ =================
  void _showEditContactBottomSheet(
    BuildContext context,
    AuthController authController,
    UserModel? user,
  ) {
    final nameController = TextEditingController(text: user?.fullName ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    final idCardController = TextEditingController(
      text: user?.idCardNumber ?? '',
    );
    final addressController = TextEditingController(text: user?.address ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 20.0,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.0,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
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
                    controller: nameController,
                    validator: AppValidators.validateFullName,
                  ),
                  const SizedBox(height: 14.0),
                  AppTextField(
                    label: 'Số điện thoại',
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    validator: AppValidators.validatePhone,
                  ),
                  const SizedBox(height: 14.0),
                  AppTextField(
                    label: 'Số CCCD gắn chip (12 số)',
                    hint: 'Nhập 12 số CCCD',
                    controller: idCardController,
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
                    controller: addressController,
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
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      authController.updateCurrentUser(
                        fullName: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        idCardNumber: idCardController.text.trim().isEmpty
                            ? null
                            : idCardController.text.trim(),
                        address: addressController.text.trim().isEmpty
                            ? null
                            : addressController.text.trim(),
                      );
                      Navigator.pop(ctx);
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
      },
    );
  }

  // ================= 3. Modal Cập Nhật Thu Nhập & Nghề Nghiệp =================
  void _showEditIncomeBottomSheet(
    BuildContext context,
    AuthController authController,
    UserModel? user,
  ) {
    final incomeController = TextEditingController(
      text: user?.monthlyIncome != null && user!.monthlyIncome! > 0
          ? user.monthlyIncome!.round().toString()
          : '',
    );
    final occupationController = TextEditingController(
      text: user?.occupation ?? '',
    );
    final workplaceController = TextEditingController(
      text: user?.workplace ?? '',
    );
    final contractTypeController = TextEditingController(
      text: user?.contractType ?? '',
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 20.0,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24.0,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
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
                    controller: incomeController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(
                      Icons.payments_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    validator: (val) => AppValidators.validateMonthlyIncome(
                      val,
                      required: false,
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  AppTextField(
                    label: 'Vị trí công việc / Nghề nghiệp',
                    hint: 'Ví dụ: Kỹ sư Phần mềm Senior',
                    controller: occupationController,
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
                    controller: workplaceController,
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
                    controller: contractTypeController,
                  ),
                  const SizedBox(height: 24.0),
                  AppPrimaryButton(
                    label: 'Xác nhận cập nhật thu nhập',
                    onPressed: () {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      final rawIncome = incomeController.text.trim();
                      final newIncome = rawIncome.isNotEmpty
                          ? double.tryParse(rawIncome)
                          : null;
                      authController.updateCurrentUser(
                        monthlyIncome: newIncome,
                        occupation: occupationController.text.trim().isEmpty
                            ? null
                            : occupationController.text.trim(),
                        workplace: workplaceController.text.trim().isEmpty
                            ? null
                            : workplaceController.text.trim(),
                        contractType: contractTypeController.text.trim().isEmpty
                            ? null
                            : contractTypeController.text.trim(),
                      );
                      Navigator.pop(ctx);
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
      },
    );
  }

  // ================= 4. Modal Thêm Tài Khoản Ngân Hàng Mới =================
  void _showAddBankAccountBottomSheet(
    BuildContext context,
    AuthController authController,
    UserModel? user,
  ) {
    String selectedBank = 'Techcombank';
    final accountNumController = TextEditingController();
    final holderNameController = TextEditingController(
      text: (user?.fullName.isNotEmpty == true)
          ? user!.fullName.toUpperCase()
          : 'CHỦ TÀI KHOẢN',
    );
    bool isDefaultDisbursal = user?.bankAccounts.isEmpty ?? true;
    bool isAutoDebit = false;
    final formKey = GlobalKey<FormState>();

    const popularBanks = [
      'Techcombank',
      'Vietcombank',
      'MBBank',
      'BIDV',
      'VietinBank',
      'VPBank',
      'ACB',
      'TPBank',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 20.0,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24.0,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
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
                        'Liên kết tài khoản ngân hàng',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      const Text(
                        'Tài khoản cần là tài khoản chính chủ để đảm bảo tính pháp lý khi nhận giải ngân Napas 24/7.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18.0),

                      // Chọn ngân hàng
                      const Text(
                        'Ngân hàng thụ hưởng',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      DropdownButtonFormField<String>(
                        initialValue: selectedBank,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                        items: popularBanks.map((bank) {
                          return DropdownMenuItem(
                            value: bank,
                            child: Text(bank),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedBank = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14.0),

                      // Số tài khoản
                      AppTextField(
                        label: 'Số tài khoản ngân hàng',
                        hint: 'Nhập số tài khoản (6 - 20 số)',
                        controller: accountNumController,
                        keyboardType: TextInputType.number,
                        validator: AppValidators.validateBankAccountNumber,
                      ),
                      const SizedBox(height: 14.0),

                      // Tên chủ tài khoản
                      AppTextField(
                        label: 'Tên chủ tài khoản (In hoa không dấu)',
                        hint: 'Ví dụ: NGUYEN VAN A',
                        controller: holderNameController,
                        validator: AppValidators.validateAccountHolderName,
                      ),
                      const SizedBox(height: 12.0),

                      // Checkboxes thiết lập
                      CheckboxListTile(
                        value: isDefaultDisbursal,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Đặt làm tài khoản giải ngân mặc định',
                          style: TextStyle(fontSize: 13.5),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            isDefaultDisbursal = val ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        value: isAutoDebit,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Đăng ký trích nợ tự động hàng tháng',
                          style: TextStyle(fontSize: 13.5),
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            isAutoDebit = val ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 16.0),

                      AppPrimaryButton(
                        label: 'Xác nhận liên kết',
                        onPressed: () {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          final newAccount = BankAccountModel(
                            id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
                            bankName: selectedBank,
                            accountNumber: accountNumController.text.trim(),
                            accountHolderName: holderNameController.text
                                .trim()
                                .toUpperCase(),
                            isDefaultDisbursal: isDefaultDisbursal,
                            isAutoDebit: isAutoDebit,
                          );
                          authController.addBankAccount(newAccount);
                          Navigator.pop(sheetCtx);
                          AppSnackBar.showSuccess(
                            context,
                            'Liên kết tài khoản $selectedBank thành công!',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================= 5. Modal Quản Lý Danh Sách Tài Khoản Ngân Hàng =================
  void _showBankAccountsBottomSheet(
    BuildContext context,
    AuthController authController,
    UserModel? user,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        final accounts = user?.bankAccounts ?? [];

        return StatefulBuilder(
          builder: (sheetContext, setListState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 32.0),
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
                    'Tài khoản thụ hưởng & Trích nợ',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  const Text(
                    'Tài khoản chính chủ nhận giải ngân các khoản vay và thiết lập trích nợ tự động hàng tháng.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  if (accounts.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24.0,
                        horizontal: 16.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_outlined,
                            size: 40.0,
                            color: AppColors.textSecondary.withValues(
                              alpha: 0.7,
                            ),
                          ),
                          const SizedBox(height: 10.0),
                          const Text(
                            'Chưa liên kết tài khoản ngân hàng nào',
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          const Text(
                            'Vui lòng thêm tài khoản để nhận giải ngân tức thì khi hồ sơ vay được duyệt.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ...accounts.map((acc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(14.0),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14.0),
                            border: Border.all(
                              color: acc.isDefaultDisbursal
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: acc.isDefaultDisbursal ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40.0,
                                height: 40.0,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.account_balance_rounded,
                                  color: AppColors.primary,
                                  size: 20.0,
                                ),
                              ),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          acc.bankName,
                                          style: const TextStyle(
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        if (acc.isDefaultDisbursal) ...[
                                          const SizedBox(width: 6.0),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6.0,
                                              vertical: 2.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6.0),
                                            ),
                                            child: const Text(
                                              'Mặc định giải ngân',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (acc.isAutoDebit) ...[
                                          const SizedBox(width: 6.0),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6.0,
                                              vertical: 2.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(
                                                alpha: 0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6.0),
                                            ),
                                            child: const Text(
                                              'Trích nợ tự động',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4.0),
                                    Text(
                                      _maskAccountNumber(acc.accountNumber),
                                      style: const TextStyle(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      acc.accountHolderName.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 11.0,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.error,
                                  size: 20.0,
                                ),
                                tooltip: 'Hủy liên kết',
                                onPressed: () {
                                  authController.removeBankAccount(acc.id);
                                  Navigator.pop(ctx);
                                  AppSnackBar.showSuccess(
                                    context,
                                    'Đã hủy liên kết tài khoản ${acc.bankName}.',
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 16.0),

                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddBankAccountBottomSheet(
                        context,
                        authController,
                        user,
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 20.0),
                    label: const Text('Thêm tài khoản ngân hàng liên kết'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = sl<AuthController>();
    final loanController = sl<LoanController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([authController, loanController]),
        builder: (context, _) {
          final user = authController.currentUser;
          final String initialLetter = (user?.fullName.isNotEmpty == true)
              ? user!.fullName.substring(0, 1).toUpperCase()
              : 'U';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Thẻ Header Cá Nhân & Định Danh eKYC C06
                _buildProfileHeaderCard(user, initialLetter),
                const SizedBox(height: 16.0),

                // 2. Thước đo Tài Chính Tóm Tắt (3 Chỉ số Vàng Tính Toán Thực Tế)
                _buildQuickFinancialMetrics(user, loanController),
                const SizedBox(height: 20.0),

                // 3. Khối Thông Tin Định Danh Pháp Lý (Legal Identity)
                _buildSectionTitle(
                  title: 'Thông tin định danh pháp lý',
                  actionText: 'Chỉnh sửa',
                  onAction: () => _showEditContactBottomSheet(
                    context,
                    authController,
                    user,
                  ),
                ),
                const SizedBox(height: 8.0),
                _buildLegalIdentityCard(user),
                const SizedBox(height: 20.0),

                // 4. Khối Năng Lực Tài Chính & Thu Nhập Thẩm Định
                _buildSectionTitle(
                  title: 'Hồ sơ năng lực tài chính & Thu nhập',
                  actionText: 'Cập nhật',
                  onAction: () =>
                      _showEditIncomeBottomSheet(context, authController, user),
                ),
                const SizedBox(height: 8.0),
                _buildFinancialCapabilityCard(user, loanController),
                const SizedBox(height: 20.0),

                // 5. Khối Tài Khoản Ngân Hàng Nhận Giải Ngân
                _buildSectionTitle(
                  title: 'Tài khoản thụ hưởng & Nhận giải ngân',
                  actionText: 'Quản lý',
                  onAction: () => _showBankAccountsBottomSheet(
                    context,
                    authController,
                    user,
                  ),
                ),
                const SizedBox(height: 8.0),
                _buildDisbursalAccountPreviewCard(
                  context,
                  authController,
                  user,
                ),
                const SizedBox(height: 20.0),

                // 6. Khối Sức Khỏe Tín Dụng & Xếp Hạng CIC
                _buildSectionTitle(
                  title: 'Hồ sơ tín nhiệm tín dụng CIC',
                  actionText: user?.cicScore != null
                      ? 'Xem báo cáo'
                      : 'Tra cứu ngay',
                  onAction: () => MainShellScreen.switchTab(context, 3),
                ),
                const SizedBox(height: 8.0),
                _buildCreditHealthSnapshotCard(context, user, loanController),
                const SizedBox(height: 20.0),

                // 7. Khối Quản Lý Hồ Sơ & Bảo Mật Cá Nhân
                const Text(
                  'Hành động & Bảo mật hồ sơ',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8.0),
                _buildSecurityActionsCard(context, authController, user),

                const SizedBox(height: 100.0), // Đệm an toàn cho Bottom Nav Bar
              ],
            ),
          );
        },
      ),
    );
  }

  // ================= CÁC WIDGET THÀNH PHẦN CHI TIẾT =================

  Widget _buildSectionTitle({
    required String title,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: AppColors.primary,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionText,
                style: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2.0),
              const Icon(Icons.arrow_forward_ios_rounded, size: 11.0),
            ],
          ),
        ),
      ],
    );
  }

  // 1. Header Card: Định danh eKYC C06 & Thông tin Khách hàng
  Widget _buildProfileHeaderCard(UserModel? user, String initialLetter) {
    final isVerified = user?.isEkycVerified ?? false;
    final String tier = user?.membershipTier.toUpperCase() ?? 'STANDARD';

    Color tierColor = AppColors.primary;
    String tierLabel = 'Thành viên mới';
    IconData tierIcon = Icons.person_rounded;

    if (tier == 'GOLD') {
      tierColor = const Color(0xFFD97706);
      tierLabel = 'Gold Member';
      tierIcon = Icons.workspace_premium_rounded;
    } else if (tier == 'PLATINUM') {
      tierColor = const Color(0xFF6366F1);
      tierLabel = 'Platinum Member';
      tierIcon = Icons.diamond_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 34.0,
                    backgroundColor: AppColors.primarySoft,
                    child: Text(
                      initialLetter,
                      style: const TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 13.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (user?.fullName.isNotEmpty == true)
                          ? user!.fullName
                          : 'Khách hàng FinCredit',
                      style: const TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      'Mã định danh: FC-${user?.userId ?? 0}',
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 3.0,
                          ),
                          decoration: BoxDecoration(
                            color: isVerified
                                ? AppColors.success.withValues(alpha: 0.12)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isVerified
                                    ? Icons.verified_user_rounded
                                    : Icons.shield_outlined,
                                size: 12.0,
                                color: isVerified
                                    ? AppColors.success
                                    : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                isVerified
                                    ? 'Đã xác thực eKYC ${user?.ekycTier ?? "C06"}'
                                    : 'Chưa xác thực eKYC',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isVerified
                                      ? AppColors.success
                                      : const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 3.0,
                          ),
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tierIcon, size: 12.0, color: tierColor),
                              const SizedBox(width: 4.0),
                              Text(
                                tierLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: tierColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Thước đo Tài Chính Tóm Tắt (3 Chỉ số Vàng Tính Toán Thực Tế)
  Widget _buildQuickFinancialMetrics(
    UserModel? user,
    LoanController loanController,
  ) {
    // 1. Điểm tín dụng thực tế
    final int? score = user?.cicScore;
    String scoreVal = 'Chưa có';
    String scoreSub = 'Bấm để tra cứu';
    Color scoreColor = AppColors.textSecondary;

    if (score != null) {
      scoreVal = '$score / 850';
      if (score >= 740) {
        scoreSub = 'Hạng 2 • Rất tốt';
        scoreColor = const Color(0xFF059669);
      } else if (score >= 680) {
        scoreSub = 'Hạng 3 • Tốt';
        scoreColor = const Color(0xFF059669);
      } else if (score >= 600) {
        scoreSub = 'Hạng 4 • Trung bình';
        scoreColor = const Color(0xFFD97706);
      } else {
        scoreSub = 'Hạng 5 • Cần chú ý';
        scoreColor = const Color(0xFFDC2626);
      }
    }

    // 2. Tỷ lệ gánh nặng nợ DTI thực tế từ danh sách khoản vay và thu nhập
    final activeLoans = loanController.loans
        .where(
          (l) =>
              l.status.toLowerCase() != 'paid' &&
              l.status.toLowerCase() != 'rejected',
        )
        .toList();
    final monthlyRepayment = activeLoans.fold<double>(
      0.0,
      (sum, l) => sum + l.monthlyInstallmentEstimate,
    );
    final income = user?.monthlyIncome ?? 0.0;

    String dtiVal;
    String dtiSub;
    Color dtiColor;

    if (income > 0 && monthlyRepayment > 0) {
      final dti = (monthlyRepayment / income * 100);
      dtiVal = '${dti.toStringAsFixed(1)}%';
      dtiSub = dti < 40 ? 'Mức an toàn < 40%' : 'Cần chú ý (>40%)';
      dtiColor = dti < 40 ? const Color(0xFF0284C7) : const Color(0xFFDC2626);
    } else if (income > 0 && monthlyRepayment == 0) {
      dtiVal = '0%';
      dtiSub = 'Không có dư nợ';
      dtiColor = const Color(0xFF059669);
    } else {
      dtiVal = 'Chưa tính';
      dtiSub = 'Chưa cập nhật thu nhập';
      dtiColor = AppColors.textSecondary;
    }

    // 3. Thu nhập thực tế
    final String incomeVal =
        (user?.monthlyIncome != null && user!.monthlyIncome! > 0)
        ? _formatCurrency(user.monthlyIncome!)
        : 'Chưa cập nhật';
    final String incomeSub =
        (user?.monthlyIncome != null && user!.monthlyIncome! > 0)
        ? 'Đã xác minh'
        : 'Chưa xác minh';
    final Color incomeColor =
        (user?.monthlyIncome != null && user!.monthlyIncome! > 0)
        ? AppColors.primary
        : AppColors.textSecondary;

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'Điểm tín dụng',
            value: scoreVal,
            subtext: scoreSub,
            icon: Icons.shield_rounded,
            color: scoreColor,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _buildMetricTile(
            title: 'Gánh nặng nợ (DTI)',
            value: dtiVal,
            subtext: dtiSub,
            icon: Icons.pie_chart_rounded,
            color: dtiColor,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _buildMetricTile(
            title: 'Thu nhập/tháng',
            value: incomeVal,
            subtext: incomeSub,
            icon: Icons.account_balance_wallet_rounded,
            color: incomeColor,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16.0, color: color),
              const SizedBox(width: 4.0),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11.0,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2.0),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 3. Khối Thông Tin Định Danh Pháp Lý (Legal Identity)
  Widget _buildLegalIdentityCard(UserModel? user) {
    final idCard = user?.idCardNumber;
    final address = user?.address;
    final phone = user?.phone;
    final isVerified = user?.isEkycVerified ?? false;

    return _buildCard([
      _buildInfoRow(
        icon: Icons.badge_outlined,
        label: 'Số CCCD gắn chip (C06)',
        value: (idCard != null && idCard.isNotEmpty)
            ? _maskIdCard(idCard)
            : 'Chưa cập nhật CCCD',
        badgeText: (idCard != null && idCard.isNotEmpty)
            ? (isVerified ? 'Hợp lệ' : 'Chưa đối soát')
            : 'Cần bổ sung',
        badgeColor: (idCard != null && idCard.isNotEmpty)
            ? (isVerified ? AppColors.success : const Color(0xFFD97706))
            : const Color(0xFFD97706),
      ),
      const Divider(height: 1.0, indent: 44.0),
      _buildInfoRow(
        icon: Icons.cake_outlined,
        label: 'Ngày sinh',
        value: user?.dateOfBirth != null
            ? '${user!.dateOfBirth!.day.toString().padLeft(2, '0')}/${user.dateOfBirth!.month.toString().padLeft(2, '0')}/${user.dateOfBirth!.year}'
            : 'Chưa cập nhật',
      ),
      const Divider(height: 1.0, indent: 44.0),
      _buildInfoRow(
        icon: Icons.phone_android_rounded,
        label: 'Số điện thoại nhận OTP',
        value: (phone != null && phone.isNotEmpty) ? phone : 'Chưa cập nhật',
      ),
      const Divider(height: 1.0, indent: 44.0),
      _buildInfoRow(
        icon: Icons.email_outlined,
        label: 'Email nhận thông báo pháp lý',
        value: user?.email ?? 'Chưa cập nhật',
      ),
      const Divider(height: 1.0, indent: 44.0),
      _buildInfoRow(
        icon: Icons.location_on_outlined,
        label: 'Địa chỉ thường trú',
        value: (address != null && address.isNotEmpty)
            ? address
            : 'Chưa cập nhật địa chỉ',
        badgeText: (address != null && address.isNotEmpty)
            ? null
            : 'Cần bổ sung',
        badgeColor: const Color(0xFFD97706),
      ),
    ]);
  }

  // 4. Khối Năng Lực Tài Chính & Thu Nhập Thẩm Định
  Widget _buildFinancialCapabilityCard(
    UserModel? user,
    LoanController loanController,
  ) {
    final income = user?.monthlyIncome;
    final occupation = user?.occupation;
    final workplace = user?.workplace;
    final contractType = user?.contractType;
    final totalCollateral = loanController.totalCollateralValue;

    return _buildCard([
      _buildInfoRow(
        icon: Icons.attach_money_rounded,
        label: 'Thu nhập ròng hàng tháng',
        value: (income != null && income > 0)
            ? _formatCurrency(income)
            : 'Chưa cập nhật',
        badgeText: (income != null && income > 0)
            ? 'Đã đối soát'
            : 'Chưa xác minh',
        badgeColor: (income != null && income > 0)
            ? AppColors.success
            : AppColors.textSecondary,
      ),
      const Divider(height: 1.0, indent: 44.0),
      _buildInfoRow(
        icon: Icons.work_outline_rounded,
        label: 'Nghề nghiệp & Vị trí',
        value: (occupation != null && occupation.isNotEmpty)
            ? occupation
            : 'Chưa cập nhật',
      ),
      const Divider(height: 1.0, indent: 44.0),
      _buildInfoRow(
        icon: Icons.business_rounded,
        label: 'Cơ quan / Nơi công tác',
        value: (workplace != null && workplace.isNotEmpty)
            ? workplace
            : 'Chưa cập nhật',
      ),
      const Divider(height: 1.0, indent: 44.0),
      _buildInfoRow(
        icon: Icons.description_outlined,
        label: 'Hợp đồng lao động',
        value: (contractType != null && contractType.isNotEmpty)
            ? contractType
            : 'Chưa cập nhật',
      ),
      const Divider(height: 1.0, indent: 44.0),
      _buildInfoRow(
        icon: Icons.apartment_rounded,
        label: 'Tổng giá trị tài sản thế chấp',
        value: totalCollateral > 0
            ? _formatCurrency(totalCollateral)
            : '0 đ (Chưa có tài sản thế chấp)',
        badgeText: totalCollateral > 0
            ? '${loanController.collaterals.length} tài sản'
            : null,
        badgeColor: AppColors.primary,
      ),
    ]);
  }

  // 5. Khối Tài Khoản Ngân Hàng Nhận Giải Ngân
  Widget _buildDisbursalAccountPreviewCard(
    BuildContext context,
    AuthController authController,
    UserModel? user,
  ) {
    final accounts = user?.bankAccounts ?? [];

    if (accounts.isEmpty) {
      return _buildCard([
        ListTile(
          leading: Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_outlined,
              color: AppColors.primary,
              size: 20.0,
            ),
          ),
          title: const Text(
            'Chưa liên kết tài khoản nhận giải ngân',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Chạm để liên kết tài khoản ngân hàng thụ hưởng chính chủ',
            style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          trailing: const Icon(
            Icons.add_circle_outline_rounded,
            size: 20.0,
            color: AppColors.primary,
          ),
          onTap: () =>
              _showBankAccountsBottomSheet(context, authController, user),
        ),
      ]);
    }

    final defaultAcc = accounts.firstWhere(
      (a) => a.isDefaultDisbursal,
      orElse: () => accounts.first,
    );

    return _buildCard([
      ListTile(
        leading: Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.account_balance_rounded,
            color: AppColors.primary,
            size: 20.0,
          ),
        ),
        title: Row(
          children: [
            Text(
              defaultAcc.bankName,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6.0),
            Text(
              _maskAccountNumber(defaultAcc.accountNumber),
              style: const TextStyle(
                fontSize: 13.0,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        subtitle: Text(
          'Nhận giải ngân mặc định • ${defaultAcc.accountHolderName.toUpperCase()}',
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14.0,
          color: AppColors.textSecondary,
        ),
        onTap: () =>
            _showBankAccountsBottomSheet(context, authController, user),
      ),
    ]);
  }

  // 6. Khối Sức Khỏe Tín Dụng & Xếp Hạng CIC
  Widget _buildCreditHealthSnapshotCard(
    BuildContext context,
    UserModel? user,
    LoanController loanController,
  ) {
    final int? score = user?.cicScore;

    if (score == null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
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
                      Icons.security_rounded,
                      color: Color(0xFF38BDF8),
                      size: 20.0,
                    ),
                    SizedBox(width: 8.0),
                    Text(
                      'Điểm Tín Dụng Quốc Gia (CIC)',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Text(
                    'Chưa có báo cáo',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFBBF24),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14.0),
            const Text(
              'Bạn chưa có báo cáo điểm tín dụng quốc gia. Tra cứu ngay để xem xếp hạng tín nhiệm và hạn mức khả dụng.',
              style: TextStyle(
                fontSize: 12.0,
                color: Color(0xFFCBD5E1),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14.0),
            InkWell(
              onTap: () => MainShellScreen.switchTab(context, 3),
              borderRadius: BorderRadius.circular(8.0),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Tra cứu điểm tín nhiệm CIC ngay',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  SizedBox(width: 4.0),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14.0,
                    color: Color(0xFF38BDF8),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    String riskLabel = 'Hạng 2 - Rất tốt';
    Color riskColor = const Color(0xFF34D399);
    if (score < 600) {
      riskLabel = 'Hạng 5 - Cần chú ý';
      riskColor = const Color(0xFFF87171);
    } else if (score < 680) {
      riskLabel = 'Hạng 4 - Trung bình';
      riskColor = const Color(0xFFFBBF24);
    } else if (score < 740) {
      riskLabel = 'Hạng 3 - Tốt';
      riskColor = const Color(0xFF34D399);
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
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
                    Icons.security_rounded,
                    color: Color(0xFF38BDF8),
                    size: 20.0,
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    'Điểm Tín Dụng Quốc Gia (CIC)',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
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
                  color: riskColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  riskLabel,
                  style: TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6.0),
              const Text(
                '/ 850 điểm',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Lịch sử tín dụng được đồng bộ từ Trung tâm Thông tin Tín dụng Quốc gia (CIC).',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFFCBD5E1),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12.0),
          InkWell(
            onTap: () => MainShellScreen.switchTab(context, 3),
            borderRadius: BorderRadius.circular(8.0),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Mở chi tiết phân tích tín dụng chuyên sâu',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF38BDF8),
                  ),
                ),
                SizedBox(width: 4.0),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14.0,
                  color: Color(0xFF38BDF8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 7. Khối Quản Lý Hồ Sơ & Bảo Mật Cá Nhân
  Widget _buildSecurityActionsCard(
    BuildContext context,
    AuthController authController,
    UserModel? user,
  ) {
    final isVerified = user?.isEkycVerified ?? false;

    return _buildCard([
      _buildMenuItem(
        icon: Icons.lock_outline_rounded,
        iconColor: AppColors.primary,
        title: 'Đổi mật khẩu tài khoản',
        subtitle: 'Cập nhật mật khẩu định kỳ với bộ đo độ mạnh bảo mật',
        onTap: () => _showChangePasswordBottomSheet(context, authController),
      ),
      const Divider(height: 1.0, indent: 56.0),
      _buildMenuItem(
        icon: Icons.document_scanner_outlined,
        iconColor: const Color(0xFFD97706),
        title: 'Quản lý tài sản thế chấp & OCR',
        subtitle: 'Bóc tách hợp đồng tín dụng và định giá tài sản bảo đảm',
        onTap: () {
          Navigator.pushNamed(context, AppRouter.loanCollateralOcr);
        },
      ),
      const Divider(height: 1.0, indent: 56.0),
      _buildMenuItem(
        icon: Icons.file_download_outlined,
        iconColor: const Color(0xFF0284C7),
        title: 'Xuất hồ sơ năng lực tài chính (PDF)',
        subtitle: 'Tải bản tóm tắt hồ sơ tín dụng có xác thực số FinCredit',
        onTap: () {
          final userName = (user?.fullName.isNotEmpty == true)
              ? user!.fullName
              : 'khách hàng';
          AppSnackBar.showSuccess(
            context,
            'Đã xuất bản tóm tắt hồ sơ năng lực tài chính cho $userName (PDF) thành công!',
          );
        },
      ),
      const Divider(height: 1.0, indent: 56.0),
      _buildMenuItem(
        icon: Icons.verified_outlined,
        iconColor: isVerified ? AppColors.success : const Color(0xFFD97706),
        title: 'Yêu cầu cập nhật định danh eKYC',
        subtitle: isVerified
            ? 'Hồ sơ eKYC ${user?.ekycTier ?? "C06"} đang có hiệu lực. Xác thực lại khi có thay đổi CCCD.'
            : 'Chưa xác thực CCCD gắn chip NFC. Chạm để tiến hành định danh.',
        onTap: () {
          if (isVerified) {
            AppSnackBar.showInfo(
              context,
              'Hồ sơ eKYC ${user?.ekycTier ?? "C06"} của bạn đang có hiệu lực đến 2028. Chưa cần xác thực lại.',
            );
          } else {
            AppSnackBar.showInfo(
              context,
              'Vui lòng chuẩn bị CCCD gắn chip NFC để quét xác thực định danh điện tử.',
            );
          }
        },
      ),
    ]);
  }

  // Tiện ích render 1 dòng thông tin
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    String? badgeText,
    Color? badgeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.0, color: AppColors.primary),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 3.0,
              ),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppColors.primary).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(6.0),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: badgeColor ?? AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(icon, color: iconColor, size: 20.0),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
      ),
      trailing:
          trailing ??
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14.0,
            color: AppColors.textSecondary,
          ),
      onTap: onTap,
    );
  }
}
