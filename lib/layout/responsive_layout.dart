import 'package:flutter/material.dart';

/// Ngưỡng kích thước màn hình chuẩn của FinCredit
class ResponsiveBreakpoints {
  const ResponsiveBreakpoints._();

  /// Màn hình điện thoại rất hẹp (VD: 320dp - 359dp)
  static const double compactMaxWidth = 360.0;

  /// Màn hình điện thoại tiêu chuẩn (< 600dp)
  static const double phoneMaxWidth = 600.0;

  /// Chiều rộng tối đa cho nội dung chính trên máy gập / tablet
  static const double contentMaxWidth = 600.0;

  static bool isCompactWidth(double width) => width < compactMaxWidth;
  static bool isWideScreen(double width) => width >= phoneMaxWidth;
}

/// Giới hạn tỷ lệ phóng to chữ hệ thống ở ngưỡng an toàn để giữ khả năng đọc
/// mà không làm vỡ bố cục nút bấm và thẻ dữ liệu.
class ResponsiveTextScaler {
  const ResponsiveTextScaler._();

  static TextScaler clamp(
    BuildContext context, {
    double minScale = 0.9,
    double maxScale = 1.25,
  }) {
    return MediaQuery.textScalerOf(
      context,
    ).clamp(minScaleFactor: minScale, maxScaleFactor: maxScale);
  }
}

/// Căn giữa và giới hạn chiều rộng tối đa của nội dung khi hiển thị trên màn hình rộng
class ResponsiveContentConstraint extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.contentMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= maxWidth) {
          return child;
        }
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        );
      },
    );
  }
}

/// Lưới thẻ 2 cột co giãn tự nhiên theo chiều cao nội dung (không dùng childAspectRatio cứng).
/// Tự động chuyển sang 1 cột khi chiều rộng nhỏ hơn [singleColumnBreakpoint].
class ResponsiveTwoColumnGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double singleColumnBreakpoint;

  const ResponsiveTwoColumnGrid({
    super.key,
    required this.children,
    this.spacing = 10.0,
    this.runSpacing = 10.0,
    this.singleColumnBreakpoint = 310.0,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < singleColumnBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) SizedBox(height: runSpacing),
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (int i = 0; i < children.length; i += 2) {
          final first = children[i];
          final second = i + 1 < children.length ? children[i + 1] : null;
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: first),
                  SizedBox(width: spacing),
                  Expanded(child: second ?? const SizedBox.shrink()),
                ],
              ),
            ),
          );
          if (i + 2 < children.length) {
            rows.add(SizedBox(height: runSpacing));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

/// Khung bọc chuẩn cho BottomSheet để tự cuộn an toàn khi xoay ngang (chiều cao thấp)
/// hoặc mở bàn phím, đồng thời giới hạn chiều rộng tối đa trên màn hình lớn.
class ResponsiveBottomSheetBody extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxHeightFactor;
  final double maxWidth;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;

  const ResponsiveBottomSheetBody({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.maxHeightFactor = 0.9,
    this.maxWidth = ResponsiveBreakpoints.contentMaxWidth,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * maxHeightFactor;

    Widget content = SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    if (backgroundColor != null || borderRadius != null) {
      content = Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: content,
      );
    }

    return content;
  }
}
