import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/services/collateral_scanner_service.dart';

void main() {
  const ownerId = '034205014023';
  const ownerName = 'Nguyễn Văn Bình';
  final refNow = DateTime(2026, 11, 20);

  group('CollateralScannerService - Kiểm định giấy tờ tài sản bảo đảm', () {
    test(
      '1. Chấp nhận Sổ tiết kiệm hợp lệ khớp chính chủ & trích xuất đúng mệnh giá',
      () {
        const text = '''
        FINBANK VIETNAM
        SỔ TIẾT KIỆM CÓ KỲ HẠN
        Chủ sở hữu: NGUYỄN VĂN BÌNH
        Số CCCD: 034205014023
        Số tài khoản tiết kiệm: TK-8899001122
        Số tiền gửi gốc: 250.000.000 VNĐ
        Kỳ hạn: 12 tháng | Lãi suất: 5.8%/năm
        Ngày gửi: 15/06/2026 | Ngày đến hạn: 15/06/2027
        Trạng thái: Đang gửi (Hiệu lực)
      ''';

        final result = CollateralScannerService.analyzeOcrText(
          text,
          assetType: 'SAVINGS',
          expectedIdCardNumber: ownerId,
          expectedOwnerName: ownerName,
          now: refNow,
        );

        expect(result.ownerIdCard, ownerId);
        expect(result.extractedName, 'Sổ tiết kiệm TK-8899001122');
        expect(result.extractedValue, 250000000);
        expect(result.certificateNumber, 'TK-8899001122');
        expect(result.expiryDate, '2027-06-15');
      },
    );

    test(
      '2. Chấp nhận Cavet ô tô hợp lệ & trích xuất đúng biển số, giá trị',
      () {
        const text = '''
        CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM
        CHỨNG NHẬN ĐĂNG KÝ XE Ô TÔ
        Tên chủ xe: NGUYỄN VĂN BÌNH
        Số CCCD: 034205014023
        Nhãn hiệu: VINFAST | Số loại: VF8 PLUS
        Biển số đăng ký: 17A-388.99
        Giá trị tham khảo: 750.000.000 VNĐ
      ''';

        final result = CollateralScannerService.analyzeOcrText(
          text,
          assetType: 'VEHICLE',
          expectedIdCardNumber: ownerId,
          expectedOwnerName: ownerName,
          now: refNow,
        );

        expect(result.ownerIdCard, ownerId);
        expect(result.extractedName, contains('17A-388.99'));
        expect(result.extractedValue, 750000000);
        expect(result.certificateNumber, '17A-388.99');
      },
    );

    test(
      '2b. Từ chối nếu chọn sai loại tài sản hoặc thiếu giá trị định giá VNĐ',
      () {
        const cavetText = '''
        CHỨNG NHẬN ĐĂNG KÝ XE Ô TÔ
        Tên chủ xe: NGUYỄN VĂN BÌNH
        Số CCCD: 034205014023
        Biển số đăng ký: 17A-388.99
        Giá trị tham khảo: 750.000.000 VNĐ
      ''';
        expect(
          () => CollateralScannerService.analyzeOcrText(
            cavetText,
            assetType: 'SAVINGS',
            expectedIdCardNumber: ownerId,
            expectedOwnerName: ownerName,
            now: refNow,
          ),
          throwsA(
            predicate((e) => e.toString().contains('không khớp với loại')),
          ),
        );

        const noValueSoHong = '''
        GIẤY CHỨNG NHẬN QUYỀN SỬ DỤNG ĐẤT
        Người sử dụng đất: Ông NGUYỄN VĂN BÌNH
        Số CCCD: 034205014023
        Thửa đất số: 142, Tờ bản đồ số: 18
        Diện tích: 85.0 m2
      ''';
        expect(
          () => CollateralScannerService.analyzeOcrText(
            noValueSoHong,
            assetType: 'REAL_ESTATE',
            expectedIdCardNumber: ownerId,
            expectedOwnerName: ownerName,
            now: refNow,
          ),
          throwsA(predicate((e) => e.toString().contains('giá trị định giá'))),
        );
      },
    );

    test('3. Từ chối ngay khi giấy tờ đứng tên người khác (sai chính chủ)', () {
      const text = '''
        SỔ TIẾT KIỆM CÓ KỲ HẠN
        Chủ sở hữu: TRẦN VĂN NAM
        Số CCCD: 079095001234
        Số tiền gửi gốc: 250.000.000 VNĐ
        Ngày đến hạn: 15/06/2027
      ''';

      expect(
        () => CollateralScannerService.analyzeOcrText(
          text,
          assetType: 'SAVINGS',
          expectedIdCardNumber: ownerId,
          expectedOwnerName: ownerName,
          now: refNow,
        ),
        throwsA(
          predicate((e) => e.toString().contains('không thuộc chính chủ')),
        ),
      );
    });

    test('4. Từ chối ngay khi sổ đã tất toán hoặc quá hạn hiệu lực', () {
      const settledText = '''
        SỔ TIẾT KIỆM CÓ KỲ HẠN
        Chủ sở hữu: NGUYỄN VĂN BÌNH
        Số CCCD: 034205014023
        Số tiền gửi gốc: 250.000.000 VNĐ
        Ngày đến hạn: 15/06/2024
        ĐÃ TẤT TOÁN / HẾT HIỆU LỰC
      ''';

      expect(
        () => CollateralScannerService.analyzeOcrText(
          settledText,
          assetType: 'SAVINGS',
          expectedIdCardNumber: ownerId,
          expectedOwnerName: ownerName,
          now: refNow,
        ),
        throwsA(predicate((e) => e.toString().contains('hết hiệu lực'))),
      );

      const expiredDateOnly = '''
        CHỨNG NHẬN ĐĂNG KIỂM Ô TÔ
        Tên chủ xe: NGUYỄN VĂN BÌNH
        Số CCCD: 034205014023
        Có giá trị đến hết ngày: 01/05/2025
      ''';

      expect(
        () => CollateralScannerService.analyzeOcrText(
          expiredDateOnly,
          assetType: 'VEHICLE',
          expectedIdCardNumber: ownerId,
          expectedOwnerName: ownerName,
          now: refNow,
        ),
        throwsA(predicate((e) => e.toString().contains('hết hạn sử dụng'))),
      );
    });

    test(
      '5. Từ chối giấy viết tay giả mạo hoặc ảnh bị lóa mất thông tin CCCD',
      () {
        const fakeHandwritten = 'Tôi có chiếc xe trị giá 5 tỷ đồng';
        expect(
          () => CollateralScannerService.analyzeOcrText(
            fakeHandwritten,
            assetType: 'VEHICLE',
            expectedIdCardNumber: ownerId,
            expectedOwnerName: ownerName,
            now: refNow,
          ),
          throwsA(
            predicate(
              (e) => e.toString().contains('không phải giấy tờ pháp lý'),
            ),
          ),
        );

        const glareMissingCccd = '''
        CHỨNG NHẬN ĐĂNG KÝ XE Ô TÔ
        Tên chủ xe: NGUYỄN VĂN BÌNH
        Biển số đăng ký: 17A-388.99
      ''';
        expect(
          () => CollateralScannerService.analyzeOcrText(
            glareMissingCccd,
            assetType: 'VEHICLE',
            expectedIdCardNumber: ownerId,
            expectedOwnerName: ownerName,
            now: refNow,
          ),
          throwsA(
            predicate((e) => e.toString().contains('Không tìm thấy số CCCD')),
          ),
        );
      },
    );
  });
}
