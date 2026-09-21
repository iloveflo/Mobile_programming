CREATE DATABASE IF NOT EXISTS credit_health_db
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE credit_health_db;


-- =========================================================
-- 1. USERS
-- =========================================================
CREATE TABLE users (
    user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    phone VARCHAR(20) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    monthly_income DECIMAL(15,2),
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);


-- =========================================================
-- 2. LOAN TYPES
-- =========================================================
CREATE TABLE loan_types (
    loan_type_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- 3. LOANS
-- =========================================================
CREATE TABLE loans (
    loan_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL,
    loan_type_id INT UNSIGNED NOT NULL,

    loan_name VARCHAR(150) NOT NULL,
    principal_amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(7,4) NOT NULL,
    interest_method VARCHAR(50) NOT NULL,

    term_months INT UNSIGNED NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,

    outstanding_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    early_payment_fee_rate DECIMAL(7,4) DEFAULT 0,

    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_loans_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_loans_type
        FOREIGN KEY (loan_type_id)
        REFERENCES loan_types(loan_type_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);


-- =========================================================
-- 4. ASSETS
-- =========================================================
CREATE TABLE assets (
    asset_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL,
    loan_id BIGINT UNSIGNED NULL,

    asset_name VARCHAR(150) NOT NULL,
    asset_type VARCHAR(50) NOT NULL,
    asset_value DECIMAL(15,2) NOT NULL,
    valuation_date DATE,
    description TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_assets_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_assets_loan
        FOREIGN KEY (loan_id)
        REFERENCES loans(loan_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);


-- =========================================================
-- 5. LOAN DOCUMENTS
-- =========================================================
CREATE TABLE loan_documents (
    document_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    loan_id BIGINT UNSIGNED NOT NULL,

    document_type VARCHAR(50) NOT NULL,
    file_url VARCHAR(500) NOT NULL,

    ocr_status VARCHAR(30) DEFAULT 'PENDING',
    ocr_result JSON,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_documents_loan
        FOREIGN KEY (loan_id)
        REFERENCES loans(loan_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- =========================================================
-- 6. PAYMENT SCHEDULES
-- =========================================================
CREATE TABLE payment_schedules (
    schedule_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    loan_id BIGINT UNSIGNED NOT NULL,

    installment_number INT UNSIGNED NOT NULL,
    due_date DATE NOT NULL,

    principal_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    interest_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    fee_amount DECIMAL(15,2) NOT NULL DEFAULT 0,

    total_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    remaining_balance DECIMAL(15,2) NOT NULL DEFAULT 0,

    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_schedule_loan
        FOREIGN KEY (loan_id)
        REFERENCES loans(loan_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT uq_schedule_installment
        UNIQUE (loan_id, installment_number)
);


-- =========================================================
-- 7. PAYMENTS
-- =========================================================
CREATE TABLE payments (
    payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    schedule_id BIGINT UNSIGNED NOT NULL,

    paid_amount DECIMAL(15,2) NOT NULL,
    paid_date DATETIME NOT NULL,

    payment_method VARCHAR(50) NOT NULL,
    transaction_reference VARCHAR(150),
    note TEXT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_payments_schedule
        FOREIGN KEY (schedule_id)
        REFERENCES payment_schedules(schedule_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- =========================================================
-- 8. CREDIT PROFILES
-- =========================================================
CREATE TABLE credit_profiles (
    profile_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL UNIQUE,

    credit_score INT,
    dti_ratio DECIMAL(7,4),
    ltv_ratio DECIMAL(7,4),
    credit_utilization DECIMAL(7,4),
    on_time_payment_rate DECIMAL(7,4),

    active_loan_count INT UNSIGNED DEFAULT 0,
    risk_level VARCHAR(30),

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_credit_profiles_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- =========================================================
-- 9. CREDIT REPORTS
-- =========================================================
CREATE TABLE credit_reports (
    report_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL,

    credit_score INT,
    dti_ratio DECIMAL(7,4),
    ltv_ratio DECIMAL(7,4),
    credit_utilization DECIMAL(7,4),
    on_time_payment_rate DECIMAL(7,4),

    total_debt DECIMAL(15,2) DEFAULT 0,
    overdue_amount DECIMAL(15,2) DEFAULT 0,

    risk_level VARCHAR(30),
    report_period VARCHAR(30),

    generated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_credit_reports_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- =========================================================
-- 10. NOTIFICATIONS
-- =========================================================
CREATE TABLE notifications (
    notification_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL,
    schedule_id BIGINT UNSIGNED NULL,

    notification_type VARCHAR(50) NOT NULL,
    channel VARCHAR(30) NOT NULL,

    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,

    scheduled_at DATETIME,
    sent_at DATETIME,

    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_notifications_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_notifications_schedule
        FOREIGN KEY (schedule_id)
        REFERENCES payment_schedules(schedule_id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);


-- =========================================================
-- 11. DEBT STRATEGIES
-- =========================================================
CREATE TABLE debt_strategies (
    strategy_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL,

    strategy_type VARCHAR(30) NOT NULL,
    extra_payment DECIMAL(15,2) DEFAULT 0,

    estimated_interest_saved DECIMAL(15,2),
    estimated_months_saved INT,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_strategies_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- =========================================================
-- 12. SIMULATIONS
-- =========================================================
CREATE TABLE simulations (
    simulation_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL,
    loan_id BIGINT UNSIGNED NOT NULL,

    extra_payment DECIMAL(15,2) DEFAULT 0,

    early_payment_fee DECIMAL(15,2) DEFAULT 0,
    estimated_interest DECIMAL(15,2) DEFAULT 0,
    estimated_interest_saved DECIMAL(15,2) DEFAULT 0,

    months_reduced INT DEFAULT 0,
    total_saving DECIMAL(15,2) DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_simulations_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_simulations_loan
        FOREIGN KEY (loan_id)
        REFERENCES loans(loan_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- =========================================================
-- 13. REFRESH TOKENS
-- =========================================================
CREATE TABLE refresh_tokens (
    token_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL,

    token TEXT NOT NULL,
    expires_at DATETIME NOT NULL,
    revoked_at DATETIME NULL,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_refresh_tokens_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- =========================================================
-- 14. OTP VERIFICATIONS
-- =========================================================
CREATE TABLE otp_verifications (
    otp_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL,

    otp_code VARCHAR(10) NOT NULL,
    purpose VARCHAR(50) NOT NULL,

    expires_at DATETIME NOT NULL,
    verified_at DATETIME NULL,

    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_otp_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- =========================================================
-- 15. NOTIFICATION PREFERENCES
-- =========================================================
CREATE TABLE notification_preferences (
    preference_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL UNIQUE,

    push_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    email_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    sms_enabled BOOLEAN NOT NULL DEFAULT FALSE,

    reminder_days INT NOT NULL DEFAULT 3,

    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_notification_preferences_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);