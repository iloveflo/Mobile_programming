import 'dart:io';

/// Dịch vụ quản lý và dọn dẹp bộ nhớ đệm (Cache) cục bộ của ứng dụng FinCredit
class CacheService {
  final Directory? customCacheDir;

  CacheService({this.customCacheDir});

  /// Thư mục lưu trữ bộ nhớ đệm độc quyền của ứng dụng FinCredit
  Directory get appCacheDirectory {
    if (customCacheDir != null) return customCacheDir!;
    final path = '${Directory.systemTemp.path}/fincredit_app_cache';
    final dir = Directory(path);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Tính toán dung lượng bộ nhớ đệm của ứng dụng (bytes)
  Future<int> getCacheSizeBytes() async {
    try {
      final cacheDir = appCacheDirectory;
      if (!await cacheDir.exists()) return 0;

      int total = await _calculateDirectorySize(cacheDir);

      // Cộng thêm các file ảnh tạm do ứng dụng/image_picker tạo ra trong temp hệ thống
      final sysTemp = Directory.systemTemp;
      if (await sysTemp.exists()) {
        final entities = sysTemp.listSync(followLinks: false);
        for (final entity in entities) {
          final name = entity.uri.pathSegments.isNotEmpty
              ? entity.uri.pathSegments.lastWhere(
                  (s) => s.isNotEmpty,
                  orElse: () => '',
                )
              : '';
          if (_isAppTemporaryEntity(name) && entity is File) {
            try {
              total += await entity.length();
            } catch (_) {}
          }
        }
      }

      return total;
    } catch (_) {
      return 0;
    }
  }

  /// Định dạng dung lượng thành chuỗi hiển thị thân thiện (MB, KB)
  Future<String> getFormattedCacheSize() async {
    final bytes = await getCacheSizeBytes();
    if (bytes <= 0) return '0.0 MB';
    final mb = bytes / (1024 * 1024);
    if (mb < 0.1) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Dọn dẹp an toàn các tệp và thư mục con trong bộ nhớ đệm ứng dụng
  /// TUYỆT ĐỐI KHÔNG xóa các file của tiến trình khác hay flutter_tools trong /tmp
  Future<bool> clearCache() async {
    try {
      final cacheDir = appCacheDirectory;
      if (await cacheDir.exists()) {
        final entities = cacheDir.listSync(followLinks: false);
        for (final entity in entities) {
          try {
            if (entity is File) {
              await entity.delete();
            } else if (entity is Directory) {
              await entity.delete(recursive: true);
            }
          } catch (_) {}
        }
      }

      // Xóa các file ảnh/tài liệu tạm do camera/image_picker sinh ra
      final sysTemp = Directory.systemTemp;
      if (await sysTemp.exists()) {
        final entities = sysTemp.listSync(followLinks: false);
        for (final entity in entities) {
          final name = entity.uri.pathSegments.isNotEmpty
              ? entity.uri.pathSegments.lastWhere(
                  (s) => s.isNotEmpty,
                  orElse: () => '',
                )
              : '';
          if (_isAppTemporaryEntity(name)) {
            try {
              if (entity is File) {
                await entity.delete();
              } else if (entity is Directory) {
                await entity.delete(recursive: true);
              }
            } catch (_) {}
          }
        }
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isAppTemporaryEntity(String name) {
    if (name.isEmpty) return false;
    // Chỉ nhận diện các file ảnh/tài liệu tạm của ứng dụng FinCredit & image_picker
    return name.startsWith('image_picker_') ||
        name.startsWith('scaled_') ||
        name.startsWith('fincredit_') ||
        name.startsWith('avatar_tmp_') ||
        name.startsWith('ocr_tmp_');
  }

  Future<int> _calculateDirectorySize(Directory dir) async {
    int total = 0;
    try {
      final entities = dir.listSync(recursive: true, followLinks: false);
      for (final entity in entities) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return total;
  }
}
