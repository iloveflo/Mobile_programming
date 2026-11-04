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
export 'common/app_document_viewer_modal.dart';
export 'common/app_snack_bar.dart';
export 'common/app_text_field.dart';
export 'common/custom_bottom_nav_bar.dart';
export 'common/quick_chip_selector.dart';

// Auth & Security
export 'auth/otp_input_field.dart';
export 'auth/password_strength_meter.dart';
export 'auth/security_badge.dart';

// Loans & Portfolio
export 'loans/add_collateral_dialog.dart';
export 'loans/early_payoff_modal.dart';
export 'loans/interest_method_card.dart';
export 'loans/loan_card.dart';
export 'loans/loan_contract_documents_section.dart';
export 'loans/loan_repayment_schedule_sheet.dart';
export 'loans/ltv_indicator_bar.dart';
export 'loans/monthly_estimate_card.dart';
export 'loans/portfolio_summary_card.dart';
export 'loans/quick_add_collateral_sheet.dart';

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

// Profile & Account
export 'profile/bank_accounts_sheet.dart';
export 'profile/change_password_sheet.dart';
export 'profile/edit_contact_sheet.dart';
export 'profile/edit_income_sheet.dart';
export 'profile/ekyc_verification_sheet.dart';
export 'profile/financial_profile_pdf_helper.dart';

// Home Components
export 'home/article_detail_modal.dart';
export 'home/cashflow_detail_sheet.dart';
export 'home/customer_support_modal.dart';
export 'home/debt_planning_sheet.dart';
export 'home/dti_report_modal.dart';
export 'home/home_active_loans_slider.dart';
export 'home/home_cashflow_projection_card.dart';
export 'home/home_dti_gauge_card.dart';
export 'home/home_education_carousel.dart';
export 'home/home_hero_card.dart';
export 'home/home_quick_action_grid.dart';
export 'home/home_security_footer.dart';
export 'home/home_urgent_due_banner.dart';
export 'home/quick_interest_calculator_dialog.dart';

// Dev Tools
export 'dev/dev_state_panel.dart';

// Core Utils
export '../core/utils/app_validators.dart';
