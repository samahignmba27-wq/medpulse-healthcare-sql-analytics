-- ============================================================================
-- FILE 1: 01_schema_and_seed_data.sql
-- PROJECT: Healthcare Clinic & Diagnostic Lab Operations Analytics (PostgreSQL)
-- ENTITY: MedPulse Clinics & Diagnostics Pvt. Ltd.
-- COURSE: SQL and Data Management (PMDE30605) - IILM University, Greater Noida
-- GROUP MEMBERS:
--   1. Samahi Vashist (25SOM2039000400)
--   2. Vyoma Srivastava (25SOM2039000268)
--   3. Samiksha Singh (25SOM2039000148)
-- ============================================================================

-- 1. CLEANUP (Safe re-run)
DROP TABLE IF EXISTS audit_logs, billing_invoices, lab_orders, lab_tests, appointments, doctors, patients, branches CASCADE;

-- 2. CREATE TABLES WITH CONSTRAINTS & RELATIONSHIPS (3NF NORMALIZED)
CREATE TABLE branches (
    branch_id      SERIAL PRIMARY KEY,
    branch_name    VARCHAR(100) NOT NULL UNIQUE,
    city           VARCHAR(50)  NOT NULL,
    region         VARCHAR(50)  NOT NULL,
    opened_date    DATE         NOT NULL
);

CREATE TABLE doctors (
    doctor_id        SERIAL PRIMARY KEY,
    branch_id        INT            NOT NULL REFERENCES branches(branch_id) ON DELETE RESTRICT,
    full_name        VARCHAR(100)   NOT NULL,
    specialty        VARCHAR(60)    NOT NULL,
    consultation_fee NUMERIC(10, 2) NOT NULL CHECK (consultation_fee > 0),
    is_active        BOOLEAN        NOT NULL DEFAULT TRUE
);

CREATE TABLE patients (
    patient_id         SERIAL PRIMARY KEY,
    full_name          VARCHAR(100) NOT NULL,
    gender             VARCHAR(15)  NOT NULL,
    dob                DATE         NOT NULL CHECK (dob <= CURRENT_DATE),
    phone              VARCHAR(20)  NOT NULL,
    city               VARCHAR(50),
    insurance_provider VARCHAR(80),
    registered_at      TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE appointments (
    appointment_id SERIAL PRIMARY KEY,
    patient_id     INT         NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    doctor_id      INT         NOT NULL REFERENCES doctors(doctor_id) ON DELETE RESTRICT,
    branch_id      INT         NOT NULL REFERENCES branches(branch_id) ON DELETE RESTRICT,
    appt_datetime  TIMESTAMP   NOT NULL,
    visit_type     VARCHAR(20) NOT NULL CHECK (visit_type IN ('Walk-In', 'Scheduled', 'Teleconsult')),
    status         VARCHAR(20) NOT NULL CHECK (status IN ('Completed', 'No-Show', 'Cancelled', 'Scheduled'))
);

CREATE TABLE lab_tests (
    test_id        SERIAL PRIMARY KEY,
    test_name      VARCHAR(100)   NOT NULL UNIQUE,
    category       VARCHAR(50)    NOT NULL CHECK (category IN ('Pathology', 'Radiology', 'Cardiology')),
    standard_price NUMERIC(10, 2) NOT NULL CHECK (standard_price > 0),
    sla_hours      INT            NOT NULL CHECK (sla_hours > 0)
);

CREATE TABLE lab_orders (
    lab_order_id   SERIAL PRIMARY KEY,
    appointment_id INT         NOT NULL REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    patient_id     INT         NOT NULL REFERENCES patients(patient_id) ON DELETE CASCADE,
    test_id        INT         NOT NULL REFERENCES lab_tests(test_id) ON DELETE RESTRICT,
    branch_id      INT         NOT NULL REFERENCES branches(branch_id) ON DELETE RESTRICT,
    ordered_at     TIMESTAMP   NOT NULL,
    completed_at   TIMESTAMP,
    order_status   VARCHAR(20) NOT NULL CHECK (order_status IN ('Completed', 'In-Progress', 'Delayed', 'Cancelled')),
    CONSTRAINT chk_completion_time CHECK (completed_at IS NULL OR completed_at >= ordered_at)
);

CREATE TABLE billing_invoices (
    invoice_id     SERIAL PRIMARY KEY,
    appointment_id INT            NOT NULL REFERENCES appointments(appointment_id) ON DELETE CASCADE,
    total_amount   NUMERIC(10, 2) NOT NULL CHECK (total_amount >= 0),
    discount_amt   NUMERIC(10, 2) NOT NULL DEFAULT 0 CHECK (discount_amt >= 0),
    payment_mode   VARCHAR(25)    NOT NULL CHECK (payment_mode IN ('UPI', 'Card', 'Cash', 'Insurance')),
    payment_status VARCHAR(25)    NOT NULL CHECK (payment_status IN ('Paid', 'Pending', 'Claim Rejected', 'Refunded')),
    billed_at      TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_logs (
    log_id      SERIAL PRIMARY KEY,
    entity_name VARCHAR(50) NOT NULL,
    entity_id   INT         NOT NULL,
    action_type VARCHAR(30) NOT NULL,
    remarks     TEXT,
    created_at  TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. PERFORMANCE INDEXES
CREATE INDEX idx_appt_branch_date ON appointments(branch_id, appt_datetime);
CREATE INDEX idx_lab_orders_status ON lab_orders(order_status, test_id);
CREATE INDEX idx_billing_status ON billing_invoices(payment_status);

-- 4. INSERT REALISTIC SAMPLE DATA (Includes intentional anomalies for ETL cleaning)
INSERT INTO branches (branch_name, city, region, opened_date) VALUES
('MedPulse South Ex', 'New Delhi', 'South NCR', '2021-03-15'),
('MedPulse Sector 62', 'Noida', 'East NCR', '2022-07-01'),
('MedPulse Cyber Hub', 'Gurugram', 'West NCR', '2023-01-20'),
('MedPulse Indirapuram', 'Ghaziabad', 'East NCR', '2023-11-10');

INSERT INTO doctors (branch_id, full_name, specialty, consultation_fee, is_active) VALUES
(1, 'Dr. Arvind Malhotra', 'Cardiology', 1500.00, TRUE),
(1, 'Dr. Neha Kapoor', 'General Medicine', 800.00, TRUE),
(2, 'Dr. Rohan Verma', 'Orthopedics', 1200.00, TRUE),
(2, 'Dr. Priya Nair', 'Gynecology', 1100.00, TRUE),
(3, 'Dr. Siddharth Jain', 'Cardiology', 1600.00, TRUE),
(3, 'Dr. Meera Joshi', 'Dermatology', 1000.00, TRUE),
(4, 'Dr. Kabir Sethi', 'General Medicine', 750.00, TRUE);

INSERT INTO patients (full_name, gender, dob, phone, city, insurance_provider) VALUES
('  Aarav Sharma ', 'male', '1988-05-14', '+91-9811122233', 'New Delhi', 'Star Health'),
('Ananya Gupta', 'Female', '1995-09-22', '9811122244', 'Noida', 'HDFC Ergo'),
('Vikramaditya Rao', 'M', '1979-12-03', '9811122255', 'Gurugram', NULL),
('Pooja Deshmukh', 'female', '1992-03-18', '+91 9811122266', 'Ghaziabad', 'ICICI Lombard'),
('Karan Mehra', 'Male', '1984-07-29', '9811122277', 'New Delhi', 'Star Health'),
('Sneha Kulkarni', 'F', '1998-11-11', '9811122288', 'Noida', NULL),
('Rajesh Bansal', 'Male', '1968-02-25', '9811122299', 'Gurugram', 'Niva Bupa'),
('Divya Chatterjee', 'Female', '1990-08-09', '9811122300', 'New Delhi', 'HDFC Ergo'),
('Aarav Sharma', 'Male', '1988-05-14', '9811122233', 'New Delhi', 'Star Health'), -- Duplicate record
('Manish Tiwari', 'Male', '1981-04-17', '9811122311', 'Ghaziabad', NULL);

INSERT INTO appointments (patient_id, doctor_id, branch_id, appt_datetime, visit_type, status) VALUES
(1, 1, 1, '2026-10-02 10:00:00', 'Scheduled', 'Completed'),
(2, 3, 2, '2026-10-03 11:30:00', 'Scheduled', 'Completed'),
(3, 5, 3, '2026-10-04 09:30:00', 'Walk-In', 'Completed'),
(4, 7, 4, '2026-10-05 16:00:00', 'Scheduled', 'No-Show'),
(5, 2, 1, '2026-10-06 12:00:00', 'Teleconsult', 'Completed'),
(6, 4, 2, '2026-10-07 14:30:00', 'Scheduled', 'Cancelled'),
(7, 5, 3, '2026-10-08 10:15:00', 'Scheduled', 'Completed'),
(8, 1, 1, '2026-10-09 15:00:00', 'Walk-In', 'Completed'),
(1, 2, 1, '2026-10-12 11:00:00', 'Scheduled', 'Completed'),
(10, 7, 4, '2026-10-14 17:30:00', 'Walk-In', 'Completed'),
(2, 4, 2, '2026-10-16 10:30:00', 'Scheduled', 'No-Show'),
(3, 6, 3, '2026-10-18 13:00:00', 'Scheduled', 'Completed'),
(5, 1, 1, '2026-10-20 09:45:00', 'Scheduled', 'Completed'),
(7, 6, 3, '2026-10-22 16:15:00', 'Scheduled', 'No-Show'),
(8, 2, 1, '2026-10-25 11:30:00', 'Teleconsult', 'Completed');

INSERT INTO lab_tests (test_name, category, standard_price, sla_hours) VALUES
('Complete Blood Count (CBC)', 'Pathology', 500.00, 6),
('Lipid Profile', 'Pathology', 1200.00, 12),
('HbA1c Glycated Hemoglobin', 'Pathology', 850.00, 8),
('MRI Brain Plain', 'Radiology', 6500.00, 24),
('2D Echocardiography', 'Cardiology', 2800.00, 4),
('Thyroid Profile (T3, T4, TSH)', 'Pathology', 950.00, 10);

INSERT INTO lab_orders (appointment_id, patient_id, test_id, branch_id, ordered_at, completed_at, order_status) VALUES
(1, 1, 5, 1, '2026-10-02 10:45:00', '2026-10-02 13:30:00', 'Completed'),
(1, 1, 2, 1, '2026-10-02 10:45:00', '2026-10-02 21:00:00', 'Completed'),
(2, 2, 1, 2, '2026-10-03 12:00:00', '2026-10-03 20:30:00', 'Completed'),
(3, 3, 4, 3, '2026-10-04 10:15:00', '2026-10-05 14:45:00', 'Completed'),
(5, 5, 3, 1, '2026-10-06 12:30:00', '2026-10-06 19:00:00', 'Completed'),
(7, 7, 5, 3, '2026-10-08 11:00:00', '2026-10-08 16:30:00', 'Completed'),
(8, 8, 2, 1, '2026-10-09 15:40:00', '2026-10-10 02:10:00', 'Completed'),
(10, 10, 1, 4, '2026-10-14 18:00:00', '2026-10-15 03:30:00', 'Completed'),
(12, 3, 6, 3, '2026-10-18 13:45:00', '2026-10-18 22:15:00', 'Completed'),
(13, 5, 5, 1, '2026-10-20 10:30:00', NULL, 'In-Progress');

INSERT INTO billing_invoices (appointment_id, total_amount, discount_amt, payment_mode, payment_status, billed_at) VALUES
(1, 5500.00, 500.00, 'Insurance', 'Paid', '2026-10-02 14:00:00'),
(2, 1700.00, 0.00, 'UPI', 'Paid', '2026-10-03 12:30:00'),
(3, 8100.00, 600.00, 'Card', 'Paid', '2026-10-04 10:30:00'),
(5, 1650.00, 150.00, 'Insurance', 'Pending', '2026-10-06 13:00:00'),
(7, 4400.00, 400.00, 'Insurance', 'Claim Rejected', '2026-10-08 17:00:00'),
(8, 2700.00, 0.00, 'Insurance', 'Paid', '2026-10-09 16:00:00'),
(9, 800.00, 0.00, 'UPI', 'Paid', '2026-10-12 11:45:00'),
(10, 1250.00, 0.00, 'Cash', 'Paid', '2026-10-14 18:15:00'),
(12, 1950.00, 0.00, 'Card', 'Paid', '2026-10-18 14:00:00'),
(13, 4300.00, 300.00, 'Insurance', 'Pending', '2026-10-20 11:00:00'),
(15, 800.00, 0.00, 'UPI', 'Paid', '2026-10-25 12:00:00');
