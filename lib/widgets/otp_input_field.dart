import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Ô nhập mã xác thực OTP 6 số chuẩn Fintech.
/// Tự động chuyển focus, hỗ trợ dán cụm số, xóa lùi (backspace),
/// và highlight ô active bằng viền [AppColors.primary] và nền [AppColors.primarySoft].
class OtpInputField extends StatefulWidget {
  /// Số lượng ký tự OTP (mặc định là 6)
  final int length;

  /// Callback khi người dùng nhập đủ toàn bộ các ô OTP
  final ValueChanged<String> onCompleted;

  /// Callback mỗi khi một ô thay đổi giá trị
  final ValueChanged<String>? onChanged;

  const OtpInputField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (index) {
      final node = FocusNode(
        debugLabel: 'OtpBox_$index',
        onKeyEvent: (node, event) {
          // Xử lý khi nhấn Backspace trên ô đang rỗng để tự động lùi về ô trước
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_controllers[index].text.isEmpty && index > 0) {
              _controllers[index - 1].clear();
              _focusNodes[index - 1].requestFocus();
              _notifyChange();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
      );

      // Lắng nghe để cập nhật màu nền và viền cho ô đang active (focused)
      node.addListener(() {
        if (mounted) setState(() {});
      });

      return node;
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Thu thập chuỗi OTP hiện tại từ tất cả các ô
  String get _currentOtp => _controllers.map((c) => c.text).join();

  void _notifyChange() {
    final otp = _currentOtp;
    widget.onChanged?.call(otp);
    if (otp.length == widget.length && !otp.contains(' ')) {
      widget.onCompleted(otp);
    }
  }

  /// Xử lý dán (Paste) cả cụm số từ clipboard vào các ô
  void _handlePaste(String text, int startIndex) {
    final cleanDigits = text.replaceAll(RegExp(r'\D'), '');
    if (cleanDigits.isEmpty) return;

    for (
      int i = 0;
      i < cleanDigits.length && (startIndex + i) < widget.length;
      i++
    ) {
      _controllers[startIndex + i].text = cleanDigits[i];
    }

    final int targetFocusIndex = (startIndex + cleanDigits.length).clamp(
      0,
      widget.length - 1,
    );
    _focusNodes[targetFocusIndex].requestFocus();
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return _buildDigitBox(index);
      }),
    );
  }

  Widget _buildDigitBox(int index) {
    final bool isFocused = _focusNodes[index].hasFocus;
    final bool hasValue = _controllers[index].text.isNotEmpty;

    // Màu sắc theo trạng thái active/hasValue/idle
    Color backgroundColor = AppColors.surface;
    Color borderColor = AppColors.border;
    double borderWidth = 1.0;

    if (isFocused) {
      backgroundColor = AppColors.primarySoft;
      borderColor = AppColors.primary;
      borderWidth = 2.0;
    } else if (hasValue) {
      backgroundColor = AppColors.surface;
      borderColor = AppColors.primaryLight;
      borderWidth = 1.2;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48.0,
      height: 54.0,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 8.0,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          cursorColor: AppColors.primary,
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            counterText: '',
          ),
          onChanged: (value) {
            if (value.length > 1) {
              // Trường hợp dán hoặc gõ nhanh nhiều số
              _handlePaste(value, index);
              return;
            }

            if (value.isNotEmpty) {
              // Nhập xong số này, tự động chuyển sang ô kế tiếp
              if (index < widget.length - 1) {
                _focusNodes[index + 1].requestFocus();
              } else {
                // Đã đến ô cuối cùng
                _focusNodes[index].unfocus();
              }
            }

            _notifyChange();
          },
        ),
      ),
    );
  }
}
