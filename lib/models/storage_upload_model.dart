/// Mô hình dữ liệu cho liên kết tải lên trước (Cloudflare R2 Presigned Upload URL)
class PresignedUploadUrlModel {
  /// Đường dẫn HTTP PUT có chữ ký tạm thời từ R2 (sống trong 5 - 15 phút)
  final String uploadUrl;

  /// Khóa định danh tệp tin trên bucket (Object Key, ví dụ: 'avatars/1/avatar_123.jpg')
  final String fileKey;

  /// Đường dẫn tải về hoặc truy xuất công khai/riêng tư sau khi upload hoàn tất
  final String downloadUrl;

  /// Thời gian sống của link tạm tính bằng giây (mặc định 300 giây = 5 phút)
  final int expiresIn;

  /// Phương thức HTTP tải lên (thường là 'PUT')
  final String httpMethod;

  /// Các headers bắt buộc khi gửi PUT (ví dụ: Content-Type)
  final Map<String, String> headers;

  const PresignedUploadUrlModel({
    required this.uploadUrl,
    required this.fileKey,
    required this.downloadUrl,
    this.expiresIn = 300,
    this.httpMethod = 'PUT',
    this.headers = const {},
  });

  factory PresignedUploadUrlModel.fromJson(Map<String, dynamic> json) {
    return PresignedUploadUrlModel(
      uploadUrl: (json['upload_url'] ?? json['uploadUrl'] ?? '') as String,
      fileKey: (json['file_key'] ?? json['fileKey'] ?? '') as String,
      downloadUrl:
          (json['download_url'] ??
                  json['downloadUrl'] ??
                  json['file_url'] ??
                  '')
              as String,
      expiresIn:
          (json['expires_in'] ?? json['expiresIn'] as num?)?.toInt() ?? 300,
      httpMethod:
          (json['http_method'] ?? json['httpMethod'] ?? 'PUT') as String,
      headers: (json['headers'] as Map?)?.cast<String, String>() ?? const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'upload_url': uploadUrl,
    'file_key': fileKey,
    'download_url': downloadUrl,
    'expires_in': expiresIn,
    'http_method': httpMethod,
    'headers': headers,
  };
}

/// Kết quả phản hồi sau khi hoàn tất quy trình tải ảnh lên R2
class UploadResultModel {
  final bool isSuccess;
  final String? fileKey;
  final String? downloadUrl;
  final String? errorMessage;

  const UploadResultModel({
    required this.isSuccess,
    this.fileKey,
    this.downloadUrl,
    this.errorMessage,
  });

  factory UploadResultModel.success({
    required String fileKey,
    required String downloadUrl,
  }) {
    return UploadResultModel(
      isSuccess: true,
      fileKey: fileKey,
      downloadUrl: downloadUrl,
    );
  }

  factory UploadResultModel.failure(String message) {
    return UploadResultModel(isSuccess: false, errorMessage: message);
  }
}
