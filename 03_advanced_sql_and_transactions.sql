-- ============================================================================
-- FILE 3: 03_advanced_sql_and_transactions.sql
-- DESCRIPTION: CTEs, Window Functions & ACID Transaction Management
-- ============================================================================

-- 1. DIAGNOSTIC LAB TURNAROUND TIME (TAT) & SLA BREACH ANALYSIS (CTE)
WITH lab_tat AS (
    SELECT 
        lo.lab_order_id,
        b.branch_name,
        lt.category,
        lt.test_name,
        lt.sla_hours,
        ROUND(EXTRACT(EPOCH FROM (lo.completed_at - lo.ordered_at)) / 3600.0, 2) AS actual_tat_hours
    FROM lab_orders lo
    JOIN lab_tests lt ON lo.test_id = lt.test_id
    JOIN branches b ON lo.branch_id = b.branch_id
    WHERE lo.order_status = 'Completed'
)
SELECT 
    branch_name,
    category,
    COUNT(*) AS completed_tests,
    ROUND(AVG(actual_tat_hours), 2) AS avg_tat_hrs,
    ROUND(AVG(sla_hours), 2) AS target_sla_hrs,
    SUM(CASE WHEN actual_tat_hours > sla_hours THEN 1 ELSE 0 END) AS sla_breaches,
    ROUND(100.0 * SUM(CASE WHEN actual_tat_hours > sla_hours THEN 1 ELSE 0 END) / COUNT(*), 1) AS breach_rate_pct
FROM lab_tat
GROUP BY branch_name, category
ORDER BY breach_rate_pct DESC, avg_tat_hrs DESC;

-- 2A. WINDOW FUNCTION: Doctor Revenue Ranking Within Specialty (DENSE_RANK)
SELECT 
    d.specialty,
    d.full_name AS doctor_name,
    b.branch_name,
    COUNT(a.appointment_id) AS completed_consults,
    COALESCE(SUM(bi.total_amount - bi.discount_amt), 0) AS total_generated_revenue,
    DENSE_RANK() OVER (
        PARTITION BY d.specialty 
        ORDER BY COALESCE(SUM(bi.total_amount - bi.discount_amt), 0) DESC
    ) AS specialty_revenue_rank
FROM doctors d
JOIN branches b ON d.branch_id = b.branch_id
LEFT JOIN appointments a ON d.doctor_id = a.doctor_id AND a.status = 'Completed'
LEFT JOIN billing_invoices bi ON a.appointment_id = bi.appointment_id
GROUP BY d.specialty, d.full_name, b.branch_name;

-- 2B. WINDOW FUNCTION: Cumulative Realized Revenue & Lag Comparison
SELECT 
    bi.invoice_id,
    DATE(bi.billed_at) AS billing_date,
    b.branch_name,
    (bi.total_amount - bi.discount_amt) AS net_amount,
    LAG(bi.total_amount - bi.discount_amt) OVER (ORDER BY bi.billed_at) AS prev_invoice_amt,
    SUM(bi.total_amount - bi.discount_amt) OVER (
        ORDER BY bi.billed_at ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM billing_invoices bi
JOIN appointments a ON bi.appointment_id = a.appointment_id
JOIN branches b ON a.branch_id = b.branch_id
WHERE bi.payment_status = 'Paid'
ORDER BY bi.billed_at;

-- 3A. TRANSACTION MANAGEMENT: Atomic Claim Settlement & Audit Log (COMMIT)
BEGIN;

UPDATE billing_invoices
SET payment_status = 'Paid'
WHERE invoice_id = 4 AND payment_status = 'Pending';

INSERT INTO audit_logs (entity_name, entity_id, action_type, remarks)
VALUES ('billing_invoices', 4, 'CLAIM_SETTLED', 'Star Health claim cleared and reconciled');

COMMIT;

-- 3B. TRANSACTION MANAGEMENT: Constraint Violation & Safe Rollback (ROLLBACK)
BEGIN;

UPDATE billing_invoices
SET payment_status = 'Refunded',
    total_amount = -500.00 -- Violates CHECK (total_amount >= 0)
WHERE invoice_id = 7;

ROLLBACK;

-- Verification Queries
SELECT * FROM audit_logs;
SELECT invoice_id, total_amount, payment_status FROM billing_invoices WHERE invoice_id IN (4, 7);
