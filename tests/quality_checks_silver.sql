/*
===============================================================================
SILVER LAYER DATA QUALITY CHECKS
===============================================================================

Purpose:
    Validate and analyze cleansed Silver layer data after transformation
    from the Bronze layer.

Checks Included:
    - Duplicate detection
    - NULL validation
    - Whitespace validation
    - Data standardization checks
    - Invalid date validation
    - Business rule validation
    - Data consistency checks
    - Referential integrity checks

Usage:
    Run each query individually to inspect results.
    A successful check returns zero rows.

===============================================================================
*/



/*
===============================================================================
SECTION 1: CRM CUSTOMER INFO VALIDATION
===============================================================================
*/


/*
-------------------------------------------------------------------------------
Check 1: Duplicate or NULL Customer IDs
Type: Duplicate Detection, NULL Validation
Expected: 0 rows (no duplicates, no NULLs)
-------------------------------------------------------------------------------
*/

SELECT
    cst_id,
    COUNT(*)

FROM silver.crm_cust_info

GROUP BY cst_id

HAVING COUNT(*) > 1
    OR cst_id IS NULL;



/*
-------------------------------------------------------------------------------
Check 2: First Name Whitespace Issues
Type: Data Cleansing Validation
Expected: 0 rows (all names are trimmed)
-------------------------------------------------------------------------------
*/

SELECT
    *,
    LENGTH(cst_firstname),
    LENGTH(TRIM(cst_firstname))

FROM silver.crm_cust_info

WHERE cst_firstname != TRIM(cst_firstname);



/*
-------------------------------------------------------------------------------
Check 3: Last Name Whitespace Issues
Type: Data Cleansing Validation
Expected: 0 rows (all names are trimmed)
-------------------------------------------------------------------------------
*/

SELECT
    *,
    LENGTH(cst_lastname),
    LENGTH(TRIM(cst_lastname))

FROM silver.crm_cust_info

WHERE cst_lastname != TRIM(cst_lastname);



/*
-------------------------------------------------------------------------------
Check 4: Distinct Marital Status Values
Type: Data Standardization Validation
Expected: Only 'Single', 'Married', 'n/a'
-------------------------------------------------------------------------------
*/

SELECT DISTINCT
    cst_martial_status

FROM silver.crm_cust_info;



/*
===============================================================================
SECTION 2: CRM PRODUCT INFO VALIDATION
===============================================================================
*/


/*
-------------------------------------------------------------------------------
Check 5: Duplicate or NULL Product IDs
Type: Duplicate Detection, NULL Validation
Expected: 0 rows
-------------------------------------------------------------------------------
*/

SELECT
    prd_id,
    COUNT(*)

FROM silver.crm_prd_info

GROUP BY prd_id

HAVING COUNT(*) > 1
    OR prd_id IS NULL;



/*
-------------------------------------------------------------------------------
Check 6: Product Name Whitespace Issues
Type: Data Cleansing Validation
Expected: 0 rows
-------------------------------------------------------------------------------
*/

SELECT
    prd_nm

FROM silver.crm_prd_info

WHERE prd_nm != TRIM(prd_nm);



/*
-------------------------------------------------------------------------------
Check 7: Negative or NULL Product Cost
Type: Missing Value Validation, Business Rule Validation
Expected: 0 rows (costs should be >= 0 after COALESCE)
-------------------------------------------------------------------------------
*/

SELECT
    COALESCE(prd_cost, 0)

FROM silver.crm_prd_info

WHERE prd_cost < 0
    OR prd_cost IS NULL;



/*
-------------------------------------------------------------------------------
Check 8: Distinct Product Line Values
Type: Data Standardization Validation
Expected: Only 'Mountain', 'Road', 'Other Sales', 'Touring', 'n/a'
-------------------------------------------------------------------------------
*/

SELECT DISTINCT
    prd_line

FROM silver.crm_prd_info;



/*
-------------------------------------------------------------------------------
Check 9: Invalid Product Date Ranges
Type: Date Validation, Business Rule Validation
Expected: 0 rows (end date should not precede start date)
-------------------------------------------------------------------------------
*/

SELECT *

FROM silver.crm_prd_info

WHERE prd_end_dt < prd_start_dt
    OR prd_end_dt IS NULL
    OR prd_start_dt IS NULL;



/*
-------------------------------------------------------------------------------
Check 10: Product End Date Calculation Validation
Type: SCD (Slowly Changing Dimension) Validation
Purpose: Verify that prd_end_dt matches the LEAD()-calculated value
-------------------------------------------------------------------------------
*/

SELECT

    prd_id,
    prd_key,
    prd_nm,
    prd_start_dt,

    LEAD(prd_start_dt)
    OVER
    (
        PARTITION BY prd_key
        ORDER BY prd_start_dt
    ) - INTERVAL '1 day' AS calculated_prd_end_dt,

    prd_end_dt

FROM silver.crm_prd_info;



/*
===============================================================================
SECTION 3: CRM SALES DETAILS VALIDATION
===============================================================================
*/


/*
-------------------------------------------------------------------------------
Check 11: Invalid Order Dates
Type: Date Validation
Expected: 0 rows
-------------------------------------------------------------------------------
*/

SELECT
    NULLIF(sls_order_dt, 0) AS sls_order_dt

FROM silver.crm_sales_details

WHERE sls_order_dt <= 0
    OR CHAR_LENGTH(sls_order_dt::TEXT) != 8
    OR sls_order_dt > 20500101
    OR sls_order_dt < 19000101;



/*
-------------------------------------------------------------------------------
Check 12: Invalid Shipping Dates
Type: Date Validation
Expected: 0 rows
-------------------------------------------------------------------------------
*/

SELECT
    NULLIF(sls_ship_dt, 0) AS sls_ship_dt

FROM silver.crm_sales_details

WHERE sls_ship_dt <= 0
    OR CHAR_LENGTH(sls_ship_dt::TEXT) != 8
    OR sls_ship_dt > 20500101
    OR sls_ship_dt < 19000101;



/*
-------------------------------------------------------------------------------
Check 13: Invalid Due Dates
Type: Date Validation
Expected: 0 rows
-------------------------------------------------------------------------------
*/

SELECT
    NULLIF(sls_due_dt, 0) AS sls_due_dt

FROM silver.crm_sales_details

WHERE sls_due_dt <= 0
    OR CHAR_LENGTH(sls_due_dt::TEXT) != 8
    OR sls_due_dt > 20500101
    OR sls_due_dt < 19000101;



/*
-------------------------------------------------------------------------------
Check 14: Invalid Sales Date Relationships
Type: Business Rule Validation
Expected: 0 rows (ship_date >= order_date, order_date <= due_date)
-------------------------------------------------------------------------------
*/

SELECT *

FROM silver.crm_sales_details

WHERE sls_ship_dt < sls_order_dt
    OR sls_order_dt > sls_due_dt;



/*
-------------------------------------------------------------------------------
Check 15: Invalid Sales Amount Calculations
Type: Business Rule Validation, Data Consistency Validation
Expected: 0 rows (sales = quantity × price, all values > 0)
-------------------------------------------------------------------------------
*/

SELECT

    sls_sales,
    sls_quantity,
    sls_price

FROM silver.crm_sales_details

WHERE sls_sales != sls_quantity * sls_price
    OR sls_sales IS NULL
    OR sls_quantity IS NULL
    OR sls_price IS NULL
    OR sls_sales <= 0
    OR sls_quantity <= 0
    OR sls_price <= 0

ORDER BY
    sls_sales,
    sls_quantity,
    sls_price;



/*
-------------------------------------------------------------------------------
Check 16: Sales Correction Logic Validation
Type: Data Correction Validation
Purpose: Preview the corrected values applied during Silver transformation
-------------------------------------------------------------------------------
*/

SELECT

    sls_sales AS old_sales,
    sls_quantity,
    sls_price AS old_price,

    CASE
        WHEN sls_sales IS NULL
            OR sls_sales <= 0
            OR sls_sales != sls_quantity * ABS(sls_price)

        THEN sls_quantity * ABS(sls_price)

        ELSE sls_sales
    END AS corrected_sales,

    CASE
        WHEN sls_price IS NULL
            OR sls_price <= 0

        THEN sls_sales / NULLIF(sls_quantity, 0)

        ELSE sls_price
    END AS corrected_price

FROM silver.crm_sales_details

WHERE sls_sales != sls_quantity * sls_price
    OR sls_sales IS NULL
    OR sls_quantity IS NULL
    OR sls_price IS NULL
    OR sls_sales <= 0
    OR sls_quantity <= 0
    OR sls_price <= 0;



/*
===============================================================================
SECTION 4: ERP CUSTOMER VALIDATION
===============================================================================
*/


/*
-------------------------------------------------------------------------------
Check 17: Customer ID Mapping Validation
Type: Referential Integrity Validation
Expected: 0 rows (all ERP customers map to a CRM customer)
-------------------------------------------------------------------------------
*/

SELECT *

FROM
(
    SELECT

        CASE
            WHEN cid LIKE 'NAS%'
            THEN SUBSTRING(cid, 4, LENGTH(cid))

            ELSE cid
        END AS cid,

        bdate,
        gen

    FROM silver.erp_cust_az12

) t

WHERE cid NOT IN
(
    SELECT cst_key
    FROM silver.crm_cust_info
);



/*
-------------------------------------------------------------------------------
Check 18: Invalid Future Birth Dates
Type: Date Validation
Expected: 0 rows (no birth dates in the future)
-------------------------------------------------------------------------------
*/

SELECT DISTINCT
    bdate

FROM silver.erp_cust_az12

WHERE bdate > CURRENT_DATE;



/*
===============================================================================
SECTION 5: ERP PRODUCT CATEGORY VALIDATION
===============================================================================
*/


/*
-------------------------------------------------------------------------------
Check 19: Category Table Whitespace Issues
Type: Data Cleansing Validation
Expected: 0 rows (all fields are trimmed)
-------------------------------------------------------------------------------
*/

SELECT *

FROM silver.erp_px_cat_g1v2

WHERE cat != TRIM(cat)
    OR subcat != TRIM(subcat)
    OR maintenance != TRIM(maintenance);



/*
-------------------------------------------------------------------------------
Check 20: Distinct Maintenance Values
Type: Data Standardization Validation
Expected: Only 'Yes', 'No' (or 'n/a')
-------------------------------------------------------------------------------
*/

SELECT DISTINCT
    maintenance

FROM silver.erp_px_cat_g1v2;
