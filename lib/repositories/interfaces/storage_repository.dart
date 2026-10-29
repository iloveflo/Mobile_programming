import '../../models/storage_upload_model.dart';

/// Hợp đồng giao tiếp dịch vụ lưu trữ đám mây (Cloudflare R2 Object Storage)
abstract class StorageRepository {
  /// Bước 2 trong sơ đồ: Yêu cầu Backend cấp Presigned URL có chữ ký tạm để upload
  Future<PresignedUploadUrlModel> getPresignedUploadUrl({
    required String folder,
    required String fileName,
    required String contentType,
    bool isPublic = false,
  });

  /// Bước 3 trong sơ đồ: Đẩy trực tiếp dữ liệu nhị phân (bytes) lên Cloudflare R2 qua HTTP PUT
  Future<bool> uploadBinaryToR2({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
    Map<String, String>? headers,
  });

  /// Bước 4 trong sơ đồ: Thông báo Backend lưu file_key vào CSDL MySQL sau khi upload R2 thành công
  Future<String> confirmUploadComplete({
    required String fileKey,
    required String folder,
    Map<String, dynamic>? metadata,
  });

  /// Lấy Presigned GET URL tạm thời có chữ ký để người dùng xem tệp riêng tư (Private) trên Cloudflare R2
  Future<String> getPresignedViewUrl({
    required String fileKey,
    int expiresInSeconds = 600,
  });

  /// Hàm điều phối trọn gói toàn bộ chu trình 4 bước (Tiện ích cấp cao)
  Future<UploadResultModel> uploadImageFile({
    required List<int> bytes,
    required String folder,
    required String fileName,
    required String contentType,
    bool isPublic = false,
    Map<String, dynamic>? metadata,
  });
}
