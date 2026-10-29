import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/repositories/interfaces/storage_repository.dart';
import 'package:my_first_app/service_locator.dart';

void main() {
  setUpAll(() {
    setupServiceLocator(isMock: true);
  });

  group('Cloudflare R2 Presigned Upload & Storage Tests', () {
    late StorageRepository storageRepository;

    setUp(() {
      storageRepository = sl<StorageRepository>();
    });

    test(
      '1. Yêu cầu Presigned URL hợp lệ cho ảnh Avatar (Public Bucket)',
      () async {
        final result = await storageRepository.getPresignedUploadUrl(
          folder: 'avatars/1',
          fileName: 'avatar.webp',
          contentType: 'image/webp',
          isPublic: true,
        );

        expect(result.uploadUrl, contains('r2.cloudflarestorage.com'));
        expect(result.uploadUrl, contains('avatars/1'));
        expect(result.fileKey, contains('avatars/1'));
        expect(result.downloadUrl, contains('pub-r2.fincredit.vn'));
        expect(result.httpMethod, equals('PUT'));
        expect(result.expiresIn, equals(300));
      },
    );

    test(
      '2. Yêu cầu Presigned URL cho tài liệu Hợp đồng OCR (Private Bucket)',
      () async {
        final result = await storageRepository.getPresignedUploadUrl(
          folder: 'contracts/ocr',
          fileName: 'contract_scan.pdf',
          contentType: 'application/pdf',
          isPublic: false,
        );

        expect(result.uploadUrl, contains('r2.cloudflarestorage.com'));
        expect(result.fileKey, contains('contracts/ocr'));
        expect(result.downloadUrl, contains('private-r2.fincredit.vn'));
        expect(result.headers['Content-Type'], equals('application/pdf'));
      },
    );

    test(
      '3. Upload binary lên R2 qua HTTP PUT và xác nhận hoàn tất thành công',
      () async {
        final dummyBytes = [1, 2, 3, 4, 5, 6, 7, 8];

        final uploadResult = await storageRepository.uploadImageFile(
          bytes: dummyBytes,
          folder: 'avatars/1',
          fileName: 'test_avatar.jpg',
          contentType: 'image/jpeg',
          isPublic: true,
        );

        expect(uploadResult.isSuccess, isTrue);
        expect(uploadResult.fileKey, isNotNull);
        expect(uploadResult.downloadUrl, contains('pub-r2.fincredit.vn'));
        expect(uploadResult.errorMessage, isNull);
      },
    );

    test('4. Xử lý ngoại lệ an toàn khi tệp bytes rỗng', () async {
      final emptyBytes = <int>[];

      final uploadResult = await storageRepository.uploadImageFile(
        bytes: emptyBytes,
        folder: 'contracts/ocr',
        fileName: 'empty.jpg',
        contentType: 'image/jpeg',
      );

      expect(uploadResult.isSuccess, isFalse);
      expect(uploadResult.errorMessage, contains('rỗng'));
    });
  });
}
