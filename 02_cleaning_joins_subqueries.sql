-- ============================================================================
-- FILE 2: 02_cleaning_joins_subqueries.sql
-- DESCRIPTION: Data Cleaning, Deduplication, Multi-Table Joins, Aggregations & Subqueries
-- ============================================================================

-- 1. DATA CLEANING & STANDARDIZATION
UPDATE patients
SET 
    full_name = INITCAP(TRIM(full_name)),
    gender = CASE 
        WHEN LOWER(TRIM(gender)) IN ('m', 'male') THEN 'Male'
        WHEN LOWER(TRIM(gender)) IN ('f', 'female') THEN 'Female'
        ELSE 'Other'
    END,
    phone = RIGHT(REGEXP_REPLACE(phone, '[^0-9]', '', 'g'), 10),
    insurance_provider = COALESCE(insurance_provider, 'Self-Pay');

-- 2. REMOVE DUPLICATE PATIENT RECORD (Self-Join Deduplication)
DELETE FROM patients p1
USING patients p2
WHERE p1.patient_id > p2.patient_id
  AND p1.phone = p2.phone
  AND p1.full_name = p2.full_name;

SELECT * FROM patients ORDER BY patient_id;

-- 3. MULTI-TABLE JOINS & AGGREGATIONS (Branch Revenue, Collections & No-Show Rate)
SELECT 
    b.branch_name,
    b.city,
    COUNT(DISTINCT a.appointment_id) AS total_appointments,
    SUM(CASE WHEN a.status = 'Completed' THEN 1 ELSE 0 END) AS completed_visits,
    SUM(CASE WHEN a.status = 'No-Show' THEN 1 ELSE 0 END) AS no_shows,
    ROUND(
        100.0 * SUM(CASE WHEN a.status = 'No-Show' THEN 1 ELSE 0 END) / COUNT(a.appointment_id), 2
    ) AS no_show_rate_pct,
    COALESCE(SUM(bi.total_amount - bi.discount_amt), 0) AS net_billed_revenue,
    COALESCE(SUM(CASE WHEN bi.payment_status = 'Paid' THEN (bi.total_amount - bi.discount_amt) ELSE 0 END), 0) AS realized_revenue
FROM branches b
LEFT JOIN appointments a ON b.branch_id = a.branch_id
LEFT JOIN billing_invoices bi ON a.appointment_id = bi.appointment_id
GROUP BY b.branch_id, b.branch_name, b.city
ORDER BY net_billed_revenue DESC;

-- 4A. SUBQUERY: High-Value Patients Above Clinic-Wide Average Invoice
SELECT 
    p.patient_id,
    p.full_name,
    p.insurance_provider,
    SUM(bi.total_amount - bi.discount_amt) AS total_patient_spend
FROM patients p
JOIN appointments a ON p.patient_id = a.patient_id
JOIN billing_invoices bi ON a.appointment_id = bi.appointment_id
GROUP BY p.patient_id, p.full_name, p.insurance_provider
HAVING SUM(bi.total_amount - bi.discount_amt) > (
    SELECT AVG(total_amount - discount_amt) FROM billing_invoices
)
ORDER BY total_patient_spend DESC;

-- 4B. SUBQUERY: Doctors Linked to Pending or Rejected Insurance Claims
SELECT 
    d.doctor_id,
    d.full_name AS doctor_name,
    d.specialty,
    b.branch_name
FROM doctors d
JOIN branches b ON d.branch_id = b.branch_id
WHERE d.doctor_id IN (
    SELECT DISTINCT a.doctor_id
    FROM appointments a
    JOIN billing_invoices bi ON a.appointment_id = bi.appointment_id
    WHERE bi.payment_status IN ('Pending', 'Claim Rejected')
);
