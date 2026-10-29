import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/services/cache_service.dart';

void main() {
  group('CacheService Unit Tests', () {
    late Directory testCacheDir;
    late CacheService cacheService;

    setUp(() {
      final testPath =
          '${Directory.systemTemp.path}/test_fincredit_cache_${DateTime.now().microsecondsSinceEpoch}';
      testCacheDir = Directory(testPath);
      testCacheDir.createSync(recursive: true);
      cacheService = CacheService(customCacheDir: testCacheDir);
    });

    tearDown(() {
      if (testCacheDir.existsSync()) {
        try {
          testCacheDir.deleteSync(recursive: true);
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
      'clearCache thực thi dọn dẹp các tệp tạm trong bộ nhớ đệm an toàn',
      () async {
        final testFile = File('${testCacheDir.path}/to_delete.dat');
        await testFile.writeAsString('test cache content');
        expect(testFile.existsSync(), isTrue);

        final result = await cacheService.clearCache();
        expect(result, isTrue);
        expect(testFile.existsSync(), isFalse);
      },
    );
  });
}
