import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/core/utils/app_validators.dart';

void main() {
  group('AppValidators Unit Tests', () {
    test('validateRequired', () {
      expect(AppValidators.validateRequired(null, 'Họ tên'), isNotNull);
      expect(AppValidators.validateRequired('', 'Họ tên'), isNotNull);
      expect(AppValidators.validateRequired('   ', 'Họ tên'), isNotNull);
      expect(AppValidators.validateRequired('Nguyễn Văn A', 'Họ tên'), isNull);
    });

    test('validateFullName', () {
      expect(AppValidators.validateFullName(''), isNotNull);
      expect(AppValidators.validateFullName('A'), isNotNull); // Quá ngắn
      expect(
        AppValidators.validateFullName('Nguyen Van 123'),
        isNotNull,
      ); // Chứa số
      expect(
        AppValidators.validateFullName('Nguyễn Văn @'),
        isNotNull,
      ); // Chứa ký tự đặc biệt
      expect(AppValidators.validateFullName('Nguyễn Văn A'), isNull);
      expect(AppValidators.validateFullName('Trần Thị Thu Thảo'), isNull);
    });

    test('validateEmail', () {
      expect(AppValidators.validateEmail(''), isNotNull);
      expect(AppValidators.validateEmail('invalid-email'), isNotNull);
      expect(AppValidators.validateEmail('test@'), isNotNull);
      expect(AppValidators.validateEmail('test@com'), isNotNull);
      expect(AppValidators.validateEmail('user@fincredit.vn'), isNull);
      expect(AppValidators.validateEmail('dev.test@gmail.com'), isNull);
    });

    test('validatePhone', () {
      expect(AppValidators.validatePhone(''), isNotNull);
      expect(
        AppValidators.validatePhone('123456789'),
        isNotNull,
      ); // Không bắt đầu bằng 0
      expect(
        AppValidators.validatePhone('091234567'),
        isNotNull,
      ); // 9 số -> thiếu
      expect(
        AppValidators.validatePhone('09123456789'),
        isNotNull,
      ); // 11 số -> thừa
      expect(
        AppValidators.validatePhone('0123456789'),
        isNotNull,
      ); // Đầu 01 không hợp lệ ở VN
      expect(AppValidators.validatePhone('0912345678'), isNull);
      expect(AppValidators.validatePhone('0388776655'), isNull);
      expect(
        AppValidators.validatePhone('098 765 4321'),
        isNull,
      ); // Hỗ trợ khoảng trắng
    });

    test('validateIdentifier', () {
      expect(AppValidators.validateIdentifier(''), isNotNull);
      expect(AppValidators.validateIdentifier('ab'), isNotNull);
      expect(AppValidators.validateIdentifier('bad-email@'), isNotNull);
      expect(AppValidators.validateIdentifier('user@fincredit.vn'), isNull);
      expect(AppValidators.validateIdentifier('0912345678'), isNull);
      expect(AppValidators.validateIdentifier('CIC12345678'), isNull);
    });

    test('validatePassword', () {
      expect(AppValidators.validatePassword(''), isNotNull);
      expect(AppValidators.validatePassword('1234567'), isNotNull); // < 8 ký tự
      expect(
        AppValidators.validatePassword('abcdefgh'),
        isNotNull,
      ); // Không có số
      expect(
        AppValidators.validatePassword('12345678'),
        isNotNull,
      ); // Không có chữ
      expect(AppValidators.validatePassword('Password123'), isNull);
      expect(AppValidators.validatePassword('Secret89!'), isNull);
    });

    test('validateConfirmPassword', () {
      expect(AppValidators.validateConfirmPassword('', 'Pass123!'), isNotNull);
      expect(
        AppValidators.validateConfirmPassword('Pass456!', 'Pass123!'),
        isNotNull,
      );
      expect(
        AppValidators.validateConfirmPassword('Pass123!', 'Pass123!'),
        isNull,
      );
    });

    test('validateIdCard', () {
      expect(AppValidators.validateIdCard('', required: false), isNull);
      expect(AppValidators.validateIdCard('', required: true), isNotNull);
      expect(AppValidators.validateIdCard('12345'), isNotNull); // Quá ngắn
      expect(AppValidators.validateIdCard('1234567890123'), isNotNull); // 13 số
      expect(
        AppValidators.validateIdCard('001200123456'),
        isNull,
      ); // 12 số CCCD gắn chip
      expect(AppValidators.validateIdCard('012345678'), isNull); // 9 số CMND cũ
    });

    test('validateMonthlyIncome', () {
      expect(AppValidators.validateMonthlyIncome('', required: false), isNull);
      expect(
        AppValidators.validateMonthlyIncome('', required: true),
        isNotNull,
      );
      expect(AppValidators.validateMonthlyIncome('abc'), isNotNull);
      expect(AppValidators.validateMonthlyIncome('500000'), isNotNull); // < 1M
      expect(AppValidators.validateMonthlyIncome('25000000'), isNull);
      expect(AppValidators.validateMonthlyIncome('25.000.000'), isNull);
    });

    test('validateBankAccountNumber', () {
      expect(AppValidators.validateBankAccountNumber(''), isNotNull);
      expect(
        AppValidators.validateBankAccountNumber('123'),
        isNotNull,
      ); // Quá ngắn
      expect(AppValidators.validateBankAccountNumber('19030012345678'), isNull);
    });

    test('validateAccountHolderName', () {
      expect(AppValidators.validateAccountHolderName(''), isNotNull);
      expect(AppValidators.validateAccountHolderName('A'), isNotNull);
      expect(
        AppValidators.validateAccountHolderName('NGUYEN VAN A 123'),
        isNotNull,
      );
      expect(AppValidators.validateAccountHolderName('NGUYEN VAN A'), isNull);
    });

    test('validateLoanName', () {
      expect(AppValidators.validateLoanName(''), isNotNull);
      expect(AppValidators.validateLoanName('V'), isNotNull);
      expect(AppValidators.validateLoanName('Vay mua nhà Times City'), isNull);
    });

    test('validateLoanAmount', () {
      expect(AppValidators.validateLoanAmount(''), isNotNull);
      expect(AppValidators.validateLoanAmount('1000000'), isNotNull); // < 5M
      expect(
        AppValidators.validateLoanAmount('60000000000'),
        isNotNull,
      ); // > 50B
      expect(AppValidators.validateLoanAmount('300000000'), isNull);
      expect(AppValidators.validateLoanAmount('300.000.000'), isNull);
    });

    test('validateCollateralName', () {
      expect(
        AppValidators.validateCollateralName('', required: true),
        isNotNull,
      );
      expect(AppValidators.validateCollateralName('', required: false), isNull);
      expect(AppValidators.validateCollateralName('Sổ hồng'), isNull);
    });

    test('validateCollateralValue', () {
      expect(
        AppValidators.validateCollateralValue(
          '',
          min: 100000000,
          max: 50000000000,
          displayName: 'Bất động sản',
          minFormatted: '100 triệu',
          maxFormatted: '50 tỷ',
          required: true,
        ),
        isNotNull,
      );
      expect(
        AppValidators.validateCollateralValue(
          '50000000',
          min: 100000000,
          max: 50000000000,
          displayName: 'Bất động sản',
          minFormatted: '100 triệu',
          maxFormatted: '50 tỷ',
        ),
        isNotNull, // < 100M
      );
      expect(
        AppValidators.validateCollateralValue(
          '1500000000',
          min: 100000000,
          max: 50000000000,
          displayName: 'Bất động sản',
          minFormatted: '100 triệu',
          maxFormatted: '50 tỷ',
        ),
        isNull,
      );
    });
  });
}
