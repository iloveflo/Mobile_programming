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

    -- Thông tin hồ sơ định danh, việc làm & tín dụng (khớp UserModel FinCredit)
    id_card_number VARCHAR(20) UNIQUE NULL,
    address VARCHAR(255) NULL,
    occupation VARCHAR(100) NULL,
    workplace VARCHAR(150) NULL,
    contract_type VARCHAR(100) NULL,
    is_ekyc_verified BOOLEAN NOT NULL DEFAULT FALSE,
    ekyc_tier VARCHAR(30) NULL,
    membership_tier VARCHAR(30) NOT NULL DEFAULT 'STANDARD',
    cic_score INT NULL,

    -- Bổ sung trường phục vụ bảo mật & quản trị tài khoản
    is_biometric_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_locked BOOLEAN NOT NULL DEFAULT FALSE,
    lock_until DATETIME NULL,
    failed_login_attempts INT NOT NULL DEFAULT 0,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);


-- =========================================================
-- 2. BANK ACCOUNTS (TÀI KHOẢN NGÂN HÀNG LIÊN KẾT)
-- =========================================================
CREATE TABLE bank_accounts (
    account_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(50) NOT NULL,
    account_holder_name VARCHAR(100) NOT NULL,
    is_default_disbursal BOOLEAN NOT NULL DEFAULT FALSE,
    is_auto_debit BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_bank_accounts_user
        FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT uq_user_bank_account
        UNIQUE (user_id, bank_name, account_number)
);


-- =========================================================
-- 3. LOAN TYPES
-- =========================================================
CREATE TABLE loan_types (
    loan_type_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    type_code VARCHAR(30) NOT NULL UNIQUE, -- Mã chuẩn hóa: MORTGAGE, CAR, CONSUMER, CREDIT_CARD, OTHER
    type_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =========================================================
-- 4. LOANS
-- =========================================================
CREATE TABLE loans (
    loan_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL,
    loan_type_id INT UNSIGNED NOT NULL,

    loan_name VARCHAR(150) NOT NULL,
    lender_name VARCHAR(100) NULL, -- Ngân hàng / Tổ chức tín dụng (Techcombank, Vietcombank, MBBank, VIB...)
    loan_type VARCHAR(30) NULL,    -- Khóa định danh loại: MORTGAGE, CAR, CONSUMER, CREDIT_CARD, OTHER

    principal_amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(7,4) NOT NULL, -- Lãi suất hàng năm (ví dụ 0.0850 tương ứng 8.5%/năm)
    interest_method VARCHAR(50) NOT NULL, -- REDUCING_BALANCE hoặc FLAT

    term_months INT UNSIGNED NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,

    outstanding_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    early_payment_fee_rate DECIMAL(7,4) DEFAULT 0,

    status VARCHAR(30) NOT NULL DEFAULT 'ACTIVE', -- ACTIVE, CLOSED, OVERDUE, SETTLED

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
-- 5. ASSETS (TÀI SẢN BẢO ĐẢM / COLLATERAL)
-- =========================================================
CREATE TABLE assets (
    asset_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL,
    loan_id BIGINT UNSIGNED NULL,

    asset_name VARCHAR(150) NOT NULL,
    asset_type VARCHAR(50) NOT NULL, -- REAL_ESTATE, VEHICLE, SAVINGS, OTHER
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
-- 6. LOAN DOCUMENTS
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
-- 7. PAYMENT SCHEDULES
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
-- 8. PAYMENTS
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
-- 9. CREDIT PROFILES
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
-- 10. CREDIT REPORTS
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
-- 11. NOTIFICATIONS
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
-- 12. DEBT STRATEGIES
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
-- 13. SIMULATIONS
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
-- 14. REFRESH TOKENS & SESSIONS (QUẢN LÝ PHIÊN THIẾT BỊ)
-- =========================================================
CREATE TABLE refresh_tokens (
    token_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NOT NULL,

    token TEXT NOT NULL,
    
    -- Thông tin thiết bị phục vụ màn hình M06 & SessionModel
    device_name VARCHAR(150) NULL,
    platform VARCHAR(100) NULL,
    ip_address VARCHAR(50) NULL,
    location VARCHAR(150) NULL,
    last_active DATETIME DEFAULT CURRENT_TIMESTAMP,

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
-- 15. OTP VERIFICATIONS
-- =========================================================
CREATE TABLE otp_verifications (
    otp_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,

    user_id BIGINT UNSIGNED NULL, -- Cho phép NULL khi OTP gửi cho luồng Đăng ký tài khoản mới
    email VARCHAR(150) NULL,
    phone VARCHAR(20) NULL,

    otp_code VARCHAR(10) NOT NULL,
    purpose VARCHAR(50) NOT NULL, -- REGISTER, FORGOT_PASSWORD, TRANSACTION

    attempt_count INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 5,

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
-- 16. NOTIFICATION PREFERENCES
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


-- =========================================================
-- 17. DỮ LIỆU KHỞI TẠO MẪU (SEED DATA TƯƠNG THÍCH VỚI APP)
-- =========================================================

-- A. LOAN TYPES
INSERT INTO loan_types (loan_type_id, type_code, type_name, description) VALUES
(1, 'CONSUMER', 'Vay tiêu dùng / Tín chấp', 'Khoản vay tín chấp tiêu dùng không bắt buộc tài sản bảo đảm'),
(2, 'MORTGAGE', 'Vay thế chấp / Bất động sản', 'Khoản vay có tài sản bảo đảm là bất động sản hoặc nhà đất'),
(3, 'CAR', 'Vay mua xe / Ô tô', 'Khoản vay thế chấp mua phương tiện đi lại, ô tô'),
(4, 'CREDIT_CARD', 'Thẻ tín dụng', 'Hạn mức thấu chi thẻ tín dụng chi tiêu linh hoạt'),
(5, 'OTHER', 'Khoản vay khác', 'Các gói tín dụng và khoản vay cá nhân khác')
ON DUPLICATE KEY UPDATE type_name=VALUES(type_name);

-- B. USERS (Tài khoản thử nghiệm tương thích UserMockData)
INSERT INTO users (
    user_id, full_name, email, phone, password_hash, monthly_income, date_of_birth,
    id_card_number, address, occupation, workplace, contract_type,
    is_ekyc_verified, ekyc_tier, membership_tier, cic_score,
    is_biometric_enabled, is_active
) VALUES (
    1, 'Nguyen Van Dev', 'dev@test.com', '0900000001', '123456', 25000000.00, '1998-05-12',
    '079201008888', 'Tòa nhà Landmark 81, P. 22, Q. Bình Thạnh, TP. Hồ Chí Minh', 'Kỹ sư Phần mềm Senior', 'Tập đoàn Công nghệ FPT', 'Hợp đồng lao động không xác định thời hạn',
    TRUE, 'C06', 'GOLD', 745,
    TRUE, TRUE
)
ON DUPLICATE KEY UPDATE full_name=VALUES(full_name);

-- C. BANK ACCOUNTS (Tài khoản ngân hàng liên kết khớp UserMockData)
INSERT INTO bank_accounts (account_id, user_id, bank_name, account_number, account_holder_name, is_default_disbursal, is_auto_debit) VALUES
(1, 1, 'Techcombank', '190382918888', 'NGUYEN VAN DEV', TRUE, FALSE),
(2, 1, 'Vietcombank', '007100129999', 'NGUYEN VAN DEV', FALSE, TRUE)
ON DUPLICATE KEY UPDATE bank_name=VALUES(bank_name);

-- D. LOANS (Các khoản vay mẫu khớp với LoanMockData)
INSERT INTO loans (loan_id, user_id, loan_type_id, loan_name, lender_name, loan_type, principal_amount, interest_rate, interest_method, term_months, start_date, end_date, outstanding_amount, early_payment_fee_rate, status) VALUES
(101, 1, 3, 'Vay mua xe VinFast VF8', 'Vietcombank', 'CAR', 500000000.00, 0.0850, 'REDUCING_BALANCE', 48, '2025-06-15', '2029-06-15', 385000000.00, 0.0150, 'ACTIVE'),
(102, 1, 4, 'Thẻ tín dụng VIB Super Card', 'VIB', 'CREDIT_CARD', 100000000.00, 0.2400, 'FLAT', 12, '2026-01-05', '2027-01-05', 28500000.00, 0.0000, 'ACTIVE'),
(103, 1, 1, 'Vay tiêu dùng tín chấp', 'MBBank', 'CONSUMER', 80000000.00, 0.1200, 'REDUCING_BALANCE', 24, '2026-02-20', '2028-02-20', 62000000.00, 0.0200, 'ACTIVE'),
(104, 1, 2, 'Vay mua căn hộ Sunrise City', 'Techcombank', 'MORTGAGE', 1800000000.00, 0.0790, 'REDUCING_BALANCE', 120, '2024-03-10', '2034-03-10', 1540000000.00, 0.0250, 'ACTIVE'),
(105, 1, 1, 'Vay tiền mặt qua sao kê lương', 'FE Credit', 'CONSUMER', 30000000.00, 0.1800, 'FLAT', 12, '2025-01-15', '2026-01-15', 0.00, 0.0300, 'CLOSED')
ON DUPLICATE KEY UPDATE loan_name=VALUES(loan_name);

-- E. ASSETS (Tài sản thế chấp khớp với AssetMockData)
INSERT INTO assets (asset_id, user_id, loan_id, asset_name, asset_type, asset_value, valuation_date, description) VALUES
(1, 1, 101, 'Ô tô VinFast VF8 Plus 2023', 'VEHICLE', 750000000.00, '2025-06-01', 'Xe thế chấp giải ngân khoản vay Vietcombank. Cavet gốc giữ tại ngân hàng.'),
(2, 1, 104, 'Căn hộ chung cư Sunrise City (85m2)', 'REAL_ESTATE', 2800000000.00, '2024-02-20', 'Sổ hồng căn hộ tháp W2, tầng 18. Thế chấp vay Techcombank.'),
(3, 1, NULL, 'Sổ tiết kiệm BIDV kỳ hạn 12 tháng', 'SAVINGS', 250000000.00, '2026-08-31', 'Tài sản thanh khoản cao dùng dự phòng tài chính.')
ON DUPLICATE KEY UPDATE asset_name=VALUES(asset_name);

-- F. SESSIONS & REFRESH TOKENS (Các phiên đăng nhập khớp SessionModel)
INSERT INTO refresh_tokens (token_id, user_id, token, device_name, platform, ip_address, location, last_active, expires_at) VALUES
(1, 1, 'mock_refresh_token_001', 'iPhone 15 Pro Max', 'iOS 17.5 • FinCredit App', '113.161.45.12', 'TP. Hồ Chí Minh, Việt Nam', NOW(), '2026-12-31 23:59:59'),
(2, 1, 'mock_refresh_token_002', 'MacBook Pro 16" M3', 'macOS Sonoma • Chrome 128', '113.161.45.12', 'TP. Hồ Chí Minh, Việt Nam', DATE_SUB(NOW(), INTERVAL 3 HOUR), '2026-12-31 23:59:59'),
(3, 1, 'mock_refresh_token_003', 'Samsung Galaxy S24 Ultra', 'Android 14 • OneUI 6.1', '14.232.208.9', 'Hà Nội, Việt Nam', DATE_SUB(NOW(), INTERVAL 2 DAY), '2026-12-31 23:59:59')
ON DUPLICATE KEY UPDATE device_name=VALUES(device_name);

-- G. CREDIT PROFILE
INSERT INTO credit_profiles (user_id, credit_score, dti_ratio, ltv_ratio, credit_utilization, on_time_payment_rate, active_loan_count, risk_level) VALUES
(1, 745, 0.3200, 0.5500, 0.2850, 0.9800, 4, 'LOW')
ON DUPLICATE KEY UPDATE credit_score=VALUES(credit_score);

-- H. NOTIFICATION PREFERENCES
INSERT INTO notification_preferences (user_id, push_enabled, email_enabled, sms_enabled, reminder_days) VALUES
(1, TRUE, TRUE, FALSE, 3)
ON DUPLICATE KEY UPDATE push_enabled=VALUES(push_enabled);