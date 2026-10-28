/// Thùng chứa (Barrel file) export toàn bộ hệ thống Reusable UI Widgets
/// và Design Tokens cho dự án FinCredit.
///
/// Cấu trúc phân nhóm thư mục:
/// - `common/`: Design tokens, buttons, inputs, snackbars, navigation bars
/// - `auth/`: OTP, password strength, security badges
/// - `loans/`: Loan cards, portfolio summary, payment cards, LTV bars
/// - `debt_strategy/`: Bộ widgets tối ưu trả nợ (Snowball & Avalanche)
/// - `simulation/`: Bộ widgets mô phỏng các kịch bản trả nợ
/// - `dev/`: Panel công cụ trạng thái môi trường phát triển
///
/// Cách sử dụng:
/// ```dart
/// import 'package:my_first_app/widgets/widget.dart';
/// ```
library;

// Common & Design Tokens
export 'common/app_button.dart';
export 'common/app_colors.dart';
export 'common/app_snack_bar.dart';
export 'common/app_text_field.dart';
export 'common/custom_bottom_nav_bar.dart';
export 'common/quick_chip_selector.dart';

// Auth & Security
export 'auth/otp_input_field.dart';
export 'auth/password_strength_meter.dart';
export 'auth/security_badge.dart';

// Loans & Portfolio
export 'loans/interest_method_card.dart';
export 'loans/loan_card.dart';
export 'loans/ltv_indicator_bar.dart';
export 'loans/monthly_estimate_card.dart';
export 'loans/portfolio_summary_card.dart';

// Debt Strategy
export 'debt_strategy/active_plan_banner.dart';
export 'debt_strategy/debt_comparison_view.dart';
export 'debt_strategy/debt_overview_card.dart';
export 'debt_strategy/debt_priority_list.dart';
export 'debt_strategy/debt_strategy_selector.dart';

// Simulation
export 'simulation/simulation_comparison_table.dart';
export 'simulation/simulation_history_sheet.dart';
export 'simulation/simulation_input_card.dart';
export 'simulation/simulation_notice_card.dart';
export 'simulation/simulation_scenario_selector.dart';

// Credit Profile
export 'credit/credit_empty_state.dart';
export 'credit/credit_factor_sheet.dart';
export 'credit/credit_metric_card.dart';
export 'credit/credit_score_gauge.dart';

// Credit Report
export 'credit_report/credit_report_card.dart';
export 'credit_report/credit_report_detail_view.dart';
export 'credit_report/credit_report_empty_state.dart';
export 'credit_report/credit_report_trend_card.dart';
export 'credit_report/generate_report_dialog.dart';

// Payment Schedule & Reminders
export 'schedule/notification_list_sheet.dart';
export 'schedule/notification_preference_sheet.dart';
export 'schedule/payment_schedule_card.dart';
export 'schedule/schedule_detail_sheet.dart';
export 'schedule/schedule_empty_state.dart';
export 'schedule/schedule_summary_card.dart';

// Dev Tools
export 'dev/dev_state_panel.dart';

// Core Utils
export '../core/utils/app_validators.dart';
