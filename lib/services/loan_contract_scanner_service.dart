import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/loan_model.dart';

/// Kết quả bóc tách OCR từ ảnh hợp đồng tín dụng / sao kê thẻ tín dụng
class LoanContractScanResult {
  final String rawText;
  final String documentCategory;
  final String? contractNumber;
  final String? loanName;
  final String? lenderName;
  final String loanType;
  final double? principalAmount;
  final double? interestRate;
  final int? tenorMonths;
  final String? startDate; // dd/MM/yyyy
  final String? collateralHint;
  final double confidenceScore;
  final int matchedFieldCount;

  const LoanContractScanResult({
    required this.rawText,
    required this.documentCategory,
    this.contractNumber,
    this.loanName,
    this.lenderName,
    required this.loanType,
    this.principalAmount,
    this.interestRate,
    this.tenorMonths,
    this.startDate,
    this.collateralHint,
    required this.confidenceScore,
    required this.matchedFieldCount,
  });

  bool get isValid => matchedFieldCount >= 2;

  Map<String, dynamic> toPrefilledMap({String? contractFileKey}) => {
    'contract_number': ?contractNumber,
    'loan_name': ?loanName,
    'lender_name': ?lenderName,
    'loan_type': loanType,
    if (principalAmount != null) 'principal_amount': principalAmount!.round(),
    'interest_rate': ?interestRate,
    'tenor_months': ?tenorMonths,
    'start_date': ?startDate,
    'collateral_hint': ?collateralHint,
    'contract_file_key': ?contractFileKey,
    'confidence_score': confidenceScore,
    'document_category': documentCategory,
  };
}

/// Dịch vụ quét OCR hợp đồng tín dụng 100% On-Device bằng Google ML Kit
class LoanContractScannerService {
  static const String categoryLoanContract = 'LOAN_CONTRACT';
  static const String categoryCreditCardStatement = 'CREDIT_CARD_STATEMENT';

  Future<LoanContractScanResult> scanContractImage(
    String imagePath, {
    String documentCategory = categoryLoanContract,
  }) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final recognized = await recognizer.processImage(inputImage);
      return parseRecognizedText(
        recognized.text,
        documentCategory: documentCategory,
      );
    } finally {
      await recognizer.close();
    }
  }

  /// Phân tích và bóc tách các trường tài chính từ văn bản OCR thô
  LoanContractScanResult parseRecognizedText(
    String rawText, {
    String documentCategory = categoryLoanContract,
  }) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return LoanContractScanResult(
        rawText: rawText,
        documentCategory: documentCategory,
        loanType: documentCategory == categoryCreditCardStatement
            ? 'CREDIT_CARD'
            : 'MORTGAGE',
        confidenceScore: 0.0,
        matchedFieldCount: 0,
      );
    }

    final normalized = _stripDiacritics(trimmed).toLowerCase();
    final lenderName = _extractLender(normalized);
    final loanType = _extractLoanType(normalized, documentCategory);
    final contractNumber = _extractContractNumber(trimmed, normalized);
    final principalAmount = _extractPrincipalAmount(trimmed, normalized);
    final interestRate = _extractInterestRate(trimmed, normalized);
    final tenorMonths = _extractTenorMonths(trimmed, normalized);
    final startDate = _extractStartDate(trimmed, normalized);
    final collateralHint = _extractCollateralHint(trimmed, normalized);
    final loanName = _extractLoanName(
      trimmed,
      normalized,
      lenderName: lenderName,
      loanType: loanType,
    );

    int matched = 0;
    if (lenderName != null) matched++;
    if (principalAmount != null) matched++;
    if (interestRate != null) matched++;
    if (tenorMonths != null) matched++;
    if (startDate != null) matched++;
    if (contractNumber != null) matched++;

    final confidence = (0.4 + (matched * 0.1)).clamp(0.0, 0.98);

    return LoanContractScanResult(
      rawText: rawText,
      documentCategory: documentCategory,
      contractNumber: contractNumber,
      loanName: loanName,
      lenderName: lenderName,
      loanType: loanType,
      principalAmount: principalAmount,
      interestRate: interestRate,
      tenorMonths: tenorMonths,
      startDate: startDate,
      collateralHint: collateralHint,
      confidenceScore: matched >= 2 ? confidence : 0.35,
      matchedFieldCount: matched,
    );
  }

  String? _extractLender(String normalized) {
    final bankAliases = <String, List<String>>{
      'Techcombank': ['techcombank', 'ky thuong', 'tcb'],
      'Vietcombank': ['vietcombank', 'ngoai thuong', 'vcb'],
      'BIDV': ['bidv', 'dau tu va phat trien'],
      'VietinBank': ['vietinbank', 'cong thuong'],
      'MBBank': ['mbbank', 'mb bank', 'quan doi'],
      'VPBank': ['vpbank', 'thinh vuong'],
      'TPBank': ['tpbank', 'tien phong'],
      'ACB': ['acb', 'a chau'],
    };

    for (final entry in bankAliases.entries) {
      for (final alias in entry.value) {
        final pattern = RegExp('(^|[^a-z])$alias([^a-z]|\$)');
        if (pattern.hasMatch(normalized)) {
          return entry.key;
        }
      }
    }

    if (normalized.contains('ngan hang') ||
        normalized.contains('to chuc tin dung') ||
        normalized.contains('cong ty tai chinh')) {
      return 'Khác/Tổ chức tín dụng';
    }
    return null;
  }

  String _extractLoanType(String normalized, String documentCategory) {
    if (documentCategory == categoryCreditCardStatement ||
        normalized.contains('the tin dung') ||
        normalized.contains('han muc the') ||
        normalized.contains('sao ke the')) {
      return 'CREDIT_CARD';
    }
    if (normalized.contains('mua xe') ||
        normalized.contains('o to') ||
        normalized.contains('xe hoi') ||
        normalized.contains('phuong tien')) {
      return 'CAR';
    }
    // Kiểm tra các từ khóa bảo đảm/thế chấp/cầm cố TRƯỚC "tiêu dùng" để tránh phân loại nhầm
    // các hợp đồng "vay tiêu dùng có tài sản bảo đảm / cầm cố sổ tiết kiệm" thành vay tín chấp.
    if (normalized.contains('the chap') ||
        normalized.contains('cam co') ||
        normalized.contains('tai san bao dam') ||
        normalized.contains('tai san the chap') ||
        normalized.contains('bat dong san') ||
        normalized.contains('can ho') ||
        normalized.contains('nha o') ||
        normalized.contains('mua nha') ||
        normalized.contains('so do') ||
        normalized.contains('so hong') ||
        normalized.contains('so tiet kiem') ||
        normalized.contains('tien gui')) {
      return 'MORTGAGE';
    }
    if (normalized.contains('tieu dung') || normalized.contains('tin chap')) {
      return 'CONSUMER';
    }
    return 'OTHER';
  }

  String? _extractContractNumber(String raw, String normalized) {
    final lines = raw.split('\n');
    final normLines = normalized.split('\n');
    for (int i = 0; i < lines.length && i < normLines.length; i++) {
      final nl = normLines[i];
      if (nl.contains('so hop dong') ||
          nl.contains('ma hop dong') ||
          nl.contains('hop dong so') ||
          nl.contains('hdtd') ||
          nl.contains('so hd')) {
        final match = RegExp(
          r'[:\s]([A-Z0-9][A-Z0-9\-/]{3,24})',
          caseSensitive: false,
        ).firstMatch(lines[i]);
        if (match != null) {
          final candidate = match.group(1)!.trim();
          if (RegExp(r'\d').hasMatch(candidate)) {
            return candidate;
          }
        }
      }
    }
    return null;
  }

  double? _extractPrincipalAmount(String raw, String normalized) {
    final lines = raw.split('\n');
    final normLines = normalized.split('\n');
    final amountKeywords = [
      'so tien vay',
      'so tien giai ngan',
      'han muc tin dung',
      'han muc the',
      'gia tri khoan vay',
      'du no goc',
      'tong du no',
      'so tien',
    ];

    for (final keyword in amountKeywords) {
      for (int i = 0; i < lines.length && i < normLines.length; i++) {
        if (!normLines[i].contains(keyword)) continue;
        final parsed = _parseCurrencyFromLine(lines[i], normLines[i]);
        if (parsed != null && parsed >= 1000000) {
          return parsed;
        }
      }
    }

    // Fallback: tìm số tiền lớn nhất >= 1 triệu VND có kèm đơn vị tiền tệ rõ ràng
    double? largest;
    for (int i = 0; i < lines.length && i < normLines.length; i++) {
      if (normLines[i].contains('vnd') ||
          normLines[i].contains('dong') ||
          normLines[i].contains('trieu') ||
          normLines[i].contains('ty') ||
          lines[i].contains('đ') ||
          lines[i].contains('₫')) {
        final parsed = _parseCurrencyFromLine(lines[i], normLines[i]);
        if (parsed != null &&
            parsed >= 1000000 &&
            (largest == null || parsed > largest)) {
          largest = parsed;
        }
      }
    }
    return largest;
  }

  double? _parseCurrencyFromLine(String rawLine, String normLine) {
    final tyMatch = RegExp(r'(\d+(?:[.,]\d+)?)\s*ty\b').firstMatch(normLine);
    if (tyMatch != null) {
      final numVal = double.tryParse(tyMatch.group(1)!.replaceAll(',', '.'));
      if (numVal != null) return numVal * 1000000000;
    }

    final trieuMatch = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(?:trieu|tr)\b',
    ).firstMatch(normLine);
    if (trieuMatch != null) {
      final numVal = double.tryParse(trieuMatch.group(1)!.replaceAll(',', '.'));
      if (numVal != null) return numVal * 1000000;
    }

    final digitMatch = RegExp(
      r'(\d{1,3}(?:[.,]\d{3}){2,}|\d{7,12})',
    ).firstMatch(rawLine);
    if (digitMatch != null) {
      final digitsOnly = digitMatch.group(1)!.replaceAll(RegExp(r'[.,]'), '');
      return double.tryParse(digitsOnly);
    }
    return null;
  }

  double? _extractInterestRate(String raw, String normalized) {
    final lines = raw.split('\n');
    final normLines = normalized.split('\n');
    for (int i = 0; i < lines.length && i < normLines.length; i++) {
      if (normLines[i].contains('lai suat') || normLines[i].contains('%/nam')) {
        final match = RegExp(
          r'(\d{1,2}(?:[.,]\d{1,2})?)\s*%',
        ).firstMatch(lines[i]);
        if (match != null) {
          final parsed = double.tryParse(match.group(1)!.replaceAll(',', '.'));
          if (parsed != null && parsed > 0 && parsed <= 100) {
            return parsed;
          }
        }
      }
    }
    return null;
  }

  int? _extractTenorMonths(String raw, String normalized) {
    final lines = raw.split('\n');
    final normLines = normalized.split('\n');
    for (int i = 0; i < lines.length && i < normLines.length; i++) {
      final nl = normLines[i];
      if (nl.contains('ky han') ||
          nl.contains('thoi han') ||
          nl.contains('so ky')) {
        final monthMatch = RegExp(r'(\d{1,3})\s*(?:thang|ky)\b').firstMatch(nl);
        if (monthMatch != null) {
          final m = int.tryParse(monthMatch.group(1)!);
          if (m != null && m >= 1) return m.clamp(6, 240);
        }
        final yearMatch = RegExp(r'(\d{1,2})\s*nam\b').firstMatch(nl);
        if (yearMatch != null) {
          final y = int.tryParse(yearMatch.group(1)!);
          if (y != null && y >= 1) return (y * 12).clamp(6, 240);
        }
      }
    }
    final fallbackMonth = RegExp(r'(\d{1,3})\s*thang\b').firstMatch(normalized);
    if (fallbackMonth != null) {
      final m = int.tryParse(fallbackMonth.group(1)!);
      if (m != null && m >= 6 && m <= 240) return m;
    }
    return null;
  }

  String? _extractStartDate(String raw, String normalized) {
    final lines = raw.split('\n');
    final normLines = normalized.split('\n');
    final dateKeywords = [
      'ngay giai ngan',
      'ngay ky',
      'ngay lap',
      'ngay hieu luc',
      'ngay sao ke',
    ];
    final dateRegex = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](20\d{2}|19\d{2})');

    for (final kw in dateKeywords) {
      for (int i = 0; i < lines.length && i < normLines.length; i++) {
        if (!normLines[i].contains(kw)) continue;
        final m = dateRegex.firstMatch(lines[i]);
        if (m != null) {
          return '${m.group(1)!.padLeft(2, '0')}/${m.group(2)!.padLeft(2, '0')}/${m.group(3)}';
        }
      }
    }

    final anyMatch = dateRegex.firstMatch(raw);
    if (anyMatch != null) {
      return '${anyMatch.group(1)!.padLeft(2, '0')}/${anyMatch.group(2)!.padLeft(2, '0')}/${anyMatch.group(3)}';
    }
    return null;
  }

  String? _extractCollateralHint(String raw, String normalized) {
    final lines = raw.split('\n');
    final normLines = normalized.split('\n');
    for (int i = 0; i < lines.length && i < normLines.length; i++) {
      final nl = normLines[i];
      if (nl.contains('tai san bao dam') ||
          nl.contains('tai san the chap') ||
          nl.contains('tsbd')) {
        final colonIdx = lines[i].indexOf(':');
        if (colonIdx != -1 && colonIdx + 1 < lines[i].length) {
          final hint = lines[i].substring(colonIdx + 1).trim();
          if (hint.length >= 3) return hint;
        } else if (i + 1 < lines.length && lines[i + 1].trim().length >= 3) {
          return lines[i + 1].trim();
        }
      }
    }
    return null;
  }

  String? _extractLoanName(
    String raw,
    String normalized, {
    required String? lenderName,
    required String loanType,
  }) {
    final lines = raw.split('\n');
    final normLines = normalized.split('\n');
    for (int i = 0; i < lines.length && i < normLines.length; i++) {
      final nl = normLines[i];
      if (nl.contains('ten khoan vay') || nl.contains('muc dich vay')) {
        final colonIdx = lines[i].indexOf(':');
        if (colonIdx != -1 && colonIdx + 1 < lines[i].length) {
          final name = lines[i].substring(colonIdx + 1).trim();
          if (name.length >= 3) return name;
        }
      }
    }

    if (lenderName == null) return null;
    final typeLabel = LoanModel.loanTypeLabels[loanType] ?? 'Khoản vay';
    return '$typeLabel - $lenderName';
  }

  String _stripDiacritics(String text) {
    const vietnamese =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const ascii =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      final idx = vietnamese.indexOf(ch);
      buffer.write(idx >= 0 ? ascii[idx] : ch);
    }
    return buffer.toString();
  }
}
