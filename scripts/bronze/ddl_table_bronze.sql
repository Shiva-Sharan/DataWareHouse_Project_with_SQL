
/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema.

    Existing tables are dropped and recreated before execution.

Layer:
    Bronze Layer (Raw Data Layer)

Source Systems:
    CRM System
    ERP System

Notes:
    - Bronze layer stores raw/unprocessed data
    - Designed for PostgreSQL
===============================================================================
*/



/*
===============================================================================
Table: bronze.crm_cust_info
===============================================================================
Description:
    Stores customer information extracted from CRM system.
===============================================================================
*/

DROP TABLE IF EXISTS bronze.crm_cust_info;

CREATE TABLE bronze.crm_cust_info (
    cst_id              INT,
    cst_key             VARCHAR(50),
    cst_firstname       VARCHAR(50),
    cst_lastname        VARCHAR(50),
    cst_martial_status  VARCHAR(50),
    cst_gndr            VARCHAR(50),
    cst_create_date     DATE
);



/*
===============================================================================
Table: bronze.crm_prd_info
===============================================================================
Description:
    Stores product information extracted from CRM system.
===============================================================================
*/

DROP TABLE IF EXISTS bronze.crm_prd_info;

CREATE TABLE bronze.crm_prd_info (
    prd_id         INT,
    prd_key        VARCHAR(50),
    prd_nm         VARCHAR(50),
    prd_cost       INT,
    prd_line       VARCHAR(50),
    prd_start_dt   TIMESTAMP,
    prd_end_dt     TIMESTAMP
);



/*
===============================================================================
Table: bronze.crm_sales_details
===============================================================================
Description:
    Stores sales transaction details extracted from CRM system.
===============================================================================
*/

DROP TABLE IF EXISTS bronze.crm_sales_details;

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num    VARCHAR(50),
    sls_prd_key    VARCHAR(50),
    sls_cust_id    INT,
    sls_order_dt   INT,
    sls_ship_dt    INT,
    sls_due_dt     INT,
    sls_sales      INT,
    sls_quantity   INT,
    sls_price      INT
);



/*
===============================================================================
Table: bronze.erp_loc_a101
===============================================================================
Description:
    Stores customer location information extracted from ERP system.
===============================================================================
*/

DROP TABLE IF EXISTS bronze.erp_loc_a101;

CREATE TABLE bronze.erp_loc_a101 (
    cid         VARCHAR(50),
    cntry       VARCHAR(50)
);



/*
===============================================================================
Table: bronze.erp_cust_az12
===============================================================================
Description:
    Stores customer demographic information extracted from ERP system.
===============================================================================
*/

DROP TABLE IF EXISTS bronze.erp_cust_az12;

CREATE TABLE bronze.erp_cust_az12 (
    cid         VARCHAR(50),
    bdate       DATE,
    gen         VARCHAR(50)
);



/*
===============================================================================
Table: bronze.erp_px_cat_g1v2
===============================================================================
Description:
    Stores product category information extracted from ERP system.
===============================================================================
*/

DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id             VARCHAR(50),
    cat            VARCHAR(50),
    subcat         VARCHAR(50),
    maintenance    VARCHAR(50)
);
