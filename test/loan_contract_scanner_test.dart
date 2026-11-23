import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/screens/loans/loan_collateral_ocr_screen.dart';
import 'package:my_first_app/screens/loans/loan_form_screen.dart';
import 'package:my_first_app/service_locator.dart';
import 'package:my_first_app/services/loan_contract_scanner_service.dart';

void main() {
  setUpAll(() {
    setupServiceLocator();
  });

  group('LoanContractScannerService Unit Tests', () {
    final scanner = LoanContractScannerService();

    test(
      '1. Bóc tách chính xác hợp đồng vay mua nhà Techcombank đầy đủ trường và tài sản bảo đảm',
      () {
        const sampleContract = '''
CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM
HỢP ĐỒNG TÍN DỤNG
Số hợp đồng: HD-2026/089
Bên cho vay: Ngân hàng TMCP Kỹ Thương Việt Nam (Techcombank)
Mục đích vay: Vay mua căn hộ Masteri Thảo Điền
Số tiền giải ngân: 1.500.000.000 VND
Lãi suất áp dụng: 9.2%/năm
Kỳ hạn vay: 120 tháng
Ngày giải ngân: 15/09/2026
Tài sản bảo đảm: Căn hộ chung cư Masteri B12-05
''';

        final res = scanner.parseRecognizedText(sampleContract);
        expect(res.isValid, isTrue);
        expect(res.lenderName, equals('Techcombank'));
        expect(res.loanType, equals('MORTGAGE'));
        expect(res.contractNumber, equals('HD-2026/089'));
        expect(res.loanName, equals('Vay mua căn hộ Masteri Thảo Điền'));
        expect(res.principalAmount, equals(1500000000));
        expect(res.interestRate, equals(9.2));
        expect(res.tenorMonths, equals(120));
        expect(res.startDate, equals('15/09/2026'));
        expect(res.collateralHint, equals('Căn hộ chung cư Masteri B12-05'));

        final prefilled = res.toPrefilledMap(
          contractFileKey: 'contracts/1/contract_scan_1.jpg',
        );
        expect(prefilled['lender_name'], equals('Techcombank'));
        expect(prefilled['tenor_months'], equals(120));
        expect(
          prefilled['contract_file_key'],
          equals('contracts/1/contract_scan_1.jpg'),
        );
      },
    );

    test(
      '2. Bóc tách hợp đồng vay mua ô tô MBBank (quy đổi năm -> tháng & triệu -> VNĐ)',
      () {
        const carContract = '''
NGÂN HÀNG TMCP QUÂN ĐỘI (MBBANK)
HỢP ĐỒNG VAY MUA Ô TÔ
Số tiền vay: 500 triệu
Lãi suất: 8,5%/năm
Thời hạn vay: 5 năm
Ngày ký: 20-10-2026
Tài sản thế chấp: Xe ô tô VinFast VF8 30K-123.45
''';

        final res = scanner.parseRecognizedText(carContract);
        expect(res.isValid, isTrue);
        expect(res.lenderName, equals('MBBank'));
        expect(res.loanType, equals('CAR'));
        expect(res.principalAmount, equals(500000000));
        expect(res.interestRate, equals(8.5));
        expect(res.tenorMonths, equals(60));
        expect(res.startDate, equals('20/10/2026'));
        expect(res.collateralHint, equals('Xe ô tô VinFast VF8 30K-123.45'));
      },
    );

    test('3. Bóc tách sao kê thẻ tín dụng VPBank', () {
      const cardStatement = '''
VPBank - SAO KÊ THẺ TÍN DỤNG
Hạn mức tín dụng: 100.000.000 đ
Ngày sao kê: 05/11/2026
Lãi suất: 24.0%/năm
''';

      final res = scanner.parseRecognizedText(
        cardStatement,
        documentCategory:
            LoanContractScannerService.categoryCreditCardStatement,
      );
      expect(res.isValid, isTrue);
      expect(res.lenderName, equals('VPBank'));
      expect(res.loanType, equals('CREDIT_CARD'));
      expect(res.principalAmount, equals(100000000));
      expect(res.interestRate, equals(24.0));
      expect(res.startDate, equals('05/11/2026'));
    });

    test(
      '4. Từ chối văn bản rác / không phải hợp đồng (không tự điền giá trị giả)',
      () {
        const garbage = 'Hóa đơn siêu thị: 2 chai nước suối 20.000đ';
        final res = scanner.parseRecognizedText(garbage);
        expect(res.isValid, isFalse);
        expect(res.lenderName, isNull);
        expect(res.principalAmount, isNull);
        expect(res.tenorMonths, isNull);
      },
    );
  });

  group('LoanFormScreen & OCR Integration Widget Tests', () {
    testWidgets(
      'LoanFormScreen nhận dữ liệu prefilled từ OCR (kể cả lender/term_months & collateral_hint)',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: LoanFormScreen(
              prefilledData: {
                'loan_name': 'Vay mua căn hộ Masteri',
                'lender': 'Techcombank',
                'loan_type': 'MORTGAGE',
                'principal_amount': 1500000000,
                'interest_rate': 9.2,
                'term_months': 120,
                'start_date': '2026-09-15',
                'collateral_hint': 'Căn hộ Masteri chưa đăng ký',
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Vay mua căn hộ Masteri'), findsOneWidget);
        expect(find.text('15/09/2026'), findsOneWidget);
        expect(
          find.textContaining('Căn hộ Masteri chưa đăng ký'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'LoanCollateralOcrScreen tab Bóc tách OCR hiển thị dropdown loại chứng từ chuẩn',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: LoanCollateralOcrScreen()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Bóc tách OCR'));
        await tester.pumpAndSettle();

        expect(find.text('Chọn loại chứng từ cần bóc tách:'), findsOneWidget);
        expect(
          find.text('Hợp đồng tín dụng / Vay vốn ngân hàng'),
          findsOneWidget,
        );
        expect(find.text('Bắt đầu quét & bóc tách AI'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    test(
      'LoanContractScannerService phân loại hợp đồng vay tiêu dùng cầm cố sổ tiết kiệm là MORTGAGE',
      () {
        final scanner = LoanContractScannerService();
        const sampleVcbContract = '''
NGÂN HÀNG TMCP NGOẠI THƯƠNG VIỆT NAM (VIETCOMBANK)
HỢP ĐỒNG VAY CẦM CỐ SỔ TIẾT KIỆM
Số hợp đồng: HD-VCB/2026-1122
Mục đích vay: Vay tiêu dùng cầm cố sổ tiết kiệm
Số tiền giải ngân: 200.000.000 VND
Lãi suất áp dụng: 7.5%/năm
Kỳ hạn vay: 12 tháng
Ngày giải ngân: 01/11/2026
Tài sản bảo đảm: Sổ tiết kiệm FinBank TK-8899001122
''';
        final result = scanner.parseRecognizedText(sampleVcbContract);
        expect(result.isValid, isTrue);
        expect(result.lenderName, 'Vietcombank');
        expect(result.loanType, 'MORTGAGE');
        expect(result.principalAmount, 200000000);
        expect(result.interestRate, 7.5);
        expect(result.tenorMonths, 12);
        expect(result.collateralHint, contains('TK-8899001122'));
      },
    );

    testWidgets(
      'LoanFormScreen bắt buộc chọn tài sản thế chấp khi có collateral_hint dù loan_type là CAR/CONSUMER',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: LoanFormScreen(
              prefilledData: {
                'loan_name': 'Vay tiêu dùng cầm cố sổ tiết kiệm',
                'lender_name': 'Vietcombank',
                'loan_type': 'CAR',
                'principal_amount': 200000000,
                'interest_rate': 7.5,
                'tenor_months': 12,
                'start_date': '2026-11-01',
                'collateral_hint': 'Sổ tiết kiệm FinBank TK-8899001122',
                'contract_file_key': 'ocr-scans/1/hd-vcb.jpg',
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Sổ tiết kiệm FinBank TK-8899001122'),
          findsOneWidget,
        );

        final submitBtn = find.text('Tạo khoản vay mới');
        await tester.ensureVisible(submitBtn);
        await tester.pumpAndSettle();
        await tester.tap(submitBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Không được tạo khoản vay mà phải hiển thị thông báo bắt buộc chọn tài sản bảo đảm
        expect(find.text('Tạo khoản vay mới'), findsOneWidget);
        expect(
          find.text('Vui lòng chọn một tài sản từ danh mục hiện có'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  });
}
