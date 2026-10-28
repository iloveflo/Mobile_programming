import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Dữ liệu cấu hình cho từng mục điều hướng trên thanh Bottom Navigation Bar
class _NavItemData {
  final IconData unselectedIcon;
  final IconData selectedIcon;
  final String label;

  const _NavItemData({
    required this.unselectedIcon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Widget Thanh điều hướng gốc (Custom Bottom Navigation Bar) 6 Tabs
/// Tích hợp hiệu ứng trượt Ẩn / Hiện mượt mà (AnimatedSlide + AnimatedOpacity)
/// theo tương tác cuộn nội dung của người dùng.
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isVisible;

  static const List<_NavItemData> _items = [
    _NavItemData(
      unselectedIcon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Trang chủ',
    ),
    _NavItemData(
      unselectedIcon: Icons.account_balance_wallet_outlined,
      selectedIcon: Icons.account_balance_wallet_rounded,
      label: 'Khoản vay',
    ),
    _NavItemData(
      unselectedIcon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      label: 'Lịch trả nợ',
    ),
    _NavItemData(
      unselectedIcon: Icons.shield_outlined,
      selectedIcon: Icons.shield_rounded,
      label: 'Tín dụng',
    ),
    _NavItemData(
      unselectedIcon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Cá nhân',
    ),
    _NavItemData(
      unselectedIcon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Cài đặt',
    ),
  ];

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      offset: isVisible ? Offset.zero : const Offset(0.0, 1.0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isVisible ? 1.0 : 0.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(
              top: BorderSide(color: AppColors.border, width: 1.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10.0,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 60.0,
              child: Row(
                children: List.generate(_items.length, (index) {
                  final item = _items[index];
                  final isSelected = index == currentIndex;

                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => onTap(index),
                        splashColor: AppColors.primarySoft,
                        highlightColor: Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primarySoft
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Icon(
                                isSelected
                                    ? item.selectedIcon
                                    : item.unselectedIcon,
                                size: 22.0,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3.0),
                            Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
