/*
===============================================================================
DDL SCRIPT: CREATE SILVER LAYER TABLES
===============================================================================

Purpose:
    Creates all tables in the 'silver' schema for cleansed and
    standardized data.

Behavior:
    - Existing tables are dropped and recreated
    - All tables include an audit column: dwh_create_date
    - Designed for PostgreSQL

Layer:
    Silver Layer (Cleansed Data)

Description:
    The Silver layer stores data that has been cleansed, deduplicated,
    and standardized from the Bronze layer, ready for integration into
    the Gold layer dimensional model.

Source Systems:
    - CRM System  → Customer, Product, Sales data
    - ERP System  → Customer Demographics, Locations, Product Categories

===============================================================================
*/



-- =============================================================================
-- TABLE: silver.crm_cust_info
-- =============================================================================
-- Cleansed customer master data from CRM system.
-- Transformations: deduplication, trimming, code standardization.
-- =============================================================================

DROP TABLE IF EXISTS silver.crm_cust_info;

CREATE TABLE silver.crm_cust_info (
    cst_id               INT,
    cst_key              VARCHAR(50),
    cst_firstname        VARCHAR(50),
    cst_lastname         VARCHAR(50),
    cst_martial_status   VARCHAR(50),
    cst_gndr             VARCHAR(50),
    cst_create_date      DATE,
    dwh_create_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- =============================================================================
-- TABLE: silver.crm_prd_info
-- =============================================================================
-- Cleansed product catalog from CRM system.
-- Transformations: key extraction, cost imputation, SCD Type 2 end dates.
-- =============================================================================

DROP TABLE IF EXISTS silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
    prd_id               INT,
    cat_id               VARCHAR(50),
    prd_key              VARCHAR(50),
    prd_nm               VARCHAR(50),
    prd_cost             INT,
    prd_line             VARCHAR(50),
    prd_start_dt         DATE,
    prd_end_dt           DATE,
    dwh_create_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- =============================================================================
-- TABLE: silver.crm_sales_details
-- =============================================================================
-- Cleansed sales transactions from CRM system.
-- Transformations: date conversion (INT → DATE), sales amount correction.
-- =============================================================================

DROP TABLE IF EXISTS silver.crm_sales_details;

CREATE TABLE silver.crm_sales_details (
    sls_ord_num          VARCHAR(50),
    sls_prd_key          VARCHAR(50),
    sls_cust_id          INT,
    sls_order_dt         DATE,
    sls_ship_dt          DATE,
    sls_due_dt           DATE,
    sls_sales            INT,
    sls_quantity         INT,
    sls_price            INT,
    dwh_create_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- =============================================================================
-- TABLE: silver.erp_cust_az12
-- =============================================================================
-- Cleansed customer demographics from ERP system.
-- Transformations: ID prefix removal (NAS), future date nullification.
-- =============================================================================

DROP TABLE IF EXISTS silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12 (
    cid                  VARCHAR(50),
    bdate                DATE,
    gen                  VARCHAR(50),
    dwh_create_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- =============================================================================
-- TABLE: silver.erp_loc_a101
-- =============================================================================
-- Cleansed customer location data from ERP system.
-- Transformations: country name standardization, whitespace trimming.
-- =============================================================================

DROP TABLE IF EXISTS silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101 (
    cid                  VARCHAR(50),
    cntry                VARCHAR(50),
    dwh_create_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



-- =============================================================================
-- TABLE: silver.erp_px_cat_g1v2
-- =============================================================================
-- Cleansed product category hierarchy from ERP system.
-- Transformations: whitespace trimming, maintenance flag standardization.
-- =============================================================================

DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2 (
    id                   VARCHAR(50),
    cat                  VARCHAR(50),
    subcat               VARCHAR(50),
    maintenance          VARCHAR(50),
    dwh_create_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
