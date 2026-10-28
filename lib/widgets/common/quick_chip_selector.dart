import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Bộ chọn Chip nhanh theo chiều ngang (QuickChipSelector)
/// Hỗ trợ chọn nhanh Ngân hàng, Hạn mức số tiền hoặc Kỳ hạn vay
class QuickChipSelector<T> extends StatelessWidget {
  final String? title;
  final List<T> items;
  final T? selectedItem;
  final ValueChanged<T> onSelected;
  final String Function(T item)? labelBuilder;
  final Widget Function(T item)? leadingBuilder;
  final EdgeInsetsGeometry padding;

  const QuickChipSelector({
    super.key,
    this.title,
    required this.items,
    required this.selectedItem,
    required this.onSelected,
    this.labelBuilder,
    this.leadingBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 0),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8.0),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: padding,
          child: Row(
            children: items.map((item) {
              final isSelected = item == selectedItem;
              final label = labelBuilder != null
                  ? labelBuilder!(item)
                  : item.toString();
              final leading = leadingBuilder != null
                  ? leadingBuilder!(item)
                  : null;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () => onSelected(item),
                  borderRadius: BorderRadius.circular(10.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primarySoft
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryLight
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (leading != null) ...[
                          leading,
                          const SizedBox(width: 6.0),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
