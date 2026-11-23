import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/services/cccd_scanner_service.dart';

void main() {
  group('CccdScannerService - QR, OCR & MRZ Cross-check', () {
    test('Parse đúng chuỗi QR Code chuẩn Bộ Công An từ mẫu CCCD', () {
      const qr =
          '034205014023||Nguyễn Văn Bình|02122005|Nam|Tổ Dân Phố 3, Thị trấn An Bài, Quỳnh Phụ, Thái Bình|16082021';
      final front = CccdScannerService.parseQrPayload(qr);

      expect(front, isNotNull);
      expect(front!.idCardNumber, '034205014023');
      expect(front.fullName, 'Nguyễn Văn Bình');
      expect(front.dateOfBirth, '2005-12-02');
      expect(front.dateOfBirthDisplay, '02/12/2005');
      expect(
        front.address,
        'Tổ Dân Phố 3, Thị trấn An Bài, Quỳnh Phụ, Thái Bình',
      );
      expect(front.fromQrCode, isTrue);
    });

    test('Parse đúng 3 dòng MRZ mặt sau CCCD và đối chiếu chéo khớp 100%', () {
      const qr =
          '034205014023||Nguyễn Văn Bình|02122005|Nam|Tổ Dân Phố 3, Thị trấn An Bài, Quỳnh Phụ, Thái Bình|16082021';
      final front = CccdScannerService.parseQrPayload(qr)!;

      final back = CccdScannerService.parseMrzLines([
        'IDVNM2050140235034205014023<<8',
        '0512022M3012028VNM<<<<<<<<<<<0',
        'NGUYEN<<VAN<BINH<<<<<<<<<<<<<<',
      ]);

      expect(back, isNotNull);
      expect(back!.idCardNumber, '034205014023');
      expect(back.birthYyMmDd, '051202');
      expect(back.expiryYyMmDd, '301202');
      expect(back.expiryDateIso, '2030-12-02');
      expect(back.expiryDateDisplay, '02/12/2030');
      expect(back.fullNameAscii, 'NGUYEN VAN BINH');

      expect(
        CccdScannerService.crossCheck(front, back, now: DateTime(2026, 11, 20)),
        isNull,
      );
    });

    test('Từ chối ngay nếu thẻ CCCD đã hết hạn sử dụng', () {
      const qr =
          '034205014023||Nguyễn Văn Bình|02122005|Nam|Tổ Dân Phố 3, Thị trấn An Bài, Quỳnh Phụ, Thái Bình|16082021';
      final front = CccdScannerService.parseQrPayload(qr)!;

      final expiredBack = CccdScannerService.parseMrzLines([
        'IDVNM2050140235034205014023<<8',
        '0512022M2412028VNM<<<<<<<<<<<0',
        'NGUYEN<<VAN<BINH<<<<<<<<<<<<<<',
      ])!;

      final err = CccdScannerService.crossCheck(
        front,
        expiredBack,
        now: DateTime(2026, 11, 20),
      );
      expect(err, isNotNull);
      expect(err, contains('hết hạn sử dụng'));
    });

    test('Phát hiện và từ chối khi 2 mặt CCCD không cùng một người', () {
      const qr =
          '034205014023||Nguyễn Văn Bình|02122005|Nam|Tổ Dân Phố 3, Thị trấn An Bài, Quỳnh Phụ, Thái Bình|16082021';
      final front = CccdScannerService.parseQrPayload(qr)!;

      final mismatchedBack = CccdScannerService.parseMrzLines([
        'IDVNM2050140235079201008888<<8',
        '9805122M3012028VNM<<<<<<<<<<<0',
        'TRAN<<VAN<NAM<<<<<<<<<<<<<<<<<',
      ])!;

      final error = CccdScannerService.crossCheck(front, mismatchedBack);
      expect(error, isNotNull);
      expect(error, contains('không khớp'));
    });
  });
}
