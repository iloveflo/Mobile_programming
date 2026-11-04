import 'package:flutter/material.dart';

import '../widget.dart';

/// Modal BottomSheet hiển thị nội dung bài viết cẩm nang tài chính FinCredit
class ArticleDetailModal extends StatelessWidget {
  final String title;
  final String summary;

  const ArticleDetailModal({
    super.key,
    required this.title,
    required this.summary,
  });

  /// Phương thức hiển thị modal
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String summary,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) => ArticleDetailModal(title: title, summary: summary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, color: AppColors.primary),
              const SizedBox(width: 8.0),
              const Text(
                'Cẩm nang FinCredit',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            summary,
            style: const TextStyle(
              fontSize: 13.0,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20.0),
        ],
      ),
    );
  }
}
