import 'package:flutter/material.dart';

import '../widget.dart';

class _ArticleItem {
  final String tag;
  final String title;
  final String summary;
  final IconData icon;
  final Color color;

  const _ArticleItem({
    required this.tag,
    required this.title,
    required this.summary,
    required this.icon,
    required this.color,
  });
}

/// Băng chuyền hiển thị các bài viết Cẩm nang tài chính & Tín dụng trên trang chủ
class HomeEducationCarousel extends StatelessWidget {
  const HomeEducationCarousel({super.key});

  static const List<_ArticleItem> _articles = [
    _ArticleItem(
      tag: 'Mẹo tiết kiệm',
      title: 'Cách đàm phán giảm 1-2% lãi suất vay khi biên độ thả nổi tăng',
      summary:
          'Chủ động đề xuất xem xét lại lịch sử trả nợ đúng hạn với cán bộ tín dụng và đăng ký gói bảo hiểm liên kết để hưởng ưu đãi biên độ tốt nhất.',
      icon: Icons.savings_outlined,
      color: Color(0xFF0D47A1),
    ),
    _ArticleItem(
      tag: 'Quản lý tài chính',
      title: 'Quy tắc 50/30/20: Cân đối chi tiêu gia đình và trả nợ đúng hạn',
      summary:
          '50% cho nhu cầu thiết yếu, 30% cho mong muốn cá nhân và 20% dành riêng cho tích lũy khẩn cấp cùng kế hoạch tất toán nợ gốc sớm.',
      icon: Icons.pie_chart_outline_rounded,
      color: Color(0xFF059669),
    ),
    _ArticleItem(
      tag: 'Tín dụng CIC',
      title:
          'Những điều cần tránh để không bị phân loại sang nợ nhóm 2 trở lên',
      summary:
          'Chậm trả quá 10 ngày sẽ tự động nhảy nhóm nợ CIC trên toàn quốc, ảnh hưởng đến việc xét duyệt vay vốn và hạn mức thẻ tín dụng trong 3 năm.',
      icon: Icons.security_rounded,
      color: Color(0xFFD97706),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Cẩm nang tài chính & Tín dụng',
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 10.0),
        SizedBox(
          height: 145.0,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            scrollDirection: Axis.horizontal,
            itemCount: _articles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12.0),
            itemBuilder: (context, index) {
              final art = _articles[index];
              return InkWell(
                onTap: () => ArticleDetailModal.show(
                  context,
                  title: art.title,
                  summary: art.summary,
                ),
                borderRadius: BorderRadius.circular(14.0),
                child: Container(
                  width: 250.0,
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14.0),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x060F172A),
                        blurRadius: 8.0,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(art.icon, size: 18.0, color: art.color),
                          const SizedBox(width: 6.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: art.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              art.tag,
                              style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                color: art.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        art.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const Row(
                        children: [
                          Text(
                            'Đọc ngay',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14.0,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
