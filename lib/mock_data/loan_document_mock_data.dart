import '../models/loan_document_model.dart';

class LoanDocumentMockData {
  static final List<LoanDocumentModel> loanDocumentsDatabase = [
    LoanDocumentModel(
      id: 1,
      loanId: 1,
      documentType: 'CONTRACT',
      fileUrl: 'https://example.com/mock/loan-contract-001.pdf',
      ocrStatus: 'COMPLETED',
      ocrResult: {
        'loan_name': 'Vay tiêu dùng cá nhân',
        'principal_amount': 50000000.0,
      },
      createdAt: DateTime(2026, 1, 10, 10),
      updatedAt: DateTime(2026, 1, 10, 10, 5),
    ),
  ];
}
