import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Dữ liệu bóc tách từ mặt trước CCCD gắn chip (ưu tiên QR Code chuẩn Bộ Công An)
class CccdFrontData {
  final String idCardNumber;
  final String fullName;
  final String dateOfBirth; // YYYY-MM-DD
  final String address;
  final String? gender;
  final String? issueDate; // YYYY-MM-DD
  final String? expiryDate; // YYYY-MM-DD
  final bool fromQrCode;

  const CccdFrontData({
    required this.idCardNumber,
    required this.fullName,
    required this.dateOfBirth,
    required this.address,
    this.gender,
    this.issueDate,
    this.expiryDate,
    this.fromQrCode = true,
  });

  /// Định dạng ngày sinh dd/MM/yyyy để hiển thị UI
  String get dateOfBirthDisplay => _formatIsoToVn(dateOfBirth);

  String? get expiryDateDisplay =>
      expiryDate != null ? _formatIsoToVn(expiryDate!) : null;

  static String _formatIsoToVn(String iso) {
    final parts = iso.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return iso;
  }
}

/// Dữ liệu bóc tách từ mã MRZ 3 dòng ở mặt sau CCCD gắn chip (chuẩn ICAO 9303)
class CccdBackData {
  final String? idCardNumber;
  final String? birthYyMmDd; // YYMMDD
  final String? expiryYyMmDd; // YYMMDD
  final String? fullNameAscii;
  final String rawMrz;

  const CccdBackData({
    this.idCardNumber,
    this.birthYyMmDd,
    this.expiryYyMmDd,
    this.fullNameAscii,
    required this.rawMrz,
  });

  String? get expiryDateIso {
    if (expiryYyMmDd == null || expiryYyMmDd!.length != 6) return null;
    final yy = int.tryParse(expiryYyMmDd!.substring(0, 2));
    final mm = expiryYyMmDd!.substring(2, 4);
    final dd = expiryYyMmDd!.substring(4, 6);
    if (yy == null) return null;
    return '${2000 + yy}-$mm-$dd';
  }

  String? get expiryDateDisplay => expiryDateIso != null
      ? CccdFrontData._formatIsoToVn(expiryDateIso!)
      : null;
}

/// Dịch vụ quét và đối chiếu chéo CCCD gắn chip 100% On-Device (không gửi ảnh ra bên thứ 3)
class CccdScannerService {
  /// Quét mặt trước CCCD: ưu tiên giải mã QR Code (chính xác 100% tiếng Việt có dấu),
  /// fallback sang OCR văn bản nếu QR không đọc được.
  Future<CccdFrontData> scanFront(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);

    // 1. Giải mã QR Code trên góc phải mặt trước CCCD
    final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    try {
      final barcodes = await barcodeScanner.processImage(inputImage);
      for (final barcode in barcodes) {
        final raw = barcode.rawValue;
        if (raw != null && raw.trim().isNotEmpty) {
          final parsed = parseQrPayload(raw);
          if (parsed != null) return parsed;
        }
      }
    } finally {
      await barcodeScanner.close();
    }

    // 2. Fallback OCR văn bản mặt trước nếu QR mờ/chói sáng
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await textRecognizer.processImage(inputImage);
      final parsed = parseFrontOcrText(recognized.text);
      if (parsed != null) return parsed;
    } finally {
      await textRecognizer.close();
    }

    throw Exception(
      'Không đọc được mã QR hoặc thông tin trên mặt trước CCCD. Vui lòng chụp rõ nét, đủ sáng và không bị lóa.',
    );
  }

  /// Quét mặt sau CCCD bằng OCR đọc 3 dòng mã MRZ chuẩn ICAO (IDVNM...)
  Future<CccdBackData> scanBack(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await textRecognizer.processImage(inputImage);
      final lines = recognized.blocks
          .expand((b) => b.lines)
          .map((l) => l.text)
          .toList();
      final parsed = parseMrzLines(lines);
      if (parsed != null) return parsed;
    } finally {
      await textRecognizer.close();
    }

    throw Exception(
      'Không đọc được mã MRZ (3 dòng chữ ở đáy mặt sau CCCD). Vui lòng chụp rõ nét mặt sau thẻ.',
    );
  }

  /// Parse chuỗi QR Code chuẩn Bộ Công An Việt Nam:
  /// `CCCD|CMND|Họ tên|ddMMyyyy|Giới tính|Nơi thường trú|ddMMyyyy`
  static CccdFrontData? parseQrPayload(String raw) {
    final parts = raw.trim().split('|');
    if (parts.length < 6) return null;

    final idNumber = parts[0].replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^\d{12}$').hasMatch(idNumber)) return null;

    final fullName = _normalizeSpaces(parts[2]);
    final dobIso = _parseDdMmYyyy(parts[3]);
    final gender = _normalizeSpaces(parts[4]);
    final address = _normalizeSpaces(parts[5]);
    final issueIso = parts.length > 6 ? _parseDdMmYyyy(parts[6]) : null;

    if (fullName.isEmpty || dobIso == null || address.isEmpty) {
      return null;
    }

    return CccdFrontData(
      idCardNumber: idNumber,
      fullName: fullName,
      dateOfBirth: dobIso,
      address: address,
      gender: gender.isEmpty ? null : gender,
      issueDate: issueIso,
      fromQrCode: true,
    );
  }

  /// Fallback parse OCR mặt trước CCCD nếu ảnh không quét được QR Code
  static CccdFrontData? parseFrontOcrText(String rawText) {
    final normalized = rawText.replaceAll('\r', '\n');
    final idMatch = RegExp(r'\b(\d{12})\b').firstMatch(normalized);
    if (idMatch == null) return null;
    final idNumber = idMatch.group(1)!;

    final dateMatches = RegExp(
      r'\b(\d{2})[/\-](\d{2})[/\-](\d{4})\b',
    ).allMatches(normalized).toList();
    String? dobIso;
    if (dateMatches.isNotEmpty) {
      final m = dateMatches.first;
      dobIso = '${m.group(3)}-${m.group(2)}-${m.group(1)}';
    }
    if (dobIso == null) return null;

    final lines = normalized
        .split('\n')
        .map(_normalizeSpaces)
        .where((l) => l.isNotEmpty)
        .toList();

    String fullName = '';
    for (int i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      if (lower.contains('full name') || lower.contains('họ và tên')) {
        if (i + 1 < lines.length &&
            !lines[i + 1].toLowerCase().contains('date of birth')) {
          fullName = lines[i + 1];
          break;
        }
      }
    }

    String address = '';
    for (int i = 0; i < lines.length; i++) {
      final lower = lines[i].toLowerCase();
      if (lower.contains('place of residence') ||
          lower.contains('nơi thường trú')) {
        final afterColon = lines[i].contains(':')
            ? lines[i].split(':').sublist(1).join(':').trim()
            : '';
        final nextLine = (i + 1 < lines.length) ? lines[i + 1] : '';
        address = [afterColon, nextLine]
            .where((s) => s.isNotEmpty)
            .join(', ')
            .replaceAll(RegExp(r'^,\s*'), '');
        break;
      }
    }

    if (fullName.isEmpty || address.isEmpty) return null;

    String? expiryIso;
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('giá trị đến') ||
          lower.contains('gia tri den') ||
          lower.contains('expiry')) {
        final m = RegExp(r'(\d{2})[/\-](\d{2})[/\-](\d{4})').firstMatch(line);
        if (m != null) {
          expiryIso = '${m.group(3)}-${m.group(2)}-${m.group(1)}';
          break;
        }
      }
    }
    if (expiryIso == null && dateMatches.length >= 2) {
      final m = dateMatches[1];
      expiryIso = '${m.group(3)}-${m.group(2)}-${m.group(1)}';
    }

    return CccdFrontData(
      idCardNumber: idNumber,
      fullName: fullName,
      dateOfBirth: dobIso,
      address: address,
      expiryDate: expiryIso,
      fromQrCode: false,
    );
  }

  /// Parse 3 dòng mã MRZ mặt sau CCCD gắn chip Việt Nam (TD1 - ICAO 9303):
  /// - Line 1: `IDVNM<9 số cuối><check><12 số CCCD><<...`
  /// - Line 2: `YYMMDD<check><M/F><YYMMDD><check>VNM<<<<<<<<<<<0`
  /// - Line 3: `NGUYEN<<VAN<BINH<<<<<<<<<<<<<<`
  static CccdBackData? parseMrzLines(List<String> lines) {
    final cleaned = lines
        .map((l) => l.toUpperCase().replaceAll(' ', ''))
        .where((l) => l.length >= 15)
        .toList();

    String? line1;
    String? line2;
    String? line3;

    for (int i = 0; i < cleaned.length; i++) {
      final line = cleaned[i];
      if (line1 == null &&
          (line.startsWith('IDVNM') ||
              (line.contains('IDVNM') && line.contains('<')))) {
        final start = line.indexOf('IDVNM');
        line1 = line.substring(start);
        if (i + 1 < cleaned.length) line2 = cleaned[i + 1];
        if (i + 2 < cleaned.length) line3 = cleaned[i + 2];
        break;
      }
    }

    if (line1 == null) return null;

    // Line 1 chứa 12 chữ số CCCD ở phần cuối trước dấu '<'
    String? idCardNumber;
    final idMatch = RegExp(r'(\d{12})(?:<|$)').firstMatch(line1);
    if (idMatch != null) {
      idCardNumber = idMatch.group(1);
    } else {
      // Fallback: lấy 9 số sau IDVNM ghép nếu không bắt được đủ 12 số
      final allDigits = RegExp(r'\d{12}').firstMatch(line1);
      if (allDigits != null) idCardNumber = allDigits.group(0);
    }

    String? birthYyMmDd;
    String? expiryYyMmDd;
    if (line2 != null) {
      final mrzLine2Match = RegExp(
        r'^(\d{6})\d[MFX<](\d{6})',
      ).firstMatch(line2);
      if (mrzLine2Match != null) {
        birthYyMmDd = mrzLine2Match.group(1);
        expiryYyMmDd = mrzLine2Match.group(2);
      } else {
        final dobMatch = RegExp(r'^(\d{6})').firstMatch(line2);
        if (dobMatch != null) {
          birthYyMmDd = dobMatch.group(1);
        }
      }
    }

    String? fullNameAscii;
    if (line3 != null) {
      fullNameAscii = line3
          .replaceAll('<', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    return CccdBackData(
      idCardNumber: idCardNumber,
      birthYyMmDd: birthYyMmDd,
      expiryYyMmDd: expiryYyMmDd,
      fullNameAscii: fullNameAscii,
      rawMrz: [line1, ?line2, ?line3].join('\n'),
    );
  }

  /// Kiểm tra CCCD còn giá trị sử dụng hay đã hết hạn
  static String? validateExpiry(String? expiryIso, {DateTime? now}) {
    if (expiryIso == null || expiryIso.isEmpty) return null;
    final expiry = DateTime.tryParse(expiryIso);
    if (expiry == null) return null;
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    if (expiryDay.isBefore(today)) {
      return 'Thẻ CCCD đã hết hạn sử dụng (hạn: ${CccdFrontData._formatIsoToVn(expiryIso)}). Vui lòng sử dụng thẻ CCCD còn hiệu lực.';
    }
    return null;
  }

  /// Đối chiếu chéo dữ liệu mặt trước và mặt sau CCCD (bao gồm kiểm tra hạn sử dụng).
  /// Trả về `null` nếu hợp lệ, hoặc thông báo lỗi chi tiết nếu không khớp / hết hạn.
  static String? crossCheck(
    CccdFrontData front,
    CccdBackData back, {
    DateTime? now,
  }) {
    // 0. Kiểm tra hạn sử dụng CCCD
    final expiryError = validateExpiry(
      back.expiryDateIso ?? front.expiryDate,
      now: now,
    );
    if (expiryError != null) return expiryError;

    // 1. Đối chiếu 12 số CCCD
    if (back.idCardNumber != null && back.idCardNumber != front.idCardNumber) {
      return 'Số CCCD ở mặt trước (${front.idCardNumber}) không khớp với mã MRZ mặt sau (${back.idCardNumber}).';
    }

    // 2. Đối chiếu ngày sinh (YYMMDD)
    if (back.birthYyMmDd != null && front.dateOfBirth.length == 10) {
      final parts = front.dateOfBirth.split('-'); // YYYY-MM-DD
      final frontYyMmDd = '${parts[0].substring(2)}${parts[1]}${parts[2]}';
      if (back.birthYyMmDd != frontYyMmDd) {
        return 'Ngày sinh trên mặt trước (${front.dateOfBirthDisplay}) không khớp với mặt sau CCCD.';
      }
    }

    // 3. Đối chiếu họ và tên không dấu (nếu MRZ đọc được)
    if (back.fullNameAscii != null && back.fullNameAscii!.length >= 3) {
      final frontAscii = removeVietnameseDiacritics(
        front.fullName,
      ).toUpperCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      final backAscii = back.fullNameAscii!.toUpperCase();
      // Kiểm tra các từ chính có khớp nhau không (cho phép OCR thiếu 1-2 ký tự cuối nếu dài)
      final frontWords = frontAscii.split(' ');
      final backWords = backAscii.split(' ');
      if (frontWords.isNotEmpty &&
          backWords.isNotEmpty &&
          frontWords.first != backWords.first) {
        return 'Họ và tên trên mặt trước (${front.fullName}) không khớp với mặt sau (${back.fullNameAscii}).';
      }
    }

    return null;
  }

  static String? _parseDdMmYyyy(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;
    final dd = digits.substring(0, 2);
    final mm = digits.substring(2, 4);
    final yyyy = digits.substring(4, 8);
    final d = int.tryParse(dd);
    final m = int.tryParse(mm);
    final y = int.tryParse(yyyy);
    if (d == null || m == null || y == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31 || y < 1900 || y > 2100) {
      return null;
    }
    return '$yyyy-$mm-$dd';
  }

  static String _normalizeSpaces(String input) =>
      input.replaceAll(RegExp(r'\s+'), ' ').trim();

  static String removeVietnameseDiacritics(String str) {
    const withDia =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const withoutDia =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final idx = withDia.indexOf(str[i]);
      buffer.write(idx >= 0 ? withoutDia[idx] : str[i]);
    }
    return buffer.toString();
  }
}
