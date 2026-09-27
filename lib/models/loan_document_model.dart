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
}
