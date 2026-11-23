import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/services/cache_service.dart';

void main() {
  group('CacheService Unit Tests', () {
    late Directory testRootDir;
    late Directory testCacheDir;
    late Directory testSystemTempDir;
    late CacheService cacheService;
    late bool memoryCleared;

    setUp(() {
      memoryCleared = false;
      final testPath =
          '${Directory.systemTemp.path}/test_fincredit_cache_${DateTime.now().microsecondsSinceEpoch}';
      testRootDir = Directory(testPath)..createSync(recursive: true);
      testCacheDir = Directory('${testRootDir.path}/fincredit_app_cache')
        ..createSync(recursive: true);
      testSystemTempDir = Directory('${testRootDir.path}/sys_temp')
        ..createSync(recursive: true);
      cacheService = CacheService(
        customCacheDir: testCacheDir,
        customSystemTempDir: testSystemTempDir,
        onClearMemoryCaches: () => memoryCleared = true,
      );
    });

    tearDown(() {
      if (testRootDir.existsSync()) {
        try {
          testRootDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test(
      'getCacheSizeBytes và getFormattedCacheSize trả về định dạng dung lượng chuẩn',
      () async {
        final testFile = File('${testCacheDir.path}/sample.dat');
        await testFile.writeAsBytes(List.generate(2048, (i) => i % 256));

        final bytes = await cacheService.getCacheSizeBytes();
        expect(bytes, greaterThanOrEqualTo(2048));

        final formatted = await cacheService.getFormattedCacheSize();
        expect(formatted, isNotEmpty);
        expect(formatted.contains('KB') || formatted.contains('MB'), isTrue);
      },
    );

    test(
      'getCacheSizeBytes vẫn quét được file tạm trong systemTemp ngay cả khi appCacheDirectory chưa tồn tại',
      () async {
        final nonExistentAppCache = Directory(
          '${testRootDir.path}/non_existent_app_cache',
        );
        final serviceWithoutAppCache = CacheService(
          customCacheDir: nonExistentAppCache,
          customSystemTempDir: testSystemTempDir,
          includeFlutterImageCache: false,
        );

        final pickerFile = File('${testSystemTempDir.path}/image_picker_1.jpg');
        await pickerFile.writeAsBytes(List.generate(4096, (i) => i % 256));

        final scaledFile = File('${testSystemTempDir.path}/scaled_photo.jpg');
        await scaledFile.writeAsBytes(List.generate(1024, (i) => i % 256));

        final bytes = await serviceWithoutAppCache.getCacheSizeBytes();
        expect(bytes, equals(5120));

        final formatted = await serviceWithoutAppCache.getFormattedCacheSize();
        expect(formatted, equals('5.0 KB'));
      },
    );

    test(
      'clearCache dọn dẹp appCacheDirectory, các file tạm hợp lệ và gọi callback dọn RAM',
      () async {
        final appCacheFile = File('${testCacheDir.path}/to_delete.dat');
        await appCacheFile.writeAsString('test cache content');

        final pickerFile = File('${testSystemTempDir.path}/image_picker_a.jpg');
        await pickerFile.writeAsString('picker temp');

        final ocrDir = Directory('${testSystemTempDir.path}/ocr_tmp_batch')
          ..createSync(recursive: true);
        final ocrFile = File('${ocrDir.path}/page1.png');
        await ocrFile.writeAsString('ocr temp');

        final fincreditTmpFile = File(
          '${testSystemTempDir.path}/fincredit_tmp_pdf.pdf',
        );
        await fincreditTmpFile.writeAsString('pdf temp');

        final result = await cacheService.clearCache();
        expect(result, isTrue);
        expect(memoryCleared, isTrue);
        expect(appCacheFile.existsSync(), isFalse);
        expect(pickerFile.existsSync(), isFalse);
        expect(ocrDir.existsSync(), isFalse);
        expect(fincreditTmpFile.existsSync(), isFalse);
      },
    );

    test(
      'clearCache TUYỆT ĐỐI KHÔNG xóa fincredit_storage (phiên đăng nhập) hoặc file của tiến trình khác',
      () async {
        final sessionDir = Directory(
          '${testSystemTempDir.path}/fincredit_storage',
        )..createSync(recursive: true);
        final sessionFile = File('${sessionDir.path}/session_v1.json');
        await sessionFile.writeAsString('{"token":"keep-me"}');

        final otherToolDir = Directory(
          '${testSystemTempDir.path}/flutter_tools',
        )..createSync(recursive: true);
        final otherFile = File('${otherToolDir.path}/lock');
        await otherFile.writeAsString('keep');

        final result = await cacheService.clearCache();
        expect(result, isTrue);
        expect(sessionDir.existsSync(), isTrue);
        expect(sessionFile.existsSync(), isTrue);
        expect(otherToolDir.existsSync(), isTrue);
        expect(otherFile.existsSync(), isTrue);
      },
    );

    test(
      'getFormattedCacheSize trả về 0.0 MB khi không có dữ liệu cache',
      () async {
        final emptyService = CacheService(
          customCacheDir: testCacheDir,
          customSystemTempDir: testSystemTempDir,
          includeFlutterImageCache: false,
        );
        expect(await emptyService.getFormattedCacheSize(), equals('0.0 MB'));
      },
    );
  });
}
