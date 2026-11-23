import 'dart:io';

import 'package:flutter/painting.dart';

/// Dịch vụ quản lý và dọn dẹp bộ nhớ đệm (Cache) cục bộ của ứng dụng FinCredit
class CacheService {
  static const Set<String> _protectedTempNames = {'fincredit_storage'};

  final Directory? customCacheDir;
  final Directory? customSystemTempDir;
  final void Function()? onClearMemoryCaches;
  final bool includeFlutterImageCache;

  CacheService({
    this.customCacheDir,
    this.customSystemTempDir,
    this.onClearMemoryCaches,
    this.includeFlutterImageCache = true,
  });

  /// Đường dẫn thư mục cache riêng của ứng dụng
  Directory get appCacheDirectory {
    if (customCacheDir != null) return customCacheDir!;
    final path = '${_systemTempDirectory.path}/fincredit_app_cache';
    return Directory(path);
  }

  Directory get _systemTempDirectory =>
      customSystemTempDir ?? Directory.systemTemp;

  /// Tính toán dung lượng bộ nhớ đệm của ứng dụng (bytes)
  Future<int> getCacheSizeBytes() async {
    try {
      int total = 0;

      final cacheDir = appCacheDirectory;
      if (await cacheDir.exists()) {
        total += await _calculateDirectorySize(cacheDir);
      }

      // Cộng thêm các file/thư mục ảnh tạm do ứng dụng/image_picker tạo ra trong temp hệ thống
      final sysTemp = _systemTempDirectory;
      if (await sysTemp.exists()) {
        final entities = sysTemp.listSync(followLinks: false);
        for (final entity in entities) {
          final name = _extractEntityName(entity);
          if (_isAppTemporaryEntity(name)) {
            if (entity is File) {
              try {
                total += await entity.length();
              } catch (_) {}
            } else if (entity is Directory) {
              total += await _calculateDirectorySize(entity);
            }
          }
        }
      }

      // Cộng thêm bộ nhớ đệm ảnh giải mã trong RAM của Flutter (nếu binding đã khởi tạo)
      if (includeFlutterImageCache) {
        try {
          total += PaintingBinding.instance.imageCache.currentSizeBytes;
        } catch (_) {}
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

  /// Dọn dẹp an toàn các tệp tạm trên đĩa và bộ nhớ đệm ảnh/URL trong RAM.
  /// TUYỆT ĐỐI KHÔNG xóa `fincredit_storage` (phiên đăng nhập) hay tệp của tiến trình khác.
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
      final sysTemp = _systemTempDirectory;
      if (await sysTemp.exists()) {
        final entities = sysTemp.listSync(followLinks: false);
        for (final entity in entities) {
          final name = _extractEntityName(entity);
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

      // Dọn bộ nhớ đệm ảnh trong RAM của Flutter
      if (includeFlutterImageCache) {
        try {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
        } catch (_) {}
      }

      // Dọn các bộ nhớ đệm trong RAM khác (VD: Presigned View URL của R2)
      try {
        onClearMemoryCaches?.call();
      } catch (_) {}

      return true;
    } catch (_) {
      return false;
    }
  }

  String _extractEntityName(FileSystemEntity entity) {
    if (entity.uri.pathSegments.isEmpty) return '';
    return entity.uri.pathSegments.lastWhere(
      (s) => s.isNotEmpty,
      orElse: () => '',
    );
  }

  bool _isAppTemporaryEntity(String name) {
    if (name.isEmpty) return false;
    if (_protectedTempNames.contains(name)) return false;
    if (name == 'fincredit_app_cache') return false;
    // Chỉ nhận diện các file ảnh/tài liệu tạm của ứng dụng FinCredit & image_picker
    return name.startsWith('image_picker_') ||
        name.startsWith('scaled_') ||
        name.startsWith('fincredit_tmp_') ||
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
