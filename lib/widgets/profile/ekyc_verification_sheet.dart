import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../repositories/interfaces/storage_repository.dart';
import '../../service_locator.dart';
import '../../services/cccd_scanner_service.dart';
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
  final CccdScannerService _scanner = CccdScannerService();
  String? _frontCardUrl;
  String? _backCardUrl;
  XFile? _frontPickedFile;
  XFile? _backPickedFile;
  CccdFrontData? _frontData;
  CccdBackData? _backData;
  bool _isUploadingFront = false;
  bool _isUploadingBack = false;
  bool _isSubmitting = false;
  bool _isLoadingFiles = false;
  String? _inlineError;
  String? _inlineSuccess;
  List<Map<String, dynamic>> _uploadedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadUploadedFiles();
  }

  Future<void> _loadUploadedFiles() async {
    if (!sl.isRegistered<StorageRepository>()) return;
    setState(() => _isLoadingFiles = true);
    try {
      final files = await sl<StorageRepository>().listUploadedFiles(
        folder: 'ekyc',
      );
      if (mounted) {
        setState(() {
          _uploadedFiles = files;
          _isLoadingFiles = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingFiles = false);
    }
  }

  Future<void> _deleteUploadedFile(String fileKey) async {
    try {
      await sl<StorageRepository>().deleteFile(fileKey);
      if (!mounted) return;
      setState(() {
        if (_frontCardUrl == fileKey) {
          _frontCardUrl = null;
          _frontData = null;
        }
        if (_backCardUrl == fileKey) {
          _backCardUrl = null;
          _backData = null;
        }
        _inlineSuccess = 'Đã xóa ảnh CCCD khỏi Cloudflare R2.';
        _inlineError = null;
      });
      await _loadUploadedFiles();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inlineError =
            'Không thể xóa ảnh: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  Future<void> _deleteAllOldFiles() async {
    final oldFiles = _uploadedFiles
        .where((f) => f['is_current'] != true)
        .map((f) => (f['file_key'] ?? '').toString())
        .where((k) => k.isNotEmpty)
        .toList();
    if (oldFiles.isEmpty) return;

    setState(() => _isLoadingFiles = true);
    try {
      for (final key in oldFiles) {
        await sl<StorageRepository>().deleteFile(key);
      }
      if (!mounted) return;
      setState(() {
        _inlineSuccess =
            'Đã dọn sạch ${oldFiles.length} ảnh CCCD đợt cũ trên Cloudflare R2.';
        _inlineError = null;
      });
      await _loadUploadedFiles();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingFiles = false;
        _inlineError =
            'Lỗi khi dọn ảnh cũ: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  Future<void> _handleScanFront() async {
    final imageUploadService = sl<ImageUploadService>();
    final picked = await imageUploadService.pickImageOnly(
      context,
      title: 'Chụp / Chọn Mặt trước CCCD',
    );
    if (picked == null || !mounted) return;

    setState(() {
      _isUploadingFront = true;
      _inlineError = null;
      _inlineSuccess = null;
    });
    try {
      final scanned = await _scanner.scanFront(picked.path);
      final expiryErr = CccdScannerService.validateExpiry(scanned.expiryDate);
      if (expiryErr != null) {
        throw Exception(expiryErr);
      }
      if (_backData != null) {
        final mismatch = CccdScannerService.crossCheck(scanned, _backData!);
        if (mismatch != null) {
          throw Exception(mismatch);
        }
      }
      if (!mounted) return;
      setState(() {
        _frontData = scanned;
        _frontPickedFile = picked;
        _frontCardUrl = picked.path;
        _isUploadingFront = false;
        _inlineError = null;
        _inlineSuccess = scanned.fromQrCode
            ? 'Đã quét mã QR mặt trước CCCD hợp lệ!'
            : 'Đã đọc thông tin mặt trước CCCD hợp lệ!';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingFront = false;
        _inlineError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _handleScanBack() async {
    final imageUploadService = sl<ImageUploadService>();
    final picked = await imageUploadService.pickImageOnly(
      context,
      title: 'Chụp / Chọn Mặt sau CCCD',
    );
    if (picked == null || !mounted) return;

    setState(() {
      _isUploadingBack = true;
      _inlineError = null;
      _inlineSuccess = null;
    });
    try {
      final scanned = await _scanner.scanBack(picked.path);
      final expiryErr = CccdScannerService.validateExpiry(
        scanned.expiryDateIso,
      );
      if (expiryErr != null) {
        throw Exception(expiryErr);
      }
      if (_frontData != null) {
        final mismatch = CccdScannerService.crossCheck(_frontData!, scanned);
        if (mismatch != null) {
          throw Exception(mismatch);
        }
      }
      if (!mounted) return;
      setState(() {
        _backData = scanned;
        _backPickedFile = picked;
        _backCardUrl = picked.path;
        _isUploadingBack = false;
        _inlineError = null;
        _inlineSuccess = 'Đã quét & đối chiếu mã MRZ mặt sau CCCD hợp lệ!';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingBack = false;
        _inlineError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Widget _buildScannedRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105.0,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.0,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
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
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.document_scanner_outlined,
                      color: AppColors.primary,
                      size: 18.0,
                    ),
                    SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        'Vui lòng chụp hoặc tải lên đủ 2 mặt CCCD gắn chip. Hệ thống sẽ tự động trích xuất Số CCCD, Họ tên, Ngày sinh và Địa chỉ thường trú — không hỗ trợ nhập thủ công.',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: AppColors.primary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: _buildCccdCard(
                      label: 'Mặt trước CCCD',
                      imageUrl: _frontCardUrl,
                      isLoading: _isUploadingFront,
                      onTap: _handleScanFront,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: _buildCccdCard(
                      label: 'Mặt sau CCCD',
                      imageUrl: _backCardUrl,
                      isLoading: _isUploadingBack,
                      onTap: _handleScanBack,
                    ),
                  ),
                ],
              ),
              if (_frontData != null) ...[
                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.06),
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
                            Icons.qr_code_scanner_rounded,
                            size: 16.0,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            _frontData!.fromQrCode
                                ? 'Thông tin giải mã từ QR CCCD'
                                : 'Thông tin trích xuất từ CCCD',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      _buildScannedRow('Số CCCD:', _frontData!.idCardNumber),
                      _buildScannedRow('Họ và tên:', _frontData!.fullName),
                      _buildScannedRow(
                        'Ngày sinh:',
                        _frontData!.dateOfBirthDisplay,
                      ),
                      _buildScannedRow('Thường trú:', _frontData!.address),
                      if ((_backData?.expiryDateDisplay ??
                              _frontData?.expiryDateDisplay) !=
                          null)
                        _buildScannedRow(
                          'Có giá trị đến:',
                          '${_backData?.expiryDateDisplay ?? _frontData?.expiryDateDisplay} (Còn hiệu lực)',
                        ),
                    ],
                  ),
                ),
              ],
              if (_inlineError != null) ...[
                const SizedBox(height: 14.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 18.0,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          _inlineError!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_inlineSuccess != null) ...[
                const SizedBox(height: 14.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.success,
                        size: 18.0,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          _inlineSuccess!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20.0),
              AppPrimaryButton(
                label: _isSubmitting
                    ? 'Đang xác thực hồ sơ...'
                    : 'Xác thực định danh C06',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        if (_frontPickedFile == null ||
                            _backPickedFile == null ||
                            _frontData == null ||
                            _backData == null) {
                          setState(() {
                            _inlineSuccess = null;
                            _inlineError =
                                'Vui lòng chụp/tải lên đủ cả Mặt trước và Mặt sau CCCD hợp lệ.';
                          });
                          return;
                        }
                        final mismatch = CccdScannerService.crossCheck(
                          _frontData!,
                          _backData!,
                        );
                        if (mismatch != null) {
                          setState(() {
                            _inlineSuccess = null;
                            _inlineError = mismatch;
                          });
                          return;
                        }
                        setState(() {
                          _isSubmitting = true;
                          _inlineError = null;
                        });

                        final uploadService = sl<ImageUploadService>();
                        final frontRes = await uploadService.uploadPickedFile(
                          _frontPickedFile!,
                          folder: 'ekyc',
                          filePrefix: 'cccd_front',
                          isPublic: false,
                        );
                        final frontKey = frontRes.fileKey;
                        if (!frontRes.isSuccess ||
                            frontKey == null ||
                            frontKey.isEmpty) {
                          if (mounted) {
                            setState(() {
                              _isSubmitting = false;
                              _inlineError =
                                  frontRes.errorMessage ??
                                  'Không thể tải ảnh mặt trước lên R2.';
                            });
                          }
                          return;
                        }

                        final backRes = await uploadService.uploadPickedFile(
                          _backPickedFile!,
                          folder: 'ekyc',
                          filePrefix: 'cccd_back',
                          isPublic: false,
                        );
                        final backKey = backRes.fileKey;
                        if (!backRes.isSuccess ||
                            backKey == null ||
                            backKey.isEmpty) {
                          try {
                            await sl<StorageRepository>().deleteFile(frontKey);
                          } catch (_) {}
                          if (mounted) {
                            setState(() {
                              _isSubmitting = false;
                              _inlineError =
                                  backRes.errorMessage ??
                                  'Không thể tải ảnh mặt sau lên R2.';
                            });
                          }
                          return;
                        }

                        final ok = await widget.authController.verifyEkyc(
                          idCardNumber: _frontData!.idCardNumber,
                          frontCardUrl: frontKey,
                          backCardUrl: backKey,
                          fullName: _frontData!.fullName,
                          dateOfBirth: _frontData!.dateOfBirth,
                          address: _frontData!.address,
                        );
                        if (!ok) {
                          // Rollback xóa 2 ảnh vừa đẩy lên R2 nếu xác thực eKYC thất bại
                          for (final k in [frontKey, backKey]) {
                            try {
                              await sl<StorageRepository>().deleteFile(k);
                            } catch (_) {}
                          }
                        }
                        setState(() => _isSubmitting = false);
                        if (!context.mounted) return;
                        if (ok) {
                          Navigator.pop(context);
                          AppSnackBar.showSuccess(
                            context,
                            'Quét CCCD & định danh C06 thành công! Thông tin cá nhân đã được đồng bộ.',
                          );
                        } else {
                          setState(() {
                            _inlineError =
                                widget.authController.errorMessage ??
                                'Xác thực eKYC thất bại.';
                          });
                        }
                      },
              ),
            ],
            if (_isLoadingFiles || _uploadedFiles.isNotEmpty) ...[
              const SizedBox(height: 20.0),
              const Divider(),
              const SizedBox(height: 10.0),
              _buildUploadedHistorySection(),
            ],
          ],
        ),
      ),
    );
  }

  String _formatUploadTime(dynamic raw) {
    final dt = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (dt == null) return '';
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${pad(dt.day)}/${pad(dt.month)}/${dt.year} ${pad(dt.hour)}:${pad(dt.minute)}';
  }

  Widget _buildUploadedHistorySection() {
    final oldCount = _uploadedFiles
        .where((f) => f['is_current'] != true)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'LỊCH SỬ ẢNH CCCD TRÊN R2 (${_uploadedFiles.length})',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.4,
              ),
            ),
            if (oldCount > 0)
              TextButton.icon(
                onPressed: _isLoadingFiles ? null : _deleteAllOldFiles,
                icon: const Icon(
                  Icons.cleaning_services_outlined,
                  size: 14.0,
                  color: AppColors.error,
                ),
                label: Text(
                  'Xóa đợt cũ ($oldCount)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8.0),
        if (_isLoadingFiles && _uploadedFiles.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
          )
        else
          ..._uploadedFiles.map((file) {
            final key = (file['file_key'] ?? '').toString();
            final isFront = key.contains('cccd_front');
            final isCurrent = file['is_current'] == true;
            final title = isFront ? 'Mặt trước CCCD' : 'Mặt sau CCCD';
            final timeStr = _formatUploadTime(file['created_at']);
            return Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 20.0,
                    color: isCurrent
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : AppColors.warning.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                isCurrent ? 'Đang dùng' : 'Đợt cũ',
                                style: TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w700,
                                  color: isCurrent
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (timeStr.isNotEmpty)
                          Text(
                            'Tải lên: $timeStr',
                            style: const TextStyle(
                              fontSize: 11.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Xem ảnh',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 18.0,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      AppDocumentViewerModal.show(
                        context,
                        title: title,
                        fileKey: key,
                        documentType: 'IDENTITY_CARD',
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Xóa ảnh trên R2',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18.0,
                      color: AppColors.error,
                    ),
                    onPressed: () => _deleteUploadedFile(key),
                  ),
                ],
              ),
            );
          }),
      ],
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
