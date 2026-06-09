/*
===============================================================================
GOLD LAYER DATA QUALITY CHECKS
===============================================================================

Purpose:
    Validate the business-ready Gold layer views for:
    - Surrogate key uniqueness in dimension tables
    - Referential integrity between fact and dimension tables
    - Data domain validation

Usage:
    Run each query individually to inspect results.
    A successful check returns zero rows (unless noted otherwise).

===============================================================================
*/



/*
-------------------------------------------------------------------------------
Check 1: Inspect Customer Dimension
Type: Visual Inspection
Purpose: Review sample data from dim_customers for correctness
-------------------------------------------------------------------------------
*/

SELECT * FROM gold.dim_customers;



/*
-------------------------------------------------------------------------------
Check 2: Valid Gender Values in Customer Dimension
Type: Data Standardization Validation
Expected: Only 'Male', 'Female', 'n/a'
-------------------------------------------------------------------------------
*/

SELECT DISTINCT
    gender

FROM gold.dim_customers;



/*
-------------------------------------------------------------------------------
Check 3: Customer Dimension — Duplicate Surrogate Keys
Type: Primary Key Uniqueness Validation
Expected: 0 rows (each customer_id should appear exactly once)
-------------------------------------------------------------------------------
*/

SELECT
    customer_id,
    COUNT(*)

FROM gold.dim_customers

GROUP BY customer_id

HAVING COUNT(*) > 1;



/*
-------------------------------------------------------------------------------
Check 4: Product Dimension — Duplicate Surrogate Keys
Type: Primary Key Uniqueness Validation
Expected: 0 rows (each product_id should appear exactly once)
-------------------------------------------------------------------------------
*/

SELECT
    product_id,
    COUNT(*)

FROM gold.dim_products

GROUP BY product_id

HAVING COUNT(*) > 1;



/*
-------------------------------------------------------------------------------
Check 5: Fact-to-Dimension Referential Integrity
Type: Referential Integrity Validation
Expected: 0 rows (no orphan records in fact_sales)
Purpose: Ensure every fact record joins to both dimension tables
-------------------------------------------------------------------------------
*/

SELECT *

FROM gold.fact_sales f

LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key

LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key

WHERE c.customer_key IS NULL
    OR p.product_key IS NULL;
