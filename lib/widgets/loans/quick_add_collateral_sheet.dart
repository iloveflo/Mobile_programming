import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/loan_controller.dart';
import '../../models/collateral_model.dart';
import '../../repositories/interfaces/storage_repository.dart';
import '../../service_locator.dart';
import '../../services/collateral_scanner_service.dart';
import '../../services/image_upload_service.dart';
import '../widget.dart';

/// Modal BottomSheet thêm tài sản bảo đảm hoàn toàn tự động qua quét chứng từ (không cho nhập tay)
class QuickAddCollateralSheet extends StatefulWidget {
  final LoanController loanController;
  final ValueChanged<CollateralModel> onCollateralAdded;
  final String? loanId;

  const QuickAddCollateralSheet({
    super.key,
    required this.loanController,
    required this.onCollateralAdded,
    this.loanId,
  });

  /// Phương thức hiển thị modal
  static Future<void> show(
    BuildContext context, {
    required LoanController loanController,
    required ValueChanged<CollateralModel> onCollateralAdded,
    String? loanId,
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
        loanId: loanId,
      ),
    );
  }

  @override
  State<QuickAddCollateralSheet> createState() =>
      _QuickAddCollateralSheetState();
}

class _QuickAddCollateralSheetState extends State<QuickAddCollateralSheet> {
  final CollateralScannerService _scanner = CollateralScannerService();
  String _selectedType = 'REAL_ESTATE';
  bool _isLoading = false;
  bool _isScanningDoc = false;
  XFile? _pickedDocFile;
  CollateralScanResult? _scanResult;
  String? _inlineError;
  String? _inlineSuccess;

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

  Future<void> _handleScanLegalDoc() async {
    final user = sl.isRegistered<AuthController>()
        ? sl<AuthController>().currentUser
        : null;
    if (user == null ||
        !user.isEkycVerified ||
        user.idCardNumber == null ||
        user.idCardNumber!.trim().length != 12) {
      setState(() {
        _inlineError =
            'Vui lòng xác thực định danh eKYC CCCD ở Hồ sơ cá nhân trước khi đăng ký tài sản bảo đảm.';
        _inlineSuccess = null;
      });
      return;
    }

    final uploadService = sl<ImageUploadService>();
    final picked = await uploadService.pickImageOnly(
      context,
      title: 'Chụp / Chọn Giấy tờ pháp lý tài sản',
    );
    if (picked == null || !mounted) return;

    setState(() {
      _isScanningDoc = true;
      _inlineError = null;
      _inlineSuccess = null;
    });

    try {
      final scanned = await _scanner.scanAndVerify(
        picked.path,
        assetType: _selectedType,
        expectedIdCardNumber: user.idCardNumber!,
        expectedOwnerName: user.fullName,
      );

      final config = CollateralModel.getConfig(_selectedType);
      if (scanned.extractedValue < config.minValue ||
          scanned.extractedValue > config.maxValue) {
        throw Exception(
          'Giá trị trên chứng từ (${_formatCurrency(scanned.extractedValue)}) nằm ngoài hạn mức ${config.displayName} (${config.limitRangeText}).',
        );
      }

      setState(() {
        _scanResult = scanned;
        _pickedDocFile = picked;
        _isScanningDoc = false;
        _inlineError = null;
        _inlineSuccess =
            'Đã kiểm định chính chủ (${scanned.ownerIdCard})! Bấm Lưu để hoàn tất.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanningDoc = false;
        _scanResult = null;
        _pickedDocFile = null;
        _inlineError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112.0,
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
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = CollateralModel.getConfig(_selectedType);

    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 14.0),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Icon(
                    Icons.add_home_work_outlined,
                    color: AppColors.primary,
                    size: 20.0,
                  ),
                ),
                const SizedBox(width: 10.0),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đăng ký tài sản bảo đảm mới',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Bắt buộc trích xuất trực tiếp từ ảnh giấy tờ chính chủ',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // 1. Chọn loại tài sản
            const Text(
              'Loại tài sản',
              style: TextStyle(
                fontSize: 12.5,
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
                if (val != null && val != _selectedType) {
                  setState(() {
                    _selectedType = val;
                    _scanResult = null;
                    _pickedDocFile = null;
                    _inlineError = null;
                    _inlineSuccess = null;
                  });
                }
              },
            ),
            const SizedBox(height: 6.0),
            Text(
              'Hạn mức ${config.displayName}: ${config.limitRangeText}',
              style: const TextStyle(
                fontSize: 11.0,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14.0),

            // 2. Chụp / Tải giấy tờ pháp lý (bắt buộc, không cho nhập tay)
            InkWell(
              onTap: _isScanningDoc ? null : _handleScanLegalDoc,
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: _pickedDocFile != null
                      ? AppColors.success.withValues(alpha: 0.08)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: _pickedDocFile != null
                        ? AppColors.success
                        : AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    if (_isScanningDoc)
                      const SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    else
                      Icon(
                        _pickedDocFile != null
                            ? Icons.verified_rounded
                            : Icons.document_scanner_outlined,
                        color: _pickedDocFile != null
                            ? AppColors.success
                            : AppColors.primary,
                        size: 24.0,
                      ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _pickedDocFile != null
                                ? 'Đã kiểm định chứng từ hợp lệ'
                                : 'Chụp / Tải giấy tờ pháp lý (Bắt buộc)',
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w700,
                              color: _pickedDocFile != null
                                  ? AppColors.success
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            _pickedDocFile != null
                                ? 'Chạm để quét lại giấy tờ khác'
                                : 'Sổ hồng / Cavet xe / Sổ tiết kiệm / Chứng thư thẩm định có ghi giá trị',
                            style: const TextStyle(
                              fontSize: 11.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Khung kết quả trích xuất tự động (chỉ đọc)
            if (_scanResult != null) ...[
              const SizedBox(height: 14.0),
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 15.0,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 6.0),
                        Text(
                          'THÔNG TIN TRÍCH XUẤT TỰ ĐỘNG',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    _buildInfoRow('Tên tài sản:', _scanResult!.extractedName),
                    _buildInfoRow(
                      'Giá trị định giá:',
                      _formatCurrency(_scanResult!.extractedValue),
                      valueColor: AppColors.primary,
                    ),
                    _buildInfoRow('CCCD chủ sở hữu:', _scanResult!.ownerIdCard),
                    if (_scanResult!.certificateNumber != null)
                      _buildInfoRow(
                        'Mã chứng từ / BKS:',
                        _scanResult!.certificateNumber!,
                      ),
                    _buildInfoRow(
                      'Thẩm quyền:',
                      'Đủ điều kiện thế chấp',
                      valueColor: AppColors.success,
                    ),
                  ],
                ),
              ),
            ],

            if (_inlineError != null) ...[
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(10.0),
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
                      size: 17.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _inlineError!,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_inlineSuccess != null) ...[
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(10.0),
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
                      size: 17.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _inlineSuccess!,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18.0),

            // 4. Nút Lưu
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
                onPressed: (_isLoading || _isScanningDoc)
                    ? null
                    : () async {
                        if (_pickedDocFile == null || _scanResult == null) {
                          setState(() {
                            _inlineSuccess = null;
                            _inlineError =
                                'Vui lòng chụp/tải lên và kiểm định giấy tờ pháp lý hợp lệ trước khi lưu.';
                          });
                          return;
                        }

                        setState(() {
                          _isLoading = true;
                          _inlineError = null;
                        });

                        // Chỉ đẩy ảnh lên R2 khi người dùng bấm Lưu chính thức
                        final uploadRes = await sl<ImageUploadService>()
                            .uploadPickedFile(
                              _pickedDocFile!,
                              folder: 'legal-documents',
                              filePrefix: 'asset_doc',
                              isPublic: false,
                            );

                        if (!context.mounted) return;
                        final uploadedKey = uploadRes.fileKey;
                        if (!uploadRes.isSuccess ||
                            uploadedKey == null ||
                            uploadedKey.isEmpty) {
                          setState(() {
                            _isLoading = false;
                            _inlineError =
                                uploadRes.errorMessage ??
                                'Không thể tải giấy tờ lên Cloudflare R2.';
                          });
                          return;
                        }

                        final success = await widget.loanController.addCollateral(
                          name: _scanResult!.extractedName,
                          type: _selectedType,
                          value: _scanResult!.extractedValue,
                          loanId: widget.loanId,
                          description:
                              'Xác thực tự động từ chứng từ chính chủ (${_scanResult!.ownerIdCard})',
                          legalDocumentUrl: uploadedKey,
                          certificateNumber: _scanResult!.certificateNumber,
                          valuationDate: DateTime.now()
                              .toIso8601String()
                              .split('T')
                              .first,
                        );

                        if (!success) {
                          // Rollback xóa ảnh vừa đẩy lên R2 nếu lưu tài sản thất bại
                          try {
                            await sl<StorageRepository>().deleteFile(
                              uploadedKey,
                            );
                          } catch (_) {}
                        }

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
                            'Đã đăng ký tài sản "${_scanResult!.extractedName}" (${_formatCurrency(_scanResult!.extractedValue)})!',
                          );
                        } else {
                          setState(() {
                            _inlineError =
                                widget.loanController.errorMessage ??
                                'Không thể thêm tài sản.';
                          });
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
    );
  }
}
