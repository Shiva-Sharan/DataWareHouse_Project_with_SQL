/*
===============================================================================
DDL SCRIPT: CREATE GOLD LAYER VIEWS (Star Schema)
===============================================================================

Purpose:
    Creates business-ready views in the 'gold' schema implementing a
    Star Schema data model for analytical reporting.

Layer:
    Gold Layer (Presentation / Data Mart)

Views Created:
    - gold.dim_customers  → Customer dimension (CRM + ERP integration)
    - gold.dim_products   → Product dimension (CRM + ERP categories)
    - gold.fact_sales     → Sales fact table (transactional grain)

Data Model:
    Star Schema with surrogate keys generated via ROW_NUMBER().
    Dimensions join Silver-layer tables across CRM and ERP systems.

Notes:
    - Views provide always-fresh query results from Silver layer
    - Run this script AFTER Silver layer is fully loaded
    - Designed for PostgreSQL

===============================================================================
*/



-- =============================================================================
-- VIEW: gold.dim_customers
-- =============================================================================
-- Integrates customer data from CRM (master) and ERP (demographics, location).
-- Gender resolution: CRM value preferred; ERP used as fallback.
-- =============================================================================

CREATE VIEW gold.dim_customers AS

SELECT

    ROW_NUMBER() OVER (ORDER BY cu.cst_id)
        AS customer_key,

    cu.cst_id              AS customer_id,
    cu.cst_key             AS customer_number,
    cu.cst_firstname       AS first_name,
    cu.cst_lastname        AS last_name,
    l.cntry                AS country,
    cu.cst_martial_status  AS marital_status,

    -- Gender resolution: prefer CRM, fallback to ERP
    CASE
        WHEN cu.cst_gndr != 'n/a' THEN cu.cst_gndr
        ELSE COALESCE(e.gen, 'n/a')
    END AS gender,

    e.bdate                AS birth_date,
    cu.cst_create_date     AS create_date

FROM silver.crm_cust_info cu

LEFT JOIN silver.erp_cust_az12 e
    ON cu.cst_key = e.cid

LEFT JOIN silver.erp_loc_a101 l
    ON cu.cst_key = l.cid;



-- =============================================================================
-- VIEW: gold.dim_products
-- =============================================================================
-- Combines CRM product master with ERP category hierarchy.
-- Filters to current product versions only (prd_end_dt IS NULL).
-- =============================================================================

CREATE VIEW gold.dim_products AS

SELECT

    ROW_NUMBER() OVER (ORDER BY p.prd_start_dt, p.prd_key)
        AS product_key,

    p.prd_id               AS product_id,
    p.prd_key              AS product_number,
    p.prd_nm               AS product_name,
    p.cat_id               AS category_id,
    pc.cat                 AS category,
    pc.subcat              AS sub_category,
    pc.maintenance,
    p.prd_cost             AS cost,
    p.prd_line             AS product_line,
    p.prd_start_dt         AS start_date

FROM silver.crm_prd_info p

LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON p.cat_id = pc.id

WHERE p.prd_end_dt IS NULL;



-- =============================================================================
-- VIEW: gold.fact_sales
-- =============================================================================
-- Central fact table at the sales transaction grain.
-- Joins to dimension views to resolve surrogate keys.
-- Business rule: sales = quantity × price
-- =============================================================================

CREATE VIEW gold.fact_sales AS

SELECT

    s.sls_ord_num          AS order_number,
    p.product_key,
    c.customer_key,
    s.sls_order_dt         AS order_date,
    s.sls_ship_dt          AS ship_date,
    s.sls_due_dt           AS due_date,
    s.sls_sales            AS sales,
    s.sls_quantity         AS quantity,
    s.sls_price            AS price

FROM silver.crm_sales_details s

LEFT JOIN gold.dim_products p
    ON s.sls_prd_key = p.product_number

LEFT JOIN gold.dim_customers c
    ON s.sls_cust_id = c.customer_id;
