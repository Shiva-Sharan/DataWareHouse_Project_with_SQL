/*
===============================================================================
Stored Procedure: silver.load_silver
===============================================================================
Purpose:
    This procedure loads cleaned and transformed data from the Bronze layer
    into the Silver layer.

Description:
    - Performs data cleansing
    - Standardizes values
    - Removes duplicates
    - Handles missing/null values
    - Validates business rules
    - Applies transformation logic
    - Tracks execution duration using logging

Source Layer:
    bronze

Target Layer:
    silver

Execution:
    CALL silver.load_silver();

===============================================================================
*/


CREATE OR REPLACE PROCEDURE silver.load_silver()

LANGUAGE plpgsql

AS $$

DECLARE

    -- Variables for table load duration tracking
    start_time TIMESTAMP;
    end_time TIMESTAMP;

    -- Variables for total batch execution tracking
    batch_start_time TIMESTAMP;
    batch_end_time TIMESTAMP;

BEGIN

    /*
    ===========================================================================
    BATCH START
    ===========================================================================
    */

    batch_start_time := clock_timestamp();

    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Loading Silver Layer';
    RAISE NOTICE '==========================================';



    /*
    ===========================================================================
    SECTION 1: CRM TABLES
    ===========================================================================
    */

    RAISE NOTICE '------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '------------------------------------------';



    /*
    ===========================================================================
    TABLE: silver.crm_cust_info
    ===========================================================================
    Purpose:
        Load and clean customer information.

    Transformations Applied:
        - Remove duplicate customers
        - Keep latest customer record
        - Trim unwanted spaces
        - Standardize marital status values
        - Standardize gender values
        - Filter NULL customer IDs
    ===========================================================================
    */

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

        -- Data Cleansing: Remove leading/trailing spaces
        TRIM(cst_firstname) AS cst_firstname,

        -- Data Cleansing: Remove leading/trailing spaces
        TRIM(cst_lastname) AS cst_lastname,

        -- Data Standardization: Convert marital codes into readable values
        CASE
            WHEN UPPER(TRIM(cst_martial_status)) = 'S'
                THEN 'Single'

            WHEN UPPER(TRIM(cst_martial_status)) = 'M'
                THEN 'Married'

            ELSE 'n/a'
        END AS cst_martial_status,

        -- Data Standardization: Convert gender codes into readable values
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

            -- Deduplication:
            -- Keep latest record per customer
            ROW_NUMBER() OVER
            (
                PARTITION BY cst_id
                ORDER BY cst_create_date DESC
            ) AS flag_last

        FROM bronze.crm_cust_info

        -- Data Filtering:
        -- Remove records with NULL customer IDs
        WHERE cst_id IS NOT NULL

    ) t

    WHERE flag_last = 1;

    end_time := clock_timestamp();

    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));



    /*
    ===========================================================================
    TABLE: silver.crm_prd_info
    ===========================================================================
    Purpose:
        Load and transform product information.

    Transformations Applied:
        - Extract category ID from product key
        - Extract product key
        - Standardize product line values
        - Replace NULL costs with 0
        - Calculate product end dates
        - Trim unwanted spaces
    ===========================================================================
    */

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

        -- Data Transformation:
        -- Extract category ID from product key
        CAST(
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')
            AS VARCHAR(50)
        ) AS cat_id,

        -- Data Transformation:
        -- Extract actual product key
        CAST(
            SUBSTRING(prd_key, 7, LENGTH(prd_key))
            AS VARCHAR(50)
        ) AS prd_key,

        -- Data Cleansing
        TRIM(prd_nm) AS prd_nm,

        -- Missing Value Handling
        COALESCE(prd_cost, 0) AS prd_cost,

        -- Data Standardization
        CASE UPPER(TRIM(prd_line))

            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'

            ELSE 'n/a'

        END AS prd_line,

        CAST(prd_start_dt AS DATE) AS prd_start_dt,

        -- SCD Logic:
        -- Calculate product end date
        COALESCE
        (
            CAST
            (
                LEAD(prd_start_dt) OVER
                (
                    PARTITION BY prd_key
                    ORDER BY prd_start_dt
                ) - INTERVAL '1 day'

                AS DATE
            ),

            prd_end_dt

        ) AS prd_end_dt

    FROM bronze.crm_prd_info;

    end_time := clock_timestamp();

    RAISE NOTICE 'Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));



    /*
    ===========================================================================
    ADD SAME STRUCTURE FOR:
        - crm_sales_details
        - erp_cust_az12
        - erp_loc_a101
        - erp_px_cat_g1v2
    ===========================================================================
    */



    /*
    ===========================================================================
    BATCH COMPLETE
    ===========================================================================
    */

    batch_end_time := clock_timestamp();

    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Loading Silver Layer Completed';
    RAISE NOTICE 'Total Load Duration: % seconds',
        EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
    RAISE NOTICE '==========================================';



EXCEPTION

    WHEN OTHERS THEN

        RAISE NOTICE '==========================================';
        RAISE NOTICE 'ERROR OCCURRED DURING LOADING SILVER LAYER';
        RAISE NOTICE 'Error Message: %', SQLERRM;
        RAISE NOTICE '==========================================';

END;
$$;



CALL silver.load_silver();
