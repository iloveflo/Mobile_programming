import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../widget.dart';

/// Khối thông báo yêu cầu hoàn tất hồ sơ (eKYC CCCD & Thu nhập cá nhân)
/// dùng chung cho Trang chủ (dạng card) và Màn hình tạo khoản vay (dạng toàn trang).
class ProfileCompletionNotice extends StatelessWidget {
  final List<String> missingFields;
  final VoidCallback onGoToProfile;
  final bool isCard;

  const ProfileCompletionNotice({
    super.key,
    required this.missingFields,
    required this.onGoToProfile,
    this.isCard = false,
  });

  /// Trả về danh sách các thông tin hồ sơ còn thiếu hoặc chưa hợp lệ của [user].
  static List<String> getMissingProfileFields(UserModel? user) {
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
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCard) ...[
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: const Text(
                'Yêu cầu hoàn tất hồ sơ',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12.0),
        ],
        Icon(
          Icons.verified_user_outlined,
          size: isCard ? 52.0 : 64.0,
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
            color: isCard ? AppColors.background : AppColors.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(missingFields.length, (index) {
              final item = missingFields[index];
              final isLast = index == missingFields.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0.0 : 6.0),
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
              );
            }),
          ),
        ),
        const SizedBox(height: 20.0),
        AppPrimaryButton(
          label: 'Đi tới Hồ sơ cá nhân',
          onPressed: onGoToProfile,
        ),
      ],
    );

    if (!isCard) {
      return Padding(padding: const EdgeInsets.all(24.0), child: content);
    }

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: content,
    );
  }
}

/// Màn hình toàn trang thông báo yêu cầu hoàn tất hồ sơ dùng cho các tab chính
/// (Trang chủ, Khoản vay, Lịch trả nợ, Tín dụng) và màn hình tạo khoản vay.
class ProfileCompletionScaffold extends StatelessWidget {
  final List<String> missingFields;
  final VoidCallback onGoToProfile;
  final bool showBackButton;

  const ProfileCompletionScaffold({
    super.key,
    required this.missingFields,
    required this.onGoToProfile,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 20.0,
                ),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
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
        child: Center(
          child: SingleChildScrollView(
            child: ProfileCompletionNotice(
              missingFields: missingFields,
              onGoToProfile: onGoToProfile,
            ),
          ),
        ),
      ),
    );
  }
}
