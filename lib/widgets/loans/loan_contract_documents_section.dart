import 'package:flutter/material.dart';

import '../../models/loan_document_model.dart';
import '../../models/loan_model.dart';
import '../../service_locator.dart';
import '../../services/image_upload_service.dart';
import '../widget.dart';

/// Khối danh sách và tải lên hồ sơ hợp đồng điện tử của khoản vay
class LoanContractDocumentsSection extends StatelessWidget {
  final LoanModel loan;
  final List<LoanDocumentModel> documents;
  final VoidCallback onDocumentUploaded;

  const LoanContractDocumentsSection({
    super.key,
    required this.loan,
    required this.documents,
    required this.onDocumentUploaded,
  });

  Future<void> _handleUploadContractDocument(BuildContext context) async {
    final uploadService = sl<ImageUploadService>();
    final result = await uploadService.pickAndUploadImage(
      context,
      folder: 'contracts',
      filePrefix: 'contract_loan_${loan.id}',
      metadata: {'loan_id': loan.id.toString()},
    );
    if (!context.mounted) return;
    if (result != null) {
      AppSnackBar.showSuccess(context, 'Tải lên tài liệu hợp đồng thành công!');
      onDocumentUploaded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'HỒ SƠ HỢP ĐỒNG ĐIỆN TỬ',
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            InkWell(
              onTap: () => _handleUploadContractDocument(context),
              borderRadius: BorderRadius.circular(6.0),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 15.0,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 4.0),
                    Text(
                      'Tải lên',
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        if (documents.isEmpty)
          Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  color: AppColors.textSecondary,
                  size: 24.0,
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    'Chưa có hồ sơ scan hợp đồng. Nhấn "Tải lên" để lưu trữ chứng từ bảo mật.',
                    style: TextStyle(
                      fontSize: 12.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: documents.map((doc) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                        size: 22.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.documentTypeDisplay,
                            style: const TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2.0),
                          Row(
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 12.0,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                'Chứng từ mã hóa • ${doc.ocrStatusDisplay}',
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10.0,
                          vertical: 6.0,
                        ),
                      ),
                      onPressed: () {
                        AppDocumentViewerModal.show(
                          context,
                          title: doc.documentTypeDisplay,
                          fileKey: doc.fileUrl,
                          documentType: doc.documentTypeDisplay,
                          ocrDetails: doc.ocrResult,
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 15.0),
                      label: const Text(
                        'Xem',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
