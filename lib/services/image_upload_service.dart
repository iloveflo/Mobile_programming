import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/storage_upload_model.dart';
import '../repositories/interfaces/storage_repository.dart';
import '../widgets/common/app_colors.dart';

/// Dịch vụ tiện ích chọn ảnh từ thiết bị, nén và tải lên Cloudflare R2
class ImageUploadService {
  final StorageRepository storageRepository;
  final ImagePicker picker;

  ImageUploadService({required this.storageRepository, ImagePicker? picker})
    : picker = picker ?? ImagePicker();

  /// Hiển thị Bottom Sheet cho người dùng chọn giữa Chụp ảnh (Camera) hoặc Thư viện (Gallery)
  Future<ImageSource?> showSourceSelector(
    BuildContext context, {
    String title = 'Chọn nguồn hình ảnh',
    String subtitle = 'Tải ảnh chất lượng cao lên máy chủ bảo mật FinCredit',
  }) async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 14.0),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.0,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16.0),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.primary,
                  size: 22.0,
                ),
              ),
              title: const Text(
                'Chụp ảnh trực tiếp bằng Camera',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: const Text(
                'Sử dụng camera thiết bị để chụp hợp đồng hoặc tài liệu',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const Divider(height: 12.0),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF0891B2).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFF0891B2),
                  size: 22.0,
                ),
              ),
              title: const Text(
                'Chọn ảnh từ Thư viện (Gallery)',
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: const Text(
                'Tải tệp ảnh có sẵn từ bộ nhớ thiết bị',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }

  /// Quy trình chọn và tải ảnh hoàn chỉnh:
  /// 1. Mở bộ chọn (Camera / Thư viện)
  /// 2. Tự động nén chất lượng & kích thước tối ưu
  /// 3. Xin Presigned URL từ Backend
  /// 4. Đẩy nhị phân lên Cloudflare R2
  /// 5. Báo Backend lưu vào CSDL
  Future<UploadResultModel?> pickAndUploadImage(
    BuildContext context, {
    required String folder,
    required String filePrefix,
    bool isPublic = false,
    String title = 'Chọn nguồn hình ảnh',
    Map<String, dynamic>? metadata,
  }) async {
    final source = await showSourceSelector(context, title: title);
    if (source == null) return null;

    try {
      // 1. Chọn và nén tự động (giới hạn 1600px, chất lượng 85% để tối ưu dung lượng)
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();
      final extension = pickedFile.name.contains('.')
          ? pickedFile.name.split('.').last.toLowerCase()
          : 'jpg';

      final contentType = extension == 'png'
          ? 'image/png'
          : extension == 'webp'
          ? 'image/webp'
          : 'image/jpeg';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${filePrefix}_$timestamp.$extension';

      // 2. Chạy quy trình Upload qua StorageRepository
      return await storageRepository.uploadImageFile(
        bytes: bytes,
        folder: folder,
        fileName: fileName,
        contentType: contentType,
        isPublic: isPublic,
        metadata: metadata,
      );
    } catch (e) {
      return UploadResultModel.failure(
        'Lỗi xử lý hình ảnh: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }
}
