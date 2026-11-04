import 'package:flutter/material.dart';

import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../service_locator.dart';
import '../../services/image_upload_service.dart';
import '../widget.dart';

/// Modal BottomSheet thực hiện luồng định danh điện tử eKYC C06
/// Hỗ trợ nhập số CCCD và chụp/tải 2 mặt thẻ căn cước lên Cloudflare R2
class EkycVerificationSheet extends StatefulWidget {
  final AuthController authController;
  final UserModel? user;

  const EkycVerificationSheet({
    super.key,
    required this.authController,
    this.user,
  });

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
          EkycVerificationSheet(authController: authController, user: user),
    );
  }

  @override
  State<EkycVerificationSheet> createState() => _EkycVerificationSheetState();
}

class _EkycVerificationSheetState extends State<EkycVerificationSheet> {
  late final TextEditingController _idCardController;
  String? _frontCardUrl;
  String? _backCardUrl;
  bool _isUploadingFront = false;
  bool _isUploadingBack = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _idCardController = TextEditingController(
      text: widget.user?.idCardNumber ?? '',
    );
  }

  @override
  void dispose() {
    _idCardController.dispose();
    super.dispose();
  }

  String _maskIdCard(String idCard) {
    final clean = idCard.replaceAll(' ', '');
    if (clean.length < 8) return clean;
    final prefix = clean.substring(0, 4);
    final mid = clean.substring(4, 8);
    return '$prefix $mid ****';
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isVerified = user?.isEkycVerified ?? false;

    return Padding(
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      child: SingleChildScrollView(
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isVerified ? Icons.verified_rounded : Icons.badge_outlined,
                    color: isVerified ? AppColors.success : AppColors.primary,
                    size: 24.0,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVerified
                            ? 'Định danh điện tử eKYC C06'
                            : 'Cập nhật định danh eKYC C06',
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        isVerified
                            ? 'Hồ sơ đã được xác thực cấp độ ${user?.ekycTier ?? "C06"}'
                            : 'Xác thực căn cước công dân gắn chip',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            if (isVerified &&
                _frontCardUrl == null &&
                _backCardUrl == null) ...[
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.success,
                          size: 18.0,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'CCCD số: ${_maskIdCard(user?.idCardNumber ?? "079201008888")}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6.0),
                    const Text(
                      'Hồ sơ định danh C06 của bạn đang có hiệu lực. Bạn chỉ cần cập nhật lại khi đổi thẻ CCCD mới hoặc hết hạn.',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _frontCardUrl = '';
                    _backCardUrl = '';
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 18.0),
                label: const Text('Cập nhật lại CCCD mới'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ] else ...[
              AppTextField(
                controller: _idCardController,
                label: 'Số CCCD gắn chip (12 số)',
                hint: '079201008888',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.credit_card_rounded),
                validator: (val) {
                  if (val == null || val.trim().length != 12) {
                    return 'Vui lòng nhập đúng 12 chữ số CCCD';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: _buildCccdCard(
                      label: 'Mặt trước CCCD',
                      imageUrl: _frontCardUrl,
                      isLoading: _isUploadingFront,
                      onTap: () async {
                        setState(() => _isUploadingFront = true);
                        final imageUploadService = sl<ImageUploadService>();
                        final res = await imageUploadService.pickAndUploadImage(
                          context,
                          folder: 'ekyc/${user?.userId ?? 1}',
                          filePrefix: 'cccd_front',
                          isPublic: false,
                          title: 'Chụp mặt trước CCCD',
                        );
                        setState(() {
                          _isUploadingFront = false;
                          if (res?.isSuccess == true) {
                            _frontCardUrl = res!.fileKey;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: _buildCccdCard(
                      label: 'Mặt sau CCCD',
                      imageUrl: _backCardUrl,
                      isLoading: _isUploadingBack,
                      onTap: () async {
                        setState(() => _isUploadingBack = true);
                        final imageUploadService = sl<ImageUploadService>();
                        final res = await imageUploadService.pickAndUploadImage(
                          context,
                          folder: 'ekyc/${user?.userId ?? 1}',
                          filePrefix: 'cccd_back',
                          isPublic: false,
                          title: 'Chụp mặt sau CCCD',
                        );
                        setState(() {
                          _isUploadingBack = false;
                          if (res?.isSuccess == true) {
                            _backCardUrl = res!.fileKey;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              AppPrimaryButton(
                label: _isSubmitting
                    ? 'Đang xác thực hồ sơ...'
                    : 'Gửi hồ sơ định danh C06',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final cccd = _idCardController.text.trim();
                        if (cccd.length != 12) {
                          AppSnackBar.showError(
                            context,
                            'Vui lòng nhập đủ 12 chữ số CCCD hợp lệ.',
                          );
                          return;
                        }
                        setState(() => _isSubmitting = true);
                        final ok = await widget.authController.verifyEkyc(
                          idCardNumber: cccd,
                          frontCardUrl:
                              (_frontCardUrl != null &&
                                  _frontCardUrl!.isNotEmpty)
                              ? _frontCardUrl!
                              : 'ekyc/${user?.userId ?? 1}/cccd_front_default.jpg',
                          backCardUrl:
                              (_backCardUrl != null && _backCardUrl!.isNotEmpty)
                              ? _backCardUrl!
                              : 'ekyc/${user?.userId ?? 1}/cccd_back_default.jpg',
                        );
                        setState(() => _isSubmitting = false);
                        if (!context.mounted) return;
                        if (ok) {
                          Navigator.pop(context);
                          AppSnackBar.showSuccess(
                            context,
                            'Định danh eKYC C06 thành công! Hồ sơ đã được cập nhật.',
                          );
                        } else {
                          AppSnackBar.showError(
                            context,
                            widget.authController.errorMessage ??
                                'Xác thực eKYC thất bại.',
                          );
                        }
                      },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCccdCard({
    required String label,
    required String? imageUrl,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        height: 100.0,
        decoration: BoxDecoration(
          color: hasImage
              ? AppColors.success.withValues(alpha: 0.08)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: hasImage ? AppColors.success : AppColors.border,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasImage
                        ? Icons.check_circle_rounded
                        : Icons.camera_alt_outlined,
                    color: hasImage ? AppColors.success : AppColors.primary,
                    size: 26.0,
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    hasImage ? 'Đã tải ảnh' : label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: hasImage
                          ? AppColors.success
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
