// thư mục widget để viết những thành phần dùng chung tái sử dụng dc nhiều lần, đóng vai trò là khung cho Frontend như:
// nút bấm
// phông chữ
// định dạng
// bố cục,......
/// Thùng chứa (Barrel file) export toàn bộ hệ thống Reusable UI Widgets
/// và Design Tokens cho dự án FinCredit.
///
/// Cách sử dụng:
/// ```dart
/// import 'package:my_first_app/widgets/widget.dart';
/// ```
library;

export 'app_button.dart';
export 'app_colors.dart';
export 'app_text_field.dart';
export 'dev_state_panel.dart';
export 'interest_method_card.dart';
export 'loan_card.dart';
export 'ltv_indicator_bar.dart';
export 'monthly_estimate_card.dart';
export 'otp_input_field.dart';
export 'password_strength_meter.dart';
export 'portfolio_summary_card.dart';
export 'quick_chip_selector.dart';
export 'security_badge.dart';
export 'custom_bottom_nav_bar.dart';
export 'app_snack_bar.dart';
export '../core/utils/app_validators.dart';
