# Healthcare Clinic & Diagnostic Lab Operations Analytics (PostgreSQL)

**Entity:** MedPulse Clinics & Diagnostics Pvt. Ltd.  
**Institution:** IILM University, Greater Noida  
**Program:** Master of Business Administration (MBA)  
**Course:** SQL and Data Management (`PMDE30605`)  
**Submission Date:** 25th November 2026  

---

## Group Members
| S. No. | Student Name | Roll Number | Module Contribution |
| :--- | :--- | :--- | :--- |
| 1 | **Samahi Vashist** | `25SOM2039000400` | Database Architecture, 3NF Normalization, ERD & DDL Implementation |
| 2 | **Vyoma Srivastava** | `25SOM2039000268` | ETL Data Cleaning, Regex Standardization, Joins & Subqueries |
| 3 | **Samiksha Singh** | `25SOM2039000148` | Advanced SQL (CTEs, Window Functions), ACID Transactions & Risk Governance |

---

## Project Overview
This project models and analyzes end-to-end clinical and diagnostic operations across four Delhi NCR branches (**MedPulse South Ex**, **Sector 62 Noida**, **Cyber Hub Gurugram**, and **Indirapuram Ghaziabad**) using **PostgreSQL 18**.

### Key Analytical Objectives
1. **3NF Relational Schema & Constraints:** 8 normalized tables (`branches`, `doctors`, `patients`, `appointments`, `lab_tests`, `lab_orders`, `billing_invoices`, `audit_logs`) protected by `PRIMARY KEY`, `FOREIGN KEY`, `CHECK`, and composite B-tree indexes.
2. **Data Hygiene & Deduplication:** Regex-based phone normalization, case/whitespace standardization, missing insurance imputation (`Self-Pay`), and self-join duplicate removal.
3. **Operational & Financial Analytics:** Multi-table joins, scalar/correlated subqueries, CTE-based Turnaround Time (TAT) SLA breach analysis, and window functions (`DENSE_RANK`, `LAG`, running `SUM OVER`).
4. **ACID Governance:** Atomic `BEGIN` / `COMMIT` / `ROLLBACK` transaction workflows with automated audit logging.

---

## Repository Structure
* `01_schema_and_seed_data.sql` — Database schema DDL, referential/domain constraints, indexes, and seed dataset.
* `02_cleaning_joins_subqueries.sql` — Data cleaning scripts, deduplication, multi-table branch performance joins, and subqueries.
* `03_advanced_sql_and_transactions.sql` — Diagnostic lab SLA CTEs, window function rankings, and ACID transaction scripts.

---

## How to Run in PostgreSQL / pgAdmin 4
1. Create a new database in PostgreSQL named `health_care`.
2. Open the **Query Tool** on `health_care` and execute `01_schema_and_seed_data.sql`.
3. Execute `02_cleaning_joins_subqueries.sql` to standardize patient records and generate branch/subquery metrics.
4. Execute `03_advanced_sql_and_transactions.sql` to run SLA analytics, window functions, and transaction tests.
