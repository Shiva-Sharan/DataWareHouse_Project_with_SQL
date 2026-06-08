/*
===============================================================================
DDL SCRIPT: CREATE SILVER LAYER TABLES
===============================================================================
Purpose:
    Creates all tables required for the 'silver' schema in the data warehouse.

Behavior:
    - Existing tables are dropped before recreation
    - Tables are designed for PostgreSQL
    - Includes audit column: dwh_create_date

Layer:
    Silver Layer

Description:
    The silver layer stores cleaned and standardized raw data
    received from source systems before transformation into
    business-ready models.

Source Systems:
    - CRM System
    - ERP System
===============================================================================
*/


/*
===============================================================================
TABLE: silver.crm_cust_info
===============================================================================
Description:
    Stores customer master data extracted from the CRM system.
===============================================================================
*/

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



/*
===============================================================================
TABLE: silver.crm_prd_info
===============================================================================
Description:
    Stores product master data extracted from the CRM system.
===============================================================================
*/

DROP TABLE IF EXISTS silver.crm_prd_info;

CREATE TABLE silver.crm_prd_info (
    prd_id               INT,
	cat_id				 VARCHAR(50),
    prd_key              VARCHAR(50),
    prd_nm               VARCHAR(50),
    prd_cost             INT,
    prd_line             VARCHAR(50),
    prd_start_dt         DATE,
    prd_end_dt           DATE,
    dwh_create_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



/*
===============================================================================
TABLE: silver.crm_sales_details
===============================================================================
Description:
    Stores sales transaction data extracted from the CRM system.
===============================================================================
*/

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



/*
===============================================================================
TABLE: silver.erp_loc_a101
===============================================================================
Description:
    Stores customer location data extracted from the ERP system.
===============================================================================
*/

DROP TABLE IF EXISTS silver.erp_loc_a101;

CREATE TABLE silver.erp_loc_a101 (
    cid                  VARCHAR(50),
    cntry                VARCHAR(50),
    dwh_create_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



/*
===============================================================================
TABLE: silver.erp_cust_az12
===============================================================================
Description:
    Stores customer demographic data extracted from the ERP system.
===============================================================================
*/

DROP TABLE IF EXISTS silver.erp_cust_az12;

CREATE TABLE silver.erp_cust_az12 (
    cid                  VARCHAR(50),
    bdate                DATE,
    gen                  VARCHAR(50),
    dwh_create_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);



/*
===============================================================================
TABLE: silver.erp_px_cat_g1v2
===============================================================================
Description:
    Stores product category and maintenance information
    extracted from the ERP system.
===============================================================================
*/

DROP TABLE IF EXISTS silver.erp_px_cat_g1v2;

CREATE TABLE silver.erp_px_cat_g1v2 (
    id                   VARCHAR(50),
    cat                  VARCHAR(50),
    subcat               VARCHAR(50),
    maintenance          VARCHAR(50),
    dwh_create_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
