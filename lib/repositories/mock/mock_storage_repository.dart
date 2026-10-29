import '../../models/storage_upload_model.dart';
import '../interfaces/storage_repository.dart';

/// Triển khai Mock của StorageRepository phục vụ chạy thử nghiệm cục bộ & kiểm thử tự động
class MockStorageRepository implements StorageRepository {
  /// Bộ nhớ tạm mô phỏng các tệp đã tải lên thành công trên Cloudflare R2
  static final Map<String, String> uploadedFilesDatabase = {};

  @override
  Future<PresignedUploadUrlModel> getPresignedUploadUrl({
    required String folder,
    required String fileName,
    required String contentType,
    bool isPublic = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final cleanFileName = fileName.replaceAll(' ', '_');
    final fileKey = '$folder/${timestamp}_$cleanFileName';

    // Tạo link ký PUT mô phỏng
    final uploadUrl =
        'https://fincredit-mock.r2.cloudflarestorage.com/$fileKey?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Expires=300';

    final downloadUrl = isPublic
        ? 'https://pub-r2.fincredit.vn/$fileKey'
        : 'https://private-r2.fincredit.vn/$fileKey?token=mock_secure_jwt';

    return PresignedUploadUrlModel(
      uploadUrl: uploadUrl,
      fileKey: fileKey,
      downloadUrl: downloadUrl,
      expiresIn: 300,
      httpMethod: 'PUT',
      headers: {'Content-Type': contentType},
    );
  }

  @override
  Future<bool> uploadBinaryToR2({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
    Map<String, String>? headers,
  }) async {
    // Giả lập độ trễ truyền dữ liệu mạng 200ms
    await Future.delayed(const Duration(milliseconds: 200));
    return bytes.isNotEmpty;
  }

  @override
  Future<String> confirmUploadComplete({
    required String fileKey,
    required String folder,
    Map<String, dynamic>? metadata,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final finalUrl = 'https://pub-r2.fincredit.vn/$fileKey';
    uploadedFilesDatabase[fileKey] = finalUrl;
    return finalUrl;
  }

  @override
  Future<String> getPresignedViewUrl({
    required String fileKey,
    int expiresInSeconds = 600,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Giả lập Presigned GET URL của R2 với token chữ ký bảo mật 10 phút
    return 'https://private-r2.fincredit.vn/$fileKey?X-Amz-Signature=mock_view_sig&expires=$expiresInSeconds';
  }

  @override
  Future<UploadResultModel> uploadImageFile({
    required List<int> bytes,
    required String folder,
    required String fileName,
    required String contentType,
    bool isPublic = false,
    Map<String, dynamic>? metadata,
  }) async {
    if (bytes.isEmpty) {
      return UploadResultModel.failure('Tệp ảnh rỗng, không thể tải lên.');
    }

    final presigned = await getPresignedUploadUrl(
      folder: folder,
      fileName: fileName,
      contentType: contentType,
      isPublic: isPublic,
    );

    final uploaded = await uploadBinaryToR2(
      uploadUrl: presigned.uploadUrl,
      bytes: bytes,
      contentType: contentType,
    );

    if (!uploaded) {
      return UploadResultModel.failure('Giả lập tải tệp lên R2 thất bại.');
    }

    final finalUrl = await confirmUploadComplete(
      fileKey: presigned.fileKey,
      folder: folder,
      metadata: metadata,
    );

    return UploadResultModel.success(
      fileKey: presigned.fileKey,
      downloadUrl: finalUrl,
    );
  }
}
