import '../models/loan_document_model.dart';

class LoanDocumentMockData {
  static final List<LoanDocumentModel> loanDocumentsDatabase = [
    LoanDocumentModel(
      id: 1,
      loanId: 101,
      documentType: 'CONTRACT',
      fileUrl: 'contracts/loans/101/hop_dong_tin_dung_vinfast_vf8.pdf',
      ocrStatus: 'COMPLETED',
      ocrResult: {
        'loan_name': 'Vay mua xe VinFast VF8',
        'principal_amount': 500000000.0,
        'interest_rate': 0.085,
        'term_months': 48,
        'lender': 'Vietcombank',
      },
      createdAt: DateTime(2025, 6, 10, 8, 30),
      updatedAt: DateTime(2025, 6, 10, 8, 35),
    ),
    LoanDocumentModel(
      id: 2,
      loanId: 101,
      documentType: 'COLLATERAL_CERTIFICATE',
      fileUrl: 'collaterals/101/cavet_xe_vinfast_vf8.jpg',
      ocrStatus: 'COMPLETED',
      ocrResult: {
        'asset_name': 'Ô tô VinFast VF8 Plus 2023',
        'license_plate': '51K-888.88',
        'valuation_amount': 750000000.0,
      },
      createdAt: DateTime(2025, 6, 11, 9, 0),
      updatedAt: DateTime(2025, 6, 11, 9, 10),
    ),
    LoanDocumentModel(
      id: 3,
      loanId: 104,
      documentType: 'CONTRACT',
      fileUrl: 'contracts/loans/104/hop_dong_the_chap_sunrise_city.pdf',
      ocrStatus: 'COMPLETED',
      ocrResult: {
        'loan_name': 'Vay mua căn hộ Sunrise City',
        'principal_amount': 1800000000.0,
        'interest_rate': 0.079,
        'term_months': 120,
        'lender': 'Techcombank',
      },
      createdAt: DateTime(2024, 3, 5, 8, 0),
      updatedAt: DateTime(2024, 3, 5, 8, 20),
    ),
    LoanDocumentModel(
      id: 4,
      loanId: 104,
      documentType: 'COLLATERAL_CERTIFICATE',
      fileUrl: 'collaterals/104/so_hong_can_ho_sunrise_city.jpg',
      ocrStatus: 'COMPLETED',
      ocrResult: {
        'asset_name': 'Căn hộ chung cư Sunrise City (85m2)',
        'certificate_number': 'SH-789201',
        'valuation_amount': 2800000000.0,
      },
      createdAt: DateTime(2024, 3, 6, 10, 0),
      updatedAt: DateTime(2024, 3, 6, 10, 15),
    ),
  ];
}
