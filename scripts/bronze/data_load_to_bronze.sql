/*
===============================================================================
Stored Procedure: bronze.load_bronze
===============================================================================

Purpose:
--------
This stored procedure loads raw CSV data from external source files into
the Bronze layer tables of the data warehouse.

Process Flow:
-------------
1. Truncate existing data from Bronze tables
2. Load fresh data from CSV files using COPY
3. Track table-level load durations
4. Track total batch execution duration
5. Handle and display runtime errors

Source Systems:
---------------
- CRM System
- ERP System

Target Schema:
--------------
bronze

Loading Method:
---------------
COPY command

Error Handling:
---------------
Uses PostgreSQL EXCEPTION block with SQLERRM for runtime error messages.

Execution:
----------
CALL bronze.load_bronze();

===============================================================================
*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    batch_start_time TIMESTAMP;
    batch_end_time TIMESTAMP;
BEGIN

    batch_start_time := clock_timestamp();

    RAISE NOTICE '================================================';
    RAISE NOTICE 'Loading Bronze Layer';
    RAISE NOTICE '================================================';



    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading CRM Tables';
    RAISE NOTICE '------------------------------------------------';



    start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: bronze.crm_cust_info';

    TRUNCATE TABLE bronze.crm_cust_info;

    RAISE NOTICE '>> Inserting Data Into: bronze.crm_cust_info';

    COPY bronze.crm_cust_info
    FROM 'D:/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
    DELIMITER ','
    CSV HEADER
    NULL '';

    end_time := clock_timestamp();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> -------------';



    start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: bronze.crm_prd_info';

    TRUNCATE TABLE bronze.crm_prd_info;

    RAISE NOTICE '>> Inserting Data Into: bronze.crm_prd_info';

    COPY bronze.crm_prd_info
    FROM 'D:/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
    DELIMITER ','
    CSV HEADER
    NULL '';

    end_time := clock_timestamp();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> -------------';



    start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: bronze.crm_sales_details';

    TRUNCATE TABLE bronze.crm_sales_details;

    RAISE NOTICE '>> Inserting Data Into: bronze.crm_sales_details';

    COPY bronze.crm_sales_details
    FROM 'D:/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
    DELIMITER ','
    CSV HEADER
    NULL '';

    end_time := clock_timestamp();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> -------------';



    RAISE NOTICE '------------------------------------------------';
    RAISE NOTICE 'Loading ERP Tables';
    RAISE NOTICE '------------------------------------------------';



    start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: bronze.erp_loc_a101';

    TRUNCATE TABLE bronze.erp_loc_a101;

    RAISE NOTICE '>> Inserting Data Into: bronze.erp_loc_a101';

    COPY bronze.erp_loc_a101
    FROM 'D:/sql-data-warehouse-project/datasets/source_erp/LOC_A101.csv'
    DELIMITER ','
    CSV HEADER
    NULL '';

    end_time := clock_timestamp();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> -------------';



    start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: bronze.erp_cust_az12';

    TRUNCATE TABLE bronze.erp_cust_az12;

    RAISE NOTICE '>> Inserting Data Into: bronze.erp_cust_az12';

    COPY bronze.erp_cust_az12
    FROM 'D:/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv'
    DELIMITER ','
    CSV HEADER
    NULL '';

    end_time := clock_timestamp();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> -------------';



    start_time := clock_timestamp();

    RAISE NOTICE '>> Truncating Table: bronze.erp_px_cat_g1v2';

    TRUNCATE TABLE bronze.erp_px_cat_g1v2;

    RAISE NOTICE '>> Inserting Data Into: bronze.erp_px_cat_g1v2';

    COPY bronze.erp_px_cat_g1v2
    FROM 'D:/sql-data-warehouse-project/datasets/source_erp/PX_CAT_G1V2.csv'
    DELIMITER ','
    CSV HEADER
    NULL '';

    end_time := clock_timestamp();

    RAISE NOTICE '>> Load Duration: % seconds',
        EXTRACT(EPOCH FROM (end_time - start_time));

    RAISE NOTICE '>> -------------';



    batch_end_time := clock_timestamp();

    RAISE NOTICE '==========================================';
    RAISE NOTICE 'Loading Bronze Layer is Completed';

    RAISE NOTICE '>> Total Load Duration: % seconds',
        EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));

    RAISE NOTICE '==========================================';



EXCEPTION
    WHEN OTHERS THEN

        RAISE NOTICE '==========================================';
        RAISE NOTICE 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        RAISE NOTICE 'Error Message: %', SQLERRM;
        RAISE NOTICE '==========================================';

END;
$$;

CALL bronze.load_bronze();
