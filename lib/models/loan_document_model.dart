class LoanDocumentModel {
  final int id;
  final int loanId;
  final String documentType;
  final String fileUrl;
  final String ocrStatus;
  final Map<String, dynamic>? ocrResult;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LoanDocumentModel({
    required this.id,
    required this.loanId,
    required this.documentType,
    required this.fileUrl,
    required this.ocrStatus,
    this.ocrResult,
    this.createdAt,
    this.updatedAt,
  });

  factory LoanDocumentModel.fromJson(Map<String, dynamic> json) {
    return LoanDocumentModel(
      id: json['document_id'] as int,
      loanId: json['loan_id'] as int,
      documentType: json['document_type'] as String,
      fileUrl: json['file_url'] as String,
      ocrStatus: json['ocr_status'] as String? ?? 'PENDING',
      ocrResult: (json['ocr_result'] as Map?)?.cast<String, dynamic>(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'document_id': id,
    'loan_id': loanId,
    'document_type': documentType,
    'file_url': fileUrl,
    'ocr_status': ocrStatus,
    'ocr_result': ocrResult,
    'created_at': createdAt?.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
  };

  String get documentTypeDisplay {
    switch (documentType.toUpperCase()) {
      case 'CONTRACT':
        return 'Hợp đồng vay vốn tín dụng';
      case 'COLLATERAL_CERTIFICATE':
        return 'Giấy tờ tài sản bảo đảm';
      case 'INCOME_PROOF':
        return 'Xác nhận thu nhập';
      case 'IDENTITY_CARD':
        return 'Căn cước công dân (eKYC)';
      case 'BANK_STATEMENT':
        return 'Sao kê tài khoản';
      default:
        final formatted = documentType.replaceAll('_', ' ');
        return formatted.isNotEmpty
            ? formatted[0].toUpperCase() + formatted.substring(1)
            : documentType;
    }
  }

  String get ocrStatusDisplay {
    switch (ocrStatus.toUpperCase()) {
      case 'COMPLETED':
        return 'Đã bóc tách AI';
      case 'PROCESSING':
        return 'Đang quét AI';
      case 'FAILED':
        return 'Chưa nhận diện';
      case 'PENDING':
      default:
        return 'Đang chờ xử lý';
    }
  }
}
