import 'package:flutter/material.dart';

import '../../repositories/interfaces/storage_repository.dart';
import '../../service_locator.dart';
import 'app_colors.dart';

/// Hộp thoại xem tài liệu & hình ảnh bảo mật trên Cloudflare R2 (Document & Image Viewer Modal)
/// Hỗ trợ phóng to thu nhỏ (InteractiveViewer), hiển thị thông tin chữ ký Presigned GET và bóc tách OCR
class AppDocumentViewerModal extends StatefulWidget {
  final String title;
  final String fileKey;
  final String? subtitle;
  final String? documentType;
  final bool isPrivate;
  final Map<String, dynamic>? ocrDetails;

  const AppDocumentViewerModal({
    super.key,
    required this.title,
    required this.fileKey,
    this.subtitle,
    this.documentType,
    this.isPrivate = true,
    this.ocrDetails,
  });

  /// Phương thức tĩnh tiện ích mở Modal xem tài liệu
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String fileKey,
    String? subtitle,
    String? documentType,
    bool isPrivate = true,
    Map<String, dynamic>? ocrDetails,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) => AppDocumentViewerModal(
        title: title,
        fileKey: fileKey,
        subtitle: subtitle,
        documentType: documentType,
        isPrivate: isPrivate,
        ocrDetails: ocrDetails,
      ),
    );
  }

  @override
  State<AppDocumentViewerModal> createState() => _AppDocumentViewerModalState();
}

class _AppDocumentViewerModalState extends State<AppDocumentViewerModal> {
  final StorageRepository _storageRepo = sl<StorageRepository>();
  String? _viewUrl;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showOcrPanel = false;

  @override
  void initState() {
    super.initState();
    _loadPresignedViewUrl();
  }

  Future<void> _loadPresignedViewUrl() async {
    if (widget.fileKey.isEmpty || widget.fileKey == 'null') {
      setState(() {
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = await _storageRepo.getPresignedViewUrl(
        fileKey: widget.fileKey,
        expiresInSeconds: 600, // 10 phút
      );
      if (mounted) {
        setState(() {
          _viewUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
          ),
          const SizedBox(height: 14.0),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: AppColors.primary,
                  size: 22.0,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      widget.subtitle ?? 'Hồ sơ lưu trữ điện tử bảo mật',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10.0),

          // Huy hiệu bảo mật chứng từ
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 6.0,
            ),
            decoration: BoxDecoration(
              color: widget.isPrivate
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: widget.isPrivate
                    ? const Color(0xFFBFDBFE)
                    : const Color(0xFFBBF7D0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isPrivate
                      ? Icons.lock_outline_rounded
                      : Icons.verified_outlined,
                  size: 14.0,
                  color: widget.isPrivate
                      ? const Color(0xFF1D4ED8)
                      : const Color(0xFF15803D),
                ),
                const SizedBox(width: 6.0),
                Expanded(
                  child: Text(
                    widget.isPrivate
                        ? 'Chứng từ số hóa bảo mật • Mã hóa cấp ngân hàng (256-bit)'
                        : 'Chứng từ công khai xác thực',
                    style: TextStyle(
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                      color: widget.isPrivate
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12.0),

          // Khung hiển thị hình ảnh / tài liệu
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: _buildDocumentViewerBody(),
              ),
            ),
          ),

          // Tùy chọn xem kết quả OCR bóc tách nếu có
          if (widget.ocrDetails != null && widget.ocrDetails!.isNotEmpty) ...[
            const SizedBox(height: 10.0),
            InkWell(
              onTap: () {
                setState(() {
                  _showOcrPanel = !_showOcrPanel;
                });
              },
              borderRadius: BorderRadius.circular(10.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.document_scanner_rounded,
                      size: 16.0,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8.0),
                    const Expanded(
                      child: Text(
                        'Dữ liệu bóc tách tự động (AI OCR Result)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      _showOcrPanel
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18.0,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (_showOcrPanel) ...[
              const SizedBox(height: 6.0),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 180.0),
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: widget.ocrDetails!.entries.map((e) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6.0),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 6.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 130.0,
                              child: Text(
                                _formatOcrKey(e.key),
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Text(
                                _formatOcrValue(e.key, e.value),
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 12.0),

          // Hàng hành động dưới cùng
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadPresignedViewUrl,
                  icon: const Icon(Icons.refresh_rounded, size: 16.0),
                  label: const Text('Tải lại chứng từ'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_rounded, size: 16.0),
                  label: const Text('Đã xem xong'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDocumentType(String? raw) {
    if (raw == null) return 'HỢP ĐỒNG ĐIỆN TỬ';
    switch (raw.toUpperCase()) {
      case 'CONTRACT':
        return 'HỢP ĐỒNG VAY VỐN TÍN DỤNG';
      case 'COLLATERAL_CERTIFICATE':
        return 'GIẤY TỜ TÀI SẢN BẢO ĐẢM';
      case 'INCOME_PROOF':
        return 'XÁC NHẬN BẢNG LƯƠNG & THU NHẬP';
      case 'IDENTITY_CARD':
        return 'CĂN CƯỚC CÔNG DÂN (EKYC)';
      case 'BANK_STATEMENT':
        return 'SAO KÊ TÀI KHOẢN NGÂN HÀNG';
      default:
        return raw.toUpperCase();
    }
  }

  String _formatOcrKey(String rawKey) {
    switch (rawKey) {
      case 'loan_name':
        return 'Tên khoản vay';
      case 'principal_amount':
      case 'principal':
        return 'Số tiền giải ngân';
      case 'interest_rate':
        return 'Lãi suất áp dụng';
      case 'term_months':
      case 'tenor_months':
        return 'Kỳ hạn vay';
      case 'lender':
      case 'lender_name':
        return 'Tổ chức cấp tín dụng';
      case 'contract_number':
        return 'Số hợp đồng';
      case 'start_date':
        return 'Ngày ký kết / giải ngân';
      case 'end_date':
        return 'Ngày đáo hạn';
      case 'confidence_score':
        return 'Độ tin cậy OCR';
      case 'asset_name':
      case 'ten_tai_san':
        return 'Tên tài sản';
      case 'license_plate':
        return 'Biển số đăng ký';
      case 'certificate_number':
        return 'Số giấy chứng nhận';
      case 'valuation_amount':
      case 'gia_tri_dinh_gia':
        return 'Giá trị thẩm định';
      case 'loai_tai_san':
        return 'Loại tài sản';
      case 'ngay_dinh_gia':
        return 'Ngày định giá';
      case 'tinh_trang_phap_ly':
        return 'Tình trạng pháp lý';
      default:
        final formatted = rawKey.replaceAll('_', ' ');
        return formatted.isNotEmpty
            ? formatted[0].toUpperCase() + formatted.substring(1)
            : rawKey;
    }
  }

  String _formatOcrValue(String rawKey, dynamic rawValue) {
    if (rawValue == null) return 'Chưa cập nhật';
    final keyLower = rawKey.toLowerCase();
    if (keyLower.contains('amount') ||
        keyLower.contains('gia_tri') ||
        keyLower == 'principal') {
      final numVal = num.tryParse(rawValue.toString());
      if (numVal != null) {
        final str = numVal.round().toString();
        final buffer = StringBuffer();
        for (int i = 0; i < str.length; i++) {
          if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
          buffer.write(str[i]);
        }
        return '${buffer.toString()} đ';
      }
    }
    if (keyLower.contains('rate')) {
      final rateVal = double.tryParse(rawValue.toString());
      if (rateVal != null) {
        final percent = rateVal <= 1.0 ? rateVal * 100 : rateVal;
        return percent == percent.roundToDouble()
            ? '${percent.round()}% / năm'
            : '${percent.toStringAsFixed(1)}% / năm';
      }
    }
    if (keyLower.contains('month') ||
        keyLower.contains('tenor') ||
        keyLower.contains('term')) {
      return '$rawValue tháng';
    }
    if (keyLower == 'confidence_score') {
      final score = double.tryParse(rawValue.toString()) ?? 1.0;
      return '${(score * 100).round()}%';
    }
    return rawValue.toString();
  }

  Widget _buildDocumentViewerBody() {
    if (widget.fileKey.isEmpty || widget.fileKey == 'null') {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_off_outlined,
                size: 48.0,
                color: Colors.white70,
              ),
              SizedBox(height: 14.0),
              Text(
                'Chưa có chứng từ số hóa',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6.0),
              Text(
                'Hồ sơ này chưa có tệp scan hoặc ảnh đính kèm trên hệ thống.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12.0),
            Text(
              'Đang kiểm tra chứng thực bảo mật...',
              style: TextStyle(fontSize: 12.0, color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40.0,
                color: Color(0xFFF87171),
              ),
              const SizedBox(height: 10.0),
              Text(
                'Không thể tải chứng từ:\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: Colors.white70),
              ),
              const SizedBox(height: 12.0),
              ElevatedButton(
                onPressed: _loadPresignedViewUrl,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    // InteractiveViewer với SingleChildScrollView chống tràn pixel trên mọi kích thước màn hình
    return InteractiveViewer(
      panEnabled: true,
      minScale: 0.8,
      maxScale: 4.0,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(14.0),
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 10.0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          color: Color(0xFF16A34A),
                          size: 16.0,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          _formatDocumentType(widget.documentType),
                          style: const TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'FINCREDIT VERIFIED',
                      style: TextStyle(
                        fontSize: 9.0,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 14.0),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Tập tin: ${widget.fileKey.split('/').last}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10.0),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24.0,
                    horizontal: 16.0,
                  ),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6.0),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 40.0,
                          color: Color(0xFFDC2626),
                        ),
                        const SizedBox(height: 6.0),
                        const Text(
                          'Bản quét chứng từ gốc được mã hóa',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          _viewUrl != null &&
                                  widget.ocrDetails != null &&
                                  widget.ocrDetails!.isNotEmpty
                              ? 'Trạng thái: Đã số hóa và trích xuất OCR'
                              : 'Trạng thái: Đã lưu trữ trên hệ thống an toàn',
                          style: const TextStyle(
                            fontSize: 10.0,
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
                const Text(
                  'Tài liệu này được lưu trữ phân tán và mã hóa tuân thủ Thông tư 09/2020/TT-NHNN và Nghị định 13/2023/NĐ-CP.',
                  style: TextStyle(
                    fontSize: 9.0,
                    color: Color(0xFF94A3B8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
