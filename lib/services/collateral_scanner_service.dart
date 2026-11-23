import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'cccd_scanner_service.dart';

/// Kết quả kiểm định & bóc tách thông tin từ giấy tờ pháp lý tài sản bảo đảm
class CollateralScanResult {
  final String assetType;
  final String rawText;
  final String ownerIdCard;
  final String extractedName;
  final double extractedValue;
  final String? certificateNumber;
  final String? expiryDate; // YYYY-MM-DD
  final String? valuationDate; // YYYY-MM-DD

  const CollateralScanResult({
    required this.assetType,
    required this.rawText,
    required this.ownerIdCard,
    required this.extractedName,
    required this.extractedValue,
    this.certificateNumber,
    this.expiryDate,
    this.valuationDate,
  });
}

/// Dịch vụ quét OCR & kiểm định giấy tờ tài sản bảo đảm 100% On-Device
class CollateralScannerService {
  /// Quét ảnh giấy tờ tài sản và đối chiếu chính chủ với hồ sơ eKYC
  Future<CollateralScanResult> scanAndVerify(
    String imagePath, {
    required String assetType,
    required String expectedIdCardNumber,
    String? expectedOwnerName,
    DateTime? now,
  }) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    String rawText;
    try {
      final recognized = await recognizer.processImage(inputImage);
      rawText = recognized.text;
    } finally {
      await recognizer.close();
    }

    return analyzeOcrText(
      rawText,
      assetType: assetType,
      expectedIdCardNumber: expectedIdCardNumber,
      expectedOwnerName: expectedOwnerName,
      now: now,
    );
  }

  /// Phân tích và kiểm định nội dung OCR (pure static để unit test dễ dàng)
  static CollateralScanResult analyzeOcrText(
    String rawText, {
    required String assetType,
    required String expectedIdCardNumber,
    String? expectedOwnerName,
    DateTime? now,
  }) {
    final trimmed = rawText.trim();
    if (trimmed.length < 25) {
      throw Exception(
        'Ảnh quá mờ, lóa sáng hoặc không đọc được chữ. Vui lòng chụp lại giấy tờ rõ nét hơn.',
      );
    }

    final asciiLower = CccdScannerService.removeVietnameseDiacritics(
      trimmed,
    ).toLowerCase();

    // 1. Kiểm tra tính hợp lệ & đúng loại tài sản của giấy tờ pháp lý
    final typeKeywords = _keywordsForType(assetType);
    final generalValKeywords = [
      'chung thu tham dinh',
      'tham dinh gia',
      'tai san bao dam',
    ];
    final matchedType = typeKeywords
        .where((kw) => asciiLower.contains(kw))
        .length;
    final matchedValuation = generalValKeywords
        .where((kw) => asciiLower.contains(kw))
        .length;

    if (matchedType == 0 && matchedValuation == 0) {
      throw Exception(
        'Ảnh không phải giấy tờ pháp lý hợp lệ hoặc không khớp với loại tài sản đã chọn.',
      );
    }

    // 2. Kiểm tra trạng thái vô hiệu / đã tất toán / hết hiệu lực
    const invalidStatusKeywords = [
      'da tat toan',
      'het hieu luc',
      'da huy',
      'khong con gia tri',
      'da thanh ly',
      'da thu hoi',
      'qua han',
    ];
    for (final kw in invalidStatusKeywords) {
      if (asciiLower.contains(kw)) {
        throw Exception(
          'Giấy tờ tài sản đã tất toán hoặc hết hiệu lực sử dụng.',
        );
      }
    }

    // 3. Kiểm tra ngày hết hạn / ngày đến hạn
    final ref = now ?? DateTime.now();
    final today = DateTime(ref.year, ref.month, ref.day);
    final lines = trimmed
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    String? expiryIso;
    for (final line in lines) {
      final lineAscii = CccdScannerService.removeVietnameseDiacritics(
        line,
      ).toLowerCase();
      if (lineAscii.contains('den han') ||
          lineAscii.contains('het han') ||
          lineAscii.contains('gia tri den') ||
          lineAscii.contains('hieu luc den') ||
          lineAscii.contains('expiry')) {
        final dateMatches = RegExp(
          r'(\d{2})[/\-](\d{2})[/\-](\d{4})',
        ).allMatches(line).toList();
        if (dateMatches.isNotEmpty) {
          final m = dateMatches.last;
          final iso = '${m.group(3)}-${m.group(2)}-${m.group(1)}';
          final parsed = DateTime.tryParse(iso);
          if (parsed != null) {
            expiryIso = iso;
            final expDay = DateTime(parsed.year, parsed.month, parsed.day);
            if (expDay.isBefore(today)) {
              throw Exception(
                'Giấy tờ tài sản đã hết hạn sử dụng (hạn: ${m.group(1)}/${m.group(2)}/${m.group(3)}).',
              );
            }
          }
        }
      }
    }

    // 4. Đối chiếu số CCCD chính chủ với hồ sơ eKYC
    final foundIds = RegExp(
      r'\b(\d{12})\b',
    ).allMatches(trimmed).map((m) => m.group(1)!).toList();
    if (foundIds.isEmpty) {
      throw Exception(
        'Không tìm thấy số CCCD chủ tài sản trên giấy tờ (ảnh bị lóa/mờ hoặc thiếu thông tin pháp lý).',
      );
    }

    final cleanExpectedId = expectedIdCardNumber.trim();
    if (cleanExpectedId.length == 12 && !foundIds.contains(cleanExpectedId)) {
      throw Exception(
        'Giấy tờ không thuộc chính chủ! CCCD trên giấy tờ (${foundIds.first}) không khớp với hồ sơ eKYC ($cleanExpectedId).',
      );
    }

    // 5. Đối chiếu họ tên chủ sở hữu nếu có trên hồ sơ eKYC
    if (expectedOwnerName != null && expectedOwnerName.trim().isNotEmpty) {
      final expectedAscii = CccdScannerService.removeVietnameseDiacritics(
        expectedOwnerName,
      ).toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
      final normDoc = asciiLower.replaceAll(RegExp(r'\s+'), ' ');
      if (expectedAscii.length >= 4 && !normDoc.contains(expectedAscii)) {
        throw Exception(
          'Tên chủ sở hữu trên giấy tờ không khớp với hồ sơ eKYC ($expectedOwnerName).',
        );
      }
    }

    // 6. Trích xuất giá trị tài sản (VNĐ) — bắt buộc có giá trị trên chứng từ
    final extractedValue = _extractMonetaryValue(lines);
    if (extractedValue == null) {
      throw Exception(
        'Không đọc được giá trị định giá (VNĐ) trên giấy tờ. Vui lòng tải chứng từ hoặc chứng thư thẩm định có ghi rõ giá trị tài sản.',
      );
    }

    // 7. Trích xuất mã chứng từ / biển số / số thửa & tên tài sản tự động
    final certificateNumber = _extractCertificateNumber(lines, assetType);
    final extractedName = _extractAssetName(
      lines,
      assetType,
      certificateNumber,
    );

    return CollateralScanResult(
      assetType: assetType,
      rawText: trimmed,
      ownerIdCard: cleanExpectedId.length == 12
          ? cleanExpectedId
          : foundIds.first,
      extractedName: extractedName,
      extractedValue: extractedValue,
      certificateNumber: certificateNumber,
      expiryDate: expiryIso,
    );
  }

  static String _extractAssetName(
    List<String> lines,
    String assetType,
    String? certNumber,
  ) {
    for (final line in lines) {
      final ascii = CccdScannerService.removeVietnameseDiacritics(
        line,
      ).toLowerCase();
      if (ascii.contains('tai san tham dinh:') ||
          ascii.contains('ten tai san:')) {
        final after = line.split(':').sublist(1).join(':').trim();
        if (after.length >= 3) return after;
      }
    }
    switch (assetType.toUpperCase()) {
      case 'SAVINGS':
        return certNumber != null
            ? 'Sổ tiết kiệm $certNumber'
            : 'Sổ tiết kiệm có kỳ hạn';
      case 'VEHICLE':
        String? brand;
        for (final line in lines) {
          final ascii = CccdScannerService.removeVietnameseDiacritics(
            line,
          ).toLowerCase();
          if (ascii.contains('nhan hieu')) {
            final cleaned = line
                .replaceAll(RegExp(r'^.*?:\s*'), '')
                .replaceAll('|', ' ')
                .trim();
            if (cleaned.isNotEmpty) {
              brand = cleaned;
              break;
            }
          }
        }
        if (brand != null && certNumber != null) {
          return 'Ô tô $brand ($certNumber)';
        }
        return certNumber != null
            ? 'Phương tiện $certNumber'
            : 'Phương tiện ô tô';
      case 'REAL_ESTATE':
        return certNumber != null
            ? 'Bất động sản ($certNumber)'
            : 'Bất động sản / Nhà đất';
      default:
        return certNumber != null
            ? 'Tài sản bảo đảm ($certNumber)'
            : 'Tài sản bảo đảm định giá';
    }
  }

  static List<String> _keywordsForType(String assetType) {
    switch (assetType.toUpperCase()) {
      case 'SAVINGS':
        return [
          'so tiet kiem',
          'tien gui',
          'ky han',
          'lai suat',
          'tai khoan tiet kiem',
          'ngay den han',
          'menh gia',
        ];
      case 'VEHICLE':
        return [
          'dang ky xe',
          'cavet',
          'bien so',
          'so khung',
          'so may',
          'nhan hieu',
          'dang kiem',
          'xe o to',
        ];
      case 'REAL_ESTATE':
        return [
          'quyen su dung dat',
          'so hong',
          'so do',
          'thua dat',
          'to ban do',
          'dien tich',
          'muc dich su dung',
        ];
      default:
        return ['tham dinh gia', 'tai san bao dam', 'giay chung nhan'];
    }
  }

  static double? _extractMonetaryValue(List<String> lines) {
    final candidates = <double>[];
    for (final line in lines) {
      final ascii = CccdScannerService.removeVietnameseDiacritics(
        line,
      ).toLowerCase();
      final isValueLine =
          ascii.contains('so tien') ||
          ascii.contains('gia tri') ||
          ascii.contains('tham dinh') ||
          ascii.contains('menh gia') ||
          ascii.contains('vnd') ||
          ascii.contains('dong');
      if (!isValueLine) continue;

      final matches = RegExp(r'(\d{1,3}(?:[.,]\d{3}){2,})').allMatches(line);
      for (final m in matches) {
        final digits = m.group(1)!.replaceAll(RegExp(r'[.,]'), '');
        final val = double.tryParse(digits);
        if (val != null && val >= 1000000) {
          candidates.add(val);
        }
      }
    }
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.last;
  }

  static String? _extractCertificateNumber(
    List<String> lines,
    String assetType,
  ) {
    for (final line in lines) {
      final ascii = CccdScannerService.removeVietnameseDiacritics(
        line,
      ).toLowerCase();
      if (assetType == 'VEHICLE' &&
          (ascii.contains('bien so') || ascii.contains('bks'))) {
        final plate = RegExp(
          r'\b(\d{2}[A-Z]{1,2}[-\s]?\d{3}\.\d{2})\b',
        ).firstMatch(line.toUpperCase());
        if (plate != null) return plate.group(1);
      }
      if (assetType == 'SAVINGS' &&
          (ascii.contains('so tai khoan') || ascii.contains('ma so'))) {
        final tk = RegExp(
          r'\b([A-Z]{0,3}-?\d{6,14})\b',
        ).firstMatch(line.toUpperCase());
        if (tk != null) return tk.group(1);
      }
      if (assetType == 'REAL_ESTATE' && ascii.contains('thua dat')) {
        final plot = RegExp(r'\b(\d{1,5})\b').firstMatch(line);
        if (plot != null) return 'Thửa ${plot.group(1)}';
      }
    }
    return null;
  }
}
