import '../../core/network/api_client.dart';
import '../../models/storage_upload_model.dart';
import '../interfaces/storage_repository.dart';

/// Triển khai thực tế của StorageRepository kết nối Backend Express và Cloudflare R2
class ApiStorageRepository implements StorageRepository {
  final ApiClient client;

  ApiStorageRepository({required this.client});

  @override
  Future<PresignedUploadUrlModel> getPresignedUploadUrl({
    required String folder,
    required String fileName,
    required String contentType,
    bool isPublic = false,
  }) async {
    final response = await client.post(
      '/api/storage/presigned-url',
      body: {
        'folder': folder,
        'file_name': fileName,
        'content_type': contentType,
        'is_public': isPublic,
      },
    );

    if (response is Map<String, dynamic>) {
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      return PresignedUploadUrlModel.fromJson(data);
    }
    throw Exception(
      'Định dạng phản hồi Presigned URL không hợp lệ từ máy chủ.',
    );
  }

  @override
  Future<bool> uploadBinaryToR2({
    required String uploadUrl,
    required List<int> bytes,
    required String contentType,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(uploadUrl);
    final success = await client.uploadBinary(
      uri,
      bytes,
      contentType: contentType,
      extraHeaders: headers,
    );
    return success;
  }

  @override
  Future<String> confirmUploadComplete({
    required String fileKey,
    required String folder,
    Map<String, dynamic>? metadata,
  }) async {
    final payload = <String, dynamic>{'file_key': fileKey, 'folder': folder};
    if (metadata != null) {
      payload['metadata'] = metadata;
    }

    final response = await client.post(
      '/api/storage/confirm-upload',
      body: payload,
    );

    if (response is Map<String, dynamic>) {
      final downloadUrl =
          response['download_url'] ?? response['file_url'] ?? response['url'];
      if (downloadUrl != null) {
        return downloadUrl.toString();
      }
    }
    return fileKey;
  }

  @override
  Future<String> getPresignedViewUrl({
    required String fileKey,
    int expiresInSeconds = 600,
  }) async {
    final response = await client.get(
      '/api/storage/view-url',
      queryParams: {
        'file_key': fileKey,
        'expires_in': expiresInSeconds.toString(),
      },
    );

    if (response is Map<String, dynamic>) {
      final viewUrl = response['view_url'] ?? response['url'];
      if (viewUrl != null) return viewUrl.toString();
    }
    return fileKey;
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
    try {
      // 1. Xin Presigned URL từ Backend
      final presigned = await getPresignedUploadUrl(
        folder: folder,
        fileName: fileName,
        contentType: contentType,
        isPublic: isPublic,
      );

      // 2. Gửi file trực tiếp lên Cloudflare R2 qua HTTP PUT
      final isUploaded = await uploadBinaryToR2(
        uploadUrl: presigned.uploadUrl,
        bytes: bytes,
        contentType: contentType,
        headers: presigned.headers,
      );

      if (!isUploaded) {
        return UploadResultModel.failure(
          'Không thể đẩy dữ liệu lên máy chủ lưu trữ.',
        );
      }

      // 3. Xác nhận và lưu trữ bản ghi vào MySQL qua Backend
      final finalUrl = await confirmUploadComplete(
        fileKey: presigned.fileKey,
        folder: folder,
        metadata: metadata,
      );

      return UploadResultModel.success(
        fileKey: presigned.fileKey,
        downloadUrl: finalUrl.isNotEmpty ? finalUrl : presigned.downloadUrl,
      );
    } catch (e) {
      return UploadResultModel.failure(
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}
