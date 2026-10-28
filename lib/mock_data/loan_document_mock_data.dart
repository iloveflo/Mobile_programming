import '../models/loan_document_model.dart';

class LoanDocumentMockData {
  static final List<LoanDocumentModel> loanDocumentsDatabase = [
    LoanDocumentModel(
      id: 1,
      loanId: 101,
      documentType: 'CONTRACT',
      fileUrl: 'https://example.com/mock/loan-contract-001.pdf',
      ocrStatus: 'COMPLETED',
      ocrResult: {
        'loan_name': 'Vay mua xe VinFast VF8',
        'principal_amount': 500000000.0,
      },
      createdAt: DateTime(2025, 6, 10, 8, 30),
      updatedAt: DateTime(2025, 6, 10, 8, 35),
    ),
  ];
}
