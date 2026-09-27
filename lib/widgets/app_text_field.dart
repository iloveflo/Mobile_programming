import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Ô nhập liệu chuẩn FinCredit bọc [TextFormField],
/// hỗ trợ nhãn riêng biệt, viền tương tác, validation, và toggle mật khẩu tiện lợi.
class AppTextField extends StatefulWidget {
  /// Nhãn hiển thị phía trên ô nhập liệu
  final String? label;

  /// Văn bản gợi ý (placeholder) bên trong ô nhập
  final String? hint;

  /// Bộ điều khiển nội dung nhập
  final TextEditingController? controller;

  /// Giá trị khởi tạo khi không truyền controller
  final String? initialValue;

  /// Đánh dấu là trường mật khẩu (tự động bật ẩn ký tự và toggle mắt xem)
  final bool isPassword;

  /// Widget biểu tượng hoặc thành phần ở đầu ô nhập
  final Widget? prefixIcon;

  /// Widget biểu tượng hoặc thành phần ở cuối ô nhập (ghi đè toggle mật khẩu nếu truyền)
  final Widget? suffixIcon;

  /// Kiểu bàn phím hiển thị
  final TextInputType keyboardType;

  /// Hành động bàn phím (Next, Done, v.v.)
  final TextInputAction? textInputAction;

  /// Hàm kiểm tra tính hợp lệ dữ liệu
  final String? Function(String?)? validator;

  /// Callback khi nội dung ô nhập thay đổi
  final ValueChanged<String>? onChanged;

  /// Trạng thái cho phép thao tác
  final bool enabled;

  /// FocusNode quản lý con trỏ
  final FocusNode? focusNode;

  /// Chế độ tự động xác thực
  final AutovalidateMode? autovalidateMode;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
    this.autovalidateMode,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPassword != widget.isPassword && !widget.isPassword) {
      _obscureText = false;
    }
  }

  void _toggleObscureText() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget? effectiveSuffixIcon = widget.suffixIcon;

    // Tự động tạo nút bật/tắt mật khẩu nếu là trường password và không có suffixIcon custom
    if (widget.isPassword && effectiveSuffixIcon == null) {
      effectiveSuffixIcon = IconButton(
        icon: Icon(
          _obscureText
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppColors.textSecondary,
          size: 20.0,
        ),
        splashRadius: 20.0,
        onPressed: _toggleObscureText,
        tooltip: _obscureText ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          Text(
            widget.label!,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 8.0),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          autovalidateMode: widget.autovalidateMode,
          style: const TextStyle(
            fontSize: 15.0,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              fontSize: 15.0,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: widget.enabled
                ? AppColors.surface
                : AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: effectiveSuffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.border, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.border, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: AppColors.primaryLight,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.error, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: AppColors.border.withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
