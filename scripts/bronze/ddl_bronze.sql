/*
===============================================================================
DDL SCRIPT: CREATE BRONZE LAYER TABLES
===============================================================================

Purpose:
    Creates all tables in the 'bronze' schema for raw data ingestion.

Behavior:
    - Existing tables are dropped and recreated
    - No transformations — schema mirrors source file structure
    - Designed for PostgreSQL

Layer:
    Bronze Layer (Raw Data)

Source Systems:
    - CRM System  → Customer, Product, Sales data
    - ERP System  → Customer Demographics, Locations, Product Categories

===============================================================================
*/



-- =============================================================================
-- TABLE: bronze.crm_cust_info
-- =============================================================================
-- Raw customer master data from CRM system.
-- Source: datasets/source_crm/cust_info.csv
-- =============================================================================

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



-- =============================================================================
-- TABLE: bronze.crm_prd_info
-- =============================================================================
-- Raw product catalog from CRM system.
-- Source: datasets/source_crm/prd_info.csv
-- =============================================================================

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



-- =============================================================================
-- TABLE: bronze.crm_sales_details
-- =============================================================================
-- Raw sales transactions from CRM system.
-- Source: datasets/source_crm/sales_details.csv
-- Note: Date columns stored as INT (YYYYMMDD format) per source system.
-- =============================================================================

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



-- =============================================================================
-- TABLE: bronze.erp_cust_az12
-- =============================================================================
-- Raw customer demographic data from ERP system.
-- Source: datasets/source_erp/CUST_AZ12.csv
-- Note: Customer IDs may include a 'NAS' prefix requiring downstream cleanup.
-- =============================================================================

DROP TABLE IF EXISTS bronze.erp_cust_az12;

CREATE TABLE bronze.erp_cust_az12 (
    cid         VARCHAR(50),
    bdate       DATE,
    gen         VARCHAR(50)
);



-- =============================================================================
-- TABLE: bronze.erp_loc_a101
-- =============================================================================
-- Raw customer location data from ERP system.
-- Source: datasets/source_erp/LOC_A101.csv
-- =============================================================================

DROP TABLE IF EXISTS bronze.erp_loc_a101;

CREATE TABLE bronze.erp_loc_a101 (
    cid         VARCHAR(50),
    cntry       VARCHAR(50)
);



-- =============================================================================
-- TABLE: bronze.erp_px_cat_g1v2
-- =============================================================================
-- Raw product category hierarchy from ERP system.
-- Source: datasets/source_erp/PX_CAT_G1V2.csv
-- =============================================================================

DROP TABLE IF EXISTS bronze.erp_px_cat_g1v2;

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id             VARCHAR(50),
    cat            VARCHAR(50),
    subcat         VARCHAR(50),
    maintenance    VARCHAR(50)
);
