/*
===============================================================================
BRONZE LAYER DATA QUALITY CHECKS
===============================================================================

Purpose:
    Validate and analyze raw Bronze layer data before loading into
    the Silver layer.

Checks Included:
    - Duplicate detection
    - NULL validation
    - Whitespace validation
    - Data standardization checks
    - Invalid date validation
    - Business rule validation
    - Data consistency checks
    - Referential integrity checks

===============================================================================
*/



/*
===============================================================================
CRM CUSTOMER INFO VALIDATION
===============================================================================
*/


/*
------------------------------------------------------------------------------
Check 1: Duplicate or NULL Customer IDs
Transformation Type:
    - Duplicate Detection
    - NULL Validation
------------------------------------------------------------------------------
*/

SELECT
    cst_id,
    COUNT(*)

FROM bronze.crm_cust_info

GROUP BY cst_id

HAVING COUNT(*) > 1
    OR cst_id IS NULL;



/*
------------------------------------------------------------------------------
Check 2: First Name Whitespace Issues
Transformation Type:
    - Data Cleansing Validation
------------------------------------------------------------------------------
*/

SELECT
    *,
    LENGTH(cst_firstname),
    LENGTH(TRIM(cst_firstname))

FROM bronze.crm_cust_info

WHERE cst_firstname != TRIM(cst_firstname);



/*
------------------------------------------------------------------------------
Check 3: Last Name Whitespace Issues
Transformation Type:
    - Data Cleansing Validation
------------------------------------------------------------------------------
*/

SELECT
    *,
    LENGTH(cst_lastname),
    LENGTH(TRIM(cst_lastname))

FROM bronze.crm_cust_info

WHERE cst_lastname != TRIM(cst_lastname);



/*
------------------------------------------------------------------------------
Check 4: Distinct Marital Status Values
Transformation Type:
    - Data Standardization Validation
------------------------------------------------------------------------------
*/

SELECT DISTINCT
    cst_martial_status

FROM bronze.crm_cust_info;





/*
===============================================================================
CRM PRODUCT INFO VALIDATION
===============================================================================
*/


/*
------------------------------------------------------------------------------
Check 5: Duplicate or NULL Product IDs
Transformation Type:
    - Duplicate Detection
    - NULL Validation
------------------------------------------------------------------------------
*/

SELECT
    prd_id,
    COUNT(*)

FROM bronze.crm_prd_info

GROUP BY prd_id

HAVING COUNT(*) > 1
    OR prd_id IS NULL;



/*
------------------------------------------------------------------------------
Check 6: Product Name Whitespace Issues
Transformation Type:
    - Data Cleansing Validation
------------------------------------------------------------------------------
*/

SELECT
    prd_nm

FROM bronze.crm_prd_info

WHERE prd_nm != TRIM(prd_nm);



/*
------------------------------------------------------------------------------
Check 7: Negative or NULL Product Cost
Transformation Type:
    - Missing Value Validation
    - Business Rule Validation
------------------------------------------------------------------------------
*/

SELECT
    COALESCE(prd_cost, 0)

FROM bronze.crm_prd_info

WHERE prd_cost < 0
    OR prd_cost IS NULL;



/*
------------------------------------------------------------------------------
Check 8: Distinct Product Line Codes
Transformation Type:
    - Data Standardization Validation
------------------------------------------------------------------------------
*/

SELECT DISTINCT
    prd_line

FROM bronze.crm_prd_info;



/*
------------------------------------------------------------------------------
Check 9: Invalid Product Date Ranges
Transformation Type:
    - Date Validation
    - Business Rule Validation
------------------------------------------------------------------------------
*/

SELECT *

FROM bronze.crm_prd_info

WHERE prd_end_dt < prd_start_dt
    OR prd_end_dt IS NULL
    OR prd_start_dt IS NULL;



/*
------------------------------------------------------------------------------
Check 10: Product End Date Calculation Validation
Transformation Type:
    - SCD (Slowly Changing Dimension) Validation
------------------------------------------------------------------------------
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

FROM bronze.crm_prd_info;





/*
===============================================================================
CRM SALES DETAILS VALIDATION
===============================================================================
*/


/*
------------------------------------------------------------------------------
Check 11: Invalid Order Dates
Transformation Type:
    - Date Validation
------------------------------------------------------------------------------
*/

SELECT
    NULLIF(sls_order_dt, 0) AS sls_order_dt

FROM bronze.crm_sales_details

WHERE sls_order_dt <= 0
    OR CHAR_LENGTH(sls_order_dt::TEXT) != 8
    OR sls_order_dt > 20500101
    OR sls_order_dt < 19000101;



/*
------------------------------------------------------------------------------
Check 12: Invalid Shipping Dates
Transformation Type:
    - Date Validation
------------------------------------------------------------------------------
*/

SELECT
    NULLIF(sls_ship_dt, 0) AS sls_ship_dt

FROM bronze.crm_sales_details

WHERE sls_ship_dt <= 0
    OR CHAR_LENGTH(sls_ship_dt::TEXT) != 8
    OR sls_ship_dt > 20500101
    OR sls_ship_dt < 19000101;



/*
------------------------------------------------------------------------------
Check 13: Invalid Due Dates
Transformation Type:
    - Date Validation
------------------------------------------------------------------------------
*/

SELECT
    NULLIF(sls_due_dt, 0) AS sls_due_dt

FROM bronze.crm_sales_details

WHERE sls_due_dt <= 0
    OR CHAR_LENGTH(sls_due_dt::TEXT) != 8
    OR sls_due_dt > 20500101
    OR sls_due_dt < 19000101;



/*
------------------------------------------------------------------------------
Check 14: Invalid Sales Date Relationships
Transformation Type:
    - Business Rule Validation
------------------------------------------------------------------------------
*/

SELECT *

FROM bronze.crm_sales_details

WHERE sls_ship_dt < sls_order_dt
    OR sls_order_dt > sls_due_dt;



/*
------------------------------------------------------------------------------
Check 15: Invalid Sales Amount Calculations
Transformation Type:
    - Business Rule Validation
    - Data Consistency Validation
------------------------------------------------------------------------------
*/

SELECT

    sls_sales,
    sls_quantity,
    sls_price

FROM bronze.crm_sales_details

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
------------------------------------------------------------------------------
Check 16: Sales Correction Logic Validation
Transformation Type:
    - Data Correction Validation
------------------------------------------------------------------------------
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

FROM bronze.crm_sales_details

WHERE sls_sales != sls_quantity * sls_price
    OR sls_sales IS NULL
    OR sls_quantity IS NULL
    OR sls_price IS NULL
    OR sls_sales <= 0
    OR sls_quantity <= 0
    OR sls_price <= 0;





/*
===============================================================================
ERP CUSTOMER VALIDATION
===============================================================================
*/


/*
------------------------------------------------------------------------------
Check 17: Customer ID Mapping Validation
Transformation Type:
    - Referential Integrity Validation
------------------------------------------------------------------------------
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

    FROM bronze.erp_cust_az12

) t

WHERE cid NOT IN
(
    SELECT cst_key
    FROM silver.crm_cust_info
);



/*
------------------------------------------------------------------------------
Check 18: Invalid Future Birth Dates
Transformation Type:
    - Date Validation
------------------------------------------------------------------------------
*/

SELECT DISTINCT
    bdate

FROM bronze.erp_cust_az12

WHERE bdate > CURRENT_DATE;





/*
===============================================================================
ERP PRODUCT CATEGORY VALIDATION
===============================================================================
*/


/*
------------------------------------------------------------------------------
Check 19: Category Table Whitespace Issues
Transformation Type:
    - Data Cleansing Validation
------------------------------------------------------------------------------
*/

SELECT *

FROM bronze.erp_px_cat_g1v2

WHERE cat != TRIM(cat)
    OR subcat != TRIM(subcat)
    OR maintenance != TRIM(maintenance);



/*
------------------------------------------------------------------------------
Check 20: Distinct Maintenance Values
Transformation Type:
    - Data Standardization Validation
------------------------------------------------------------------------------
*/

SELECT DISTINCT
    maintenance
FROM bronze.erp_px_cat_g1v2;
