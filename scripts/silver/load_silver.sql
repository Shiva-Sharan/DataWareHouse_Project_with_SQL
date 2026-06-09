/*
===============================================================================
STORED PROCEDURE: silver.load_silver()
===============================================================================

Purpose:
    Loads cleansed and transformed data from the Bronze layer into the
    Silver layer of the data warehouse.

Transformations Applied:
    - Data cleansing (trimming, null handling)
    - Code standardization (gender, marital status, product line)
    - Deduplication (ROW_NUMBER window function)
    - Key extraction (splitting composite product keys)
    - SCD Type 2 logic (product end date calculation)
    - Date type conversion (INT → DATE)
    - ID normalization (stripping ERP prefixes)

Source Layer:
    bronze

Target Layer:
    silver

Loading Strategy:
    Full truncate-and-reload per table

Error Handling:
    PL/pgSQL EXCEPTION block with SQLERRM for runtime error reporting.

Usage:
    CALL silver.load_silver();

===============================================================================
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$
DECLARE

    -- Per-table timing
    start_time       TIMESTAMP;
    end_time         TIMESTAMP;

    -- Batch timing
    batch_start_time TIMESTAMP;
    batch_end_time   TIMESTAMP;

BEGIN

    -- =========================================================================
    -- BATCH START
    -- =========================================================================

    batch_start_time := clock_timestamp();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer';
    RAISE NOTICE '================================================';



    -- =========================================================================
    -- SECTION 1: CRM TABLES
    -- =========================================================================

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '------------------------------------------------';



    -- =========================================================================
    -- TABLE: silver.crm_cust_info
    -- =========================================================================
    -- Transformations:
    --   • Deduplicate by cst_id, keeping latest record
    --   • Trim whitespace from name fields
    --   • Standardize marital status codes (S → Single, M → Married)
    --   • Standardize gender codes (F → Female, M → Male)
    --   • Filter out NULL customer IDs
    -- =========================================================================

    start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: silver.crm_cust_info';
    TRUNCATE TABLE silver.crm_cust_info;

    RAISE NOTICE '>> Inserting Data Into: silver.crm_cust_info';

    INSERT INTO silver.crm_cust_info
    (
        cst_id,
        cst_key,
        cst_firstname,
        cst_lastname,
        cst_martial_status,
        cst_gndr,
        cst_create_date
    )

    SELECT

        cst_id,
        cst_key,

        -- Trim leading/trailing whitespace
        TRIM(cst_firstname) AS cst_firstname,
        TRIM(cst_lastname)  AS cst_lastname,

        -- Standardize marital status codes
        CASE
            WHEN UPPER(TRIM(cst_martial_status)) = 'S'
                THEN 'Single'
            WHEN UPPER(TRIM(cst_martial_status)) = 'M'
                THEN 'Married'
            ELSE 'n/a'
        END AS cst_martial_status,

        -- Standardize gender codes
        CASE
            WHEN UPPER(TRIM(cst_gndr)) = 'F'
                THEN 'Female'
            WHEN UPPER(TRIM(cst_gndr)) = 'M'
                THEN 'Male'
            ELSE 'n/a'
        END AS cst_gndr,

        cst_create_date

    FROM
    (
        SELECT *,

            -- Deduplication: keep latest record per customer
            ROW_NUMBER() OVER
            (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS flag_last

        FROM bronze.crm_cust_info

        -- Exclude records with NULL customer IDs
        WHERE cst_id IS NOT NULL

    ) t

    WHERE flag_last = 1;

    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));



    -- =========================================================================
    -- TABLE: silver.crm_prd_info
    -- =========================================================================
    -- Transformations:
    --   • Extract category ID from composite product key (first 5 chars)
    --   • Extract clean product key (chars 7 onward)
    --   • Trim product name whitespace
    --   • Replace NULL costs with 0
    --   • Standardize product line codes (M/R/S/T → full names)
    --   • Calculate SCD Type 2 end dates using LEAD() window function
    -- =========================================================================

    start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: silver.crm_prd_info';
    TRUNCATE TABLE silver.crm_prd_info;

    RAISE NOTICE '>> Inserting Data Into: silver.crm_prd_info';

    INSERT INTO silver.crm_prd_info
    (
        prd_id,
        cat_id,
        prd_key,
        prd_nm,
        prd_cost,
        prd_line,
        prd_start_dt,
        prd_end_dt
    )

    SELECT

        prd_id,

        -- Extract category ID from composite key (e.g., 'CO-RF' → 'CO_RF')
        CAST(
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')
            AS VARCHAR(50)
        ) AS cat_id,

        -- Extract product key (e.g., 'FR-R92B-58' from position 7 onward)
        CAST(
            SUBSTRING(prd_key, 7, LENGTH(prd_key))
            AS VARCHAR(50)
        ) AS prd_key,

        -- Trim product name whitespace
        TRIM(prd_nm) AS prd_nm,

        -- Replace NULL costs with 0
        COALESCE(prd_cost, 0) AS prd_cost,

        -- Standardize product line codes
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,

        -- Cast start date to DATE
        CAST(prd_start_dt AS DATE) AS prd_start_dt,

        -- SCD Type 2: calculate end date from next version's start date
        CAST(
            LEAD(prd_start_dt) OVER (
                PARTITION BY prd_key
                ORDER BY prd_start_dt
            ) - INTERVAL '1 day'
            AS DATE
        ) AS prd_end_dt

    FROM bronze.crm_prd_info;

    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));



    -- =========================================================================
    -- TABLE: silver.crm_sales_details
    -- =========================================================================
    -- Transformations:
    --   • Convert integer dates (YYYYMMDD) to DATE type
    --   • Nullify invalid/zero date values
    --   • Correct sales amounts where sales != quantity × price
    --   • Derive price from sales/quantity when price is missing
    -- =========================================================================

    start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: silver.crm_sales_details';
    TRUNCATE TABLE silver.crm_sales_details;

    RAISE NOTICE '>> Inserting Data Into: silver.crm_sales_details';

    INSERT INTO silver.crm_sales_details
    (
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        sls_order_dt,
        sls_ship_dt,
        sls_due_dt,
        sls_sales,
        sls_quantity,
        sls_price
    )

    SELECT

        sls_ord_num,
        sls_prd_key,
        sls_cust_id,

        -- Convert integer dates to DATE (nullify zeros/invalid values)
        CASE
            WHEN sls_order_dt IS NULL OR sls_order_dt = 0 THEN NULL
            ELSE TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD')
        END AS sls_order_dt,

        CASE
            WHEN sls_ship_dt IS NULL OR sls_ship_dt = 0 THEN NULL
            ELSE TO_DATE(sls_ship_dt::TEXT, 'YYYYMMDD')
        END AS sls_ship_dt,

        CASE
            WHEN sls_due_dt IS NULL OR sls_due_dt = 0 THEN NULL
            ELSE TO_DATE(sls_due_dt::TEXT, 'YYYYMMDD')
        END AS sls_due_dt,

        -- Correct sales amount if inconsistent with quantity × price
        CASE
            WHEN sls_sales IS NULL
                OR sls_sales <= 0
                OR sls_sales != sls_quantity * ABS(sls_price)
            THEN sls_quantity * ABS(sls_price)
            ELSE sls_sales
        END AS sls_sales,

        sls_quantity,

        -- Derive price from sales/quantity when price is missing or invalid
        CASE
            WHEN sls_price IS NULL OR sls_price <= 0
            THEN sls_sales / NULLIF(sls_quantity, 0)
            ELSE sls_price
        END AS sls_price

    FROM bronze.crm_sales_details;

    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));



    -- =========================================================================
    -- SECTION 2: ERP TABLES
    -- =========================================================================

    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading ERP Tables';
    RAISE NOTICE '------------------------------------------------';



    -- =========================================================================
    -- TABLE: silver.erp_cust_az12
    -- =========================================================================
    -- Transformations:
    --   • Strip 'NAS' prefix from customer IDs for CRM key matching
    --   • Nullify future birth dates (data quality correction)
    --   • Standardize gender values to match CRM conventions
    -- =========================================================================

    start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: silver.erp_cust_az12';
    TRUNCATE TABLE silver.erp_cust_az12;

    RAISE NOTICE '>> Inserting Data Into: silver.erp_cust_az12';

    INSERT INTO silver.erp_cust_az12
    (
        cid,
        bdate,
        gen
    )

    SELECT

        -- Strip 'NAS' prefix for cross-system key alignment
        CASE
            WHEN cid LIKE 'NAS%'
            THEN SUBSTRING(cid, 4, LENGTH(cid))
            ELSE cid
        END AS cid,

        -- Nullify future birth dates
        CASE
            WHEN bdate > CURRENT_DATE THEN NULL
            ELSE bdate
        END AS bdate,

        -- Standardize gender values
        CASE
            WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE')  THEN 'Female'
            WHEN UPPER(TRIM(gen)) IN ('M', 'MALE')    THEN 'Male'
            ELSE 'n/a'
        END AS gen

    FROM bronze.erp_cust_az12;

    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));



    -- =========================================================================
    -- TABLE: silver.erp_loc_a101
    -- =========================================================================
    -- Transformations:
    --   • Strip 'NAS' prefix from customer IDs
    --   • Trim country name whitespace
    --   • Standardize common country name variations
    -- =========================================================================

    start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: silver.erp_loc_a101';
    TRUNCATE TABLE silver.erp_loc_a101;

    RAISE NOTICE '>> Inserting Data Into: silver.erp_loc_a101';

    INSERT INTO silver.erp_loc_a101
    (
        cid,
        cntry
    )

    SELECT

        -- Strip 'NAS' prefix for cross-system key alignment
        CASE
            WHEN cid LIKE 'NAS%'
            THEN SUBSTRING(cid, 4, LENGTH(cid))
            ELSE cid
        END AS cid,

        -- Trim and standardize country names
        CASE
            WHEN TRIM(cntry) = 'DE' THEN 'Germany'
            WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
            WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
            ELSE TRIM(cntry)
        END AS cntry

    FROM bronze.erp_loc_a101;

    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));



    -- =========================================================================
    -- TABLE: silver.erp_px_cat_g1v2
    -- =========================================================================
    -- Transformations:
    --   • Trim whitespace from category, subcategory, and maintenance fields
    -- =========================================================================

    start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: silver.erp_px_cat_g1v2';
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    RAISE NOTICE '>> Inserting Data Into: silver.erp_px_cat_g1v2';

    INSERT INTO silver.erp_px_cat_g1v2
    (
        id,
        cat,
        subcat,
        maintenance
    )

    SELECT

        id,
        TRIM(cat)         AS cat,
        TRIM(subcat)      AS subcat,
        TRIM(maintenance) AS maintenance

    FROM bronze.erp_px_cat_g1v2;

    end_time := clock_timestamp();
    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));



    -- =========================================================================
    -- BATCH COMPLETE
    -- =========================================================================

    batch_end_time := clock_timestamp();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Silver Layer Completed';
    RAISE NOTICE '>> Total Load Duration: % seconds',
        EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
    RAISE NOTICE '================================================';



EXCEPTION

    WHEN OTHERS THEN

        RAISE NOTICE '================================================';
        RAISE NOTICE 'ERROR OCCURRED DURING LOADING SILVER LAYER';
        RAISE NOTICE 'Error Message: %', SQLERRM;
        RAISE NOTICE '================================================';

END;
$$;

-- Execute the procedure
CALL silver.load_silver();
