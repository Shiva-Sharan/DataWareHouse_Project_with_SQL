# 📖 Data Catalog

> Enterprise data catalog for the SQL Data Warehouse project.
> Documents every table and view across the Bronze, Silver, and Gold layers.

---

## Table of Contents

- [Bronze Layer](#-bronze-layer)
  - [bronze.crm_cust_info](#bronzecrm_cust_info)
  - [bronze.crm_prd_info](#bronzecrm_prd_info)
  - [bronze.crm_sales_details](#bronzecrm_sales_details)
  - [bronze.erp_cust_az12](#bronzeerp_cust_az12)
  - [bronze.erp_loc_a101](#bronzeerp_loc_a101)
  - [bronze.erp_px_cat_g1v2](#bronzeerp_px_cat_g1v2)
- [Silver Layer](#-silver-layer)
  - [silver.crm_cust_info](#silvercrm_cust_info)
  - [silver.crm_prd_info](#silvercrm_prd_info)
  - [silver.crm_sales_details](#silvercrm_sales_details)
  - [silver.erp_cust_az12](#silvererp_cust_az12)
  - [silver.erp_loc_a101](#silvererp_loc_a101)
  - [silver.erp_px_cat_g1v2](#silvererp_px_cat_g1v2)
- [Gold Layer](#-gold-layer)
  - [gold.dim_customers](#golddim_customers)
  - [gold.dim_products](#golddim_products)
  - [gold.fact_sales](#goldfact_sales)

---

## 🥉 Bronze Layer

> **Purpose:** Raw data ingestion layer. Stores exact copies of source system extracts with no transformations applied. Serves as the immutable audit trail for all downstream processing.
>
> **Load Strategy:** Full truncate-and-reload via PostgreSQL `COPY` command.
>
> **Object Type:** Tables
>
> **Stored Procedure:** `bronze.load_bronze()`

---

### `bronze.crm_cust_info`

**Description:**
Raw customer master data extracted from the CRM system. Contains customer identifiers, personal information, and account metadata. This is the primary customer record used for identity resolution across the warehouse.

**Source File:** `datasets/source_crm/cust_info.csv`
**Approximate Row Count:** ~18,400

#### Columns

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `cst_id` | `INT` | Yes | Numeric customer identifier (natural key) |
| `cst_key` | `VARCHAR(50)` | Yes | Alphanumeric customer business key (e.g., `AW00011000`) |
| `cst_firstname` | `VARCHAR(50)` | Yes | Customer first name (may contain leading/trailing whitespace) |
| `cst_lastname` | `VARCHAR(50)` | Yes | Customer last name (may contain leading/trailing whitespace) |
| `cst_martial_status` | `VARCHAR(50)` | Yes | Marital status code (`S` = Single, `M` = Married) |
| `cst_gndr` | `VARCHAR(50)` | Yes | Gender code (`F` = Female, `M` = Male) |
| `cst_create_date` | `DATE` | Yes | Account creation date |

#### Keys & Relationships

| Key Type | Column(s) | Notes |
|---|---|---|
| Natural Key | `cst_id` | Not enforced; may contain duplicates in raw data |
| Business Key | `cst_key` | Used for cross-system joins with ERP tables |

#### Known Data Quality Issues

- Duplicate `cst_id` values exist (resolved in Silver via deduplication)
- `cst_firstname` and `cst_lastname` contain leading/trailing whitespace
- `cst_martial_status` and `cst_gndr` use single-character codes

---

### `bronze.crm_prd_info`

**Description:**
Raw product catalog from the CRM system. Contains product identifiers, pricing, product line classifications, and version dating for Slowly Changing Dimension tracking.

**Source File:** `datasets/source_crm/prd_info.csv`
**Approximate Row Count:** ~397

#### Columns

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `prd_id` | `INT` | Yes | Numeric product identifier |
| `prd_key` | `VARCHAR(50)` | Yes | Composite product key (e.g., `CO-RF-FR-R92B-58`). Encodes both category ID and product number. |
| `prd_nm` | `VARCHAR(50)` | Yes | Product name (may contain whitespace) |
| `prd_cost` | `INT` | Yes | Product unit cost (NULL for some records) |
| `prd_line` | `VARCHAR(50)` | Yes | Product line code (`M`, `R`, `S`, `T`) with trailing whitespace |
| `prd_start_dt` | `TIMESTAMP` | Yes | Product version start date |
| `prd_end_dt` | `TIMESTAMP` | Yes | Product version end date (NULL = current version) |

#### Keys & Relationships

| Key Type | Column(s) | Notes |
|---|---|---|
| Natural Key | `prd_id` | Numeric product identifier |
| Business Key | `prd_key` | Composite key — split into `cat_id` and `prd_key` in Silver |

#### Known Data Quality Issues

- `prd_key` is a composite value requiring parsing in the Silver layer
- `prd_cost` is NULL for some products
- `prd_line` contains trailing whitespace
- Some `prd_end_dt` values predate `prd_start_dt` (corrected via LEAD in Silver)

---

### `bronze.crm_sales_details`

**Description:**
Raw sales transaction records from the CRM system. Contains order details, product references, customer references, date information, and financial measures at the individual order-line grain.

**Source File:** `datasets/source_crm/sales_details.csv`

#### Columns

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `sls_ord_num` | `VARCHAR(50)` | Yes | Sales order number |
| `sls_prd_key` | `VARCHAR(50)` | Yes | Product key reference (joins to `prd_key` after Silver extraction) |
| `sls_cust_id` | `INT` | Yes | Customer ID reference (joins to `cst_id`) |
| `sls_order_dt` | `INT` | Yes | Order date stored as integer (`YYYYMMDD` format) |
| `sls_ship_dt` | `INT` | Yes | Shipping date stored as integer (`YYYYMMDD` format) |
| `sls_due_dt` | `INT` | Yes | Due date stored as integer (`YYYYMMDD` format) |
| `sls_sales` | `INT` | Yes | Total sales amount |
| `sls_quantity` | `INT` | Yes | Quantity sold |
| `sls_price` | `INT` | Yes | Unit price |

#### Keys & Relationships

| Key Type | Column(s) | References |
|---|---|---|
| Foreign Key | `sls_prd_key` | → `bronze.crm_prd_info.prd_key` (extracted portion) |
| Foreign Key | `sls_cust_id` | → `bronze.crm_cust_info.cst_id` |

#### Known Data Quality Issues

- Date columns stored as `INT` instead of `DATE` (converted in Silver)
- Zero and invalid date values exist
- `sls_sales != sls_quantity * sls_price` for some records
- Negative `sls_price` values exist

---

### `bronze.erp_cust_az12`

**Description:**
Raw customer demographic data from the ERP system. Supplements the CRM customer record with birth date and an independently captured gender value.

**Source File:** `datasets/source_erp/CUST_AZ12.csv`
**Approximate Row Count:** ~18,400

#### Columns

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `cid` | `VARCHAR(50)` | Yes | Customer ID with `NAS` prefix (e.g., `NASAW00011000`) |
| `bdate` | `DATE` | Yes | Customer birth date |
| `gen` | `VARCHAR(50)` | Yes | Gender value (`Male`, `Female`) — full-word format |

#### Keys & Relationships

| Key Type | Column(s) | References |
|---|---|---|
| Business Key | `cid` | → `bronze.crm_cust_info.cst_key` (after stripping `NAS` prefix) |

#### Known Data Quality Issues

- `cid` values are prefixed with `NAS`, requiring substring extraction for cross-system joins
- Some `bdate` values are in the future (invalid)

---

### `bronze.erp_loc_a101`

**Description:**
Raw customer location data from the ERP system. Provides the geographic country association for each customer.

**Source File:** `datasets/source_erp/LOC_A101.csv`
**Approximate Row Count:** ~18,400

#### Columns

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `cid` | `VARCHAR(50)` | Yes | Customer ID (e.g., `AW-00011000`) — dash-separated format |
| `cntry` | `VARCHAR(50)` | Yes | Country name or abbreviation |

#### Keys & Relationships

| Key Type | Column(s) | References |
|---|---|---|
| Business Key | `cid` | → `bronze.crm_cust_info.cst_key` (format varies) |

#### Known Data Quality Issues

- `cid` format differs from CRM (`AW-00011000` vs. `AW00011000`)
- `cntry` may contain abbreviations (`DE`, `US`) instead of full names
- Whitespace and NULL values may exist

---

### `bronze.erp_px_cat_g1v2`

**Description:**
Raw product category hierarchy from the ERP system. Provides the category and subcategory classification used to enrich the CRM product catalog in the Gold layer.

**Source File:** `datasets/source_erp/PX_CAT_G1V2.csv`
**Approximate Row Count:** 37

#### Columns

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `id` | `VARCHAR(50)` | Yes | Category identifier (e.g., `AC_BR`) — matches extracted `cat_id` from `crm_prd_info.prd_key` |
| `cat` | `VARCHAR(50)` | Yes | Top-level product category (e.g., `Accessories`, `Bikes`, `Components`) |
| `subcat` | `VARCHAR(50)` | Yes | Product subcategory (e.g., `Bike Racks`, `Road Bikes`) |
| `maintenance` | `VARCHAR(50)` | Yes | Maintenance required flag (`Yes`, `No`) |

#### Keys & Relationships

| Key Type | Column(s) | References |
|---|---|---|
| Primary Key | `id` | Referenced by `silver.crm_prd_info.cat_id` |

#### Known Data Quality Issues

- Potential whitespace in `cat`, `subcat`, `maintenance` fields

---

## 🥈 Silver Layer

> **Purpose:** Cleansed and standardized data layer. Data is deduplicated, trimmed, type-cast, and code-standardized before being made available for Gold layer integration.
>
> **Load Strategy:** Full truncate-and-reload via `INSERT INTO ... SELECT` from Bronze.
>
> **Object Type:** Tables (with `dwh_create_date` audit column)
>
> **Stored Procedure:** `silver.load_silver()`

---

### `silver.crm_cust_info`

**Description:**
Cleansed customer master data. Deduplicated to one record per customer, with trimmed name fields and standardized code values. Serves as the primary customer anchor table for Gold layer integration.

#### Columns

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `cst_id` | `INT` | No | Unique customer identifier (deduplicated) |
| `cst_key` | `VARCHAR(50)` | No | Customer business key — used for ERP cross-joins |
| `cst_firstname` | `VARCHAR(50)` | Yes | Trimmed first name |
| `cst_lastname` | `VARCHAR(50)` | Yes | Trimmed last name |
| `cst_martial_status` | `VARCHAR(50)` | Yes | Standardized: `Single`, `Married`, or `n/a` |
| `cst_gndr` | `VARCHAR(50)` | Yes | Standardized: `Female`, `Male`, or `n/a` |
| `cst_create_date` | `DATE` | Yes | Account creation date |
| `dwh_create_date` | `TIMESTAMP` | No | ETL audit timestamp (auto-populated) |

#### Transformations Applied

| Transformation | Logic |
|---|---|
| **Deduplication** | `ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC)` — keeps latest record |
| **NULL Filtering** | Records with `cst_id IS NULL` are excluded |
| **Whitespace Trimming** | `TRIM()` applied to `cst_firstname`, `cst_lastname` |
| **Marital Status Standardization** | `S` → `Single`, `M` → `Married`, else → `n/a` |
| **Gender Standardization** | `F` → `Female`, `M` → `Male`, else → `n/a` |

#### Business Usage

- Primary source for customer dimension in Gold layer
- Used for customer segmentation by gender, marital status
- Join anchor for ERP demographics and location data

---

### `silver.crm_prd_info`

**Description:**
Cleansed and enriched product catalog. The composite `prd_key` is split into a category ID and a clean product key. Product line codes are expanded to readable values, and SCD Type 2 end dates are calculated.

#### Columns

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `prd_id` | `INT` | No | Unique product identifier |
| `cat_id` | `VARCHAR(50)` | Yes | Extracted category ID (e.g., `CO_RF`) — joins to `erp_px_cat_g1v2.id` |
| `prd_key` | `VARCHAR(50)` | Yes | Extracted product key (e.g., `FR-R92B-58`) |
| `prd_nm` | `VARCHAR(50)` | Yes | Trimmed product name |
| `prd_cost` | `INT` | No | Product cost (NULLs replaced with `0`) |
| `prd_line` | `VARCHAR(50)` | Yes | Standardized: `Mountain`, `Road`, `Other Sales`, `Touring`, or `n/a` |
| `prd_start_dt` | `DATE` | Yes | Product version start date |
| `prd_end_dt` | `DATE` | Yes | Calculated end date (NULL = current version) |
| `dwh_create_date` | `TIMESTAMP` | No | ETL audit timestamp |

#### Transformations Applied

| Transformation | Logic |
|---|---|
| **Category ID Extraction** | `REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')` |
| **Product Key Extraction** | `SUBSTRING(prd_key, 7, LENGTH(prd_key))` |
| **Whitespace Trimming** | `TRIM()` on `prd_nm` |
| **NULL Cost Handling** | `COALESCE(prd_cost, 0)` |
| **Product Line Standardization** | `M` → `Mountain`, `R` → `Road`, `S` → `Other Sales`, `T` → `Touring` |
| **SCD Type 2 End Date** | `LEAD(prd_start_dt) OVER (...) - INTERVAL '1 day'` |

#### Business Usage

- Primary source for product dimension in Gold layer
- Enables product-level cost analysis and product line segmentation
- Category ID links product to ERP category hierarchy

---

### `silver.crm_sales_details`

**Description:**
Cleansed sales transactions with corrected date types and validated financial calculations. Integer dates are converted to proper `DATE` type, and sales amounts are recalculated where inconsistent with `quantity × price`.

#### Columns

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `sls_ord_num` | `VARCHAR(50)` | Yes | Sales order number |
| `sls_prd_key` | `VARCHAR(50)` | Yes | Product key (joins to `silver.crm_prd_info.prd_key`) |
| `sls_cust_id` | `INT` | Yes | Customer ID (joins to `silver.crm_cust_info.cst_id`) |
| `sls_order_dt` | `DATE` | Yes | Order date (converted from INT) |
| `sls_ship_dt` | `DATE` | Yes | Shipping date (converted from INT) |
| `sls_due_dt` | `DATE` | Yes | Due date (converted from INT) |
| `sls_sales` | `INT` | Yes | Corrected total sales amount |
| `sls_quantity` | `INT` | Yes | Quantity sold |
| `sls_price` | `INT` | Yes | Corrected unit price |
| `dwh_create_date` | `TIMESTAMP` | No | ETL audit timestamp |

#### Transformations Applied

| Transformation | Logic |
|---|---|
| **Date Conversion** | `TO_DATE(sls_order_dt::TEXT, 'YYYYMMDD')` — zero/NULL values become NULL |
| **Sales Correction** | If `sales IS NULL` or `sales <= 0` or `sales != quantity × ABS(price)`, then `quantity × ABS(price)` |
| **Price Derivation** | If `price IS NULL` or `price <= 0`, then `sales / NULLIF(quantity, 0)` |

#### Business Usage

- Feeds the central `gold.fact_sales` view
- Enables sales performance analysis, revenue trending, and order fulfillment tracking
- Business rule: `sales = quantity × price`

---

### `silver.erp_cust_az12`

**Description:**
Cleansed customer demographics from the ERP system. The `NAS` prefix is stripped from customer IDs to enable cross-system joining with CRM data.

#### Columns

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `cid` | `VARCHAR(50)` | Yes | Cleaned customer ID (NAS prefix removed) |
| `bdate` | `DATE` | Yes | Birth date (future dates nullified) |
| `gen` | `VARCHAR(50)` | Yes | Standardized: `Female`, `Male`, or `n/a` |
| `dwh_create_date` | `TIMESTAMP` | No | ETL audit timestamp |

#### Transformations Applied

| Transformation | Logic |
|---|---|
| **ID Normalization** | `SUBSTRING(cid, 4, LENGTH(cid))` when `cid LIKE 'NAS%'` |
| **Future Date Nullification** | `CASE WHEN bdate > CURRENT_DATE THEN NULL` |
| **Gender Standardization** | `F`/`FEMALE` → `Female`, `M`/`MALE` → `Male`, else → `n/a` |

#### Business Usage

- Provides birth date for customer age analysis
- Gender fallback when CRM gender is `n/a`

---

### `silver.erp_loc_a101`

**Description:**
Cleansed customer location data from the ERP system. Country names are standardized and whitespace is trimmed.

#### Columns

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `cid` | `VARCHAR(50)` | Yes | Cleaned customer ID |
| `cntry` | `VARCHAR(50)` | Yes | Standardized country name |
| `dwh_create_date` | `TIMESTAMP` | No | ETL audit timestamp |

#### Transformations Applied

| Transformation | Logic |
|---|---|
| **ID Normalization** | `SUBSTRING(cid, 4, LENGTH(cid))` when `cid LIKE 'NAS%'` |
| **Country Standardization** | `DE` → `Germany`, `US`/`USA` → `United States`, empty → `n/a` |
| **Whitespace Trimming** | `TRIM()` on `cntry` |

#### Business Usage

- Provides geographic dimension for customer analytics
- Enables regional sales segmentation and country-level reporting

---

### `silver.erp_px_cat_g1v2`

**Description:**
Cleansed product category hierarchy from the ERP system. Whitespace is trimmed from all text fields.

#### Columns

| Column Name | Data Type | Nullable | Description |
|---|---|---|---|
| `id` | `VARCHAR(50)` | Yes | Category identifier (e.g., `AC_BR`) |
| `cat` | `VARCHAR(50)` | Yes | Trimmed top-level category |
| `subcat` | `VARCHAR(50)` | Yes | Trimmed subcategory |
| `maintenance` | `VARCHAR(50)` | Yes | Trimmed maintenance flag (`Yes` / `No`) |
| `dwh_create_date` | `TIMESTAMP` | No | ETL audit timestamp |

#### Transformations Applied

| Transformation | Logic |
|---|---|
| **Whitespace Trimming** | `TRIM()` on `cat`, `subcat`, `maintenance` |

#### Business Usage

- Enriches product dimension with category hierarchy
- Enables product mix analysis by category and subcategory
- Maintenance flag supports operational planning queries

---

## 🥇 Gold Layer

> **Purpose:** Business-ready presentation layer implementing a Star Schema dimensional model. Designed for direct consumption by BI tools, dashboards, and analytical queries.
>
> **Load Strategy:** No load — implemented as SQL **views** over Silver tables for always-fresh results.
>
> **Object Type:** Views
>
> **DDL Script:** `scripts/gold/ddl_gold.sql`

---

### `gold.dim_customers`

**Description:**
Conformed customer dimension integrating data from the CRM customer master, ERP demographics, and ERP locations into a single, query-optimized view. Implements a gender resolution strategy where the CRM value is preferred and ERP serves as the fallback.

**Type:** View (dimension)

#### Columns

| Column Name | Data Type | Source Table(s) | Description |
|---|---|---|---|
| `customer_key` | `INT` | Generated | Surrogate key — `ROW_NUMBER() OVER (ORDER BY cst_id)` |
| `customer_id` | `INT` | `silver.crm_cust_info` | Natural customer identifier |
| `customer_number` | `VARCHAR(50)` | `silver.crm_cust_info` | Alphanumeric business key |
| `first_name` | `VARCHAR(50)` | `silver.crm_cust_info` | Cleaned first name |
| `last_name` | `VARCHAR(50)` | `silver.crm_cust_info` | Cleaned last name |
| `country` | `VARCHAR(50)` | `silver.erp_loc_a101` | Standardized country |
| `marital_status` | `VARCHAR(50)` | `silver.crm_cust_info` | `Single`, `Married`, or `n/a` |
| `gender` | `VARCHAR(50)` | `silver.crm_cust_info` + `silver.erp_cust_az12` | CRM preferred; ERP fallback |
| `birth_date` | `DATE` | `silver.erp_cust_az12` | Customer date of birth |
| `create_date` | `DATE` | `silver.crm_cust_info` | Account creation date |

#### Keys & Relationships

| Key Type | Column | Notes |
|---|---|---|
| Surrogate Key (PK) | `customer_key` | Non-persistent — regenerated per query execution |
| Natural Key | `customer_id` | Unique per customer |
| Business Key | `customer_number` | Alphanumeric customer code |

#### Joins

```
silver.crm_cust_info cu
  LEFT JOIN silver.erp_cust_az12 e  ON cu.cst_key = e.cid
  LEFT JOIN silver.erp_loc_a101 l   ON cu.cst_key = l.cid
```

#### Business Usage

- Customer segmentation by demographics (gender, marital status, country)
- Customer lifetime analysis using `create_date` and `birth_date`
- Geographic distribution reporting
- Dimension table for all customer-centric fact queries

---

### `gold.dim_products`

**Description:**
Conformed product dimension combining the CRM product catalog with the ERP product category hierarchy. Filtered to **current product versions only** (`prd_end_dt IS NULL`), ensuring the dimension reflects only active products.

**Type:** View (dimension)

#### Columns

| Column Name | Data Type | Source Table(s) | Description |
|---|---|---|---|
| `product_key` | `INT` | Generated | Surrogate key — `ROW_NUMBER() OVER (ORDER BY prd_start_dt, prd_key)` |
| `product_id` | `INT` | `silver.crm_prd_info` | Natural product identifier |
| `product_number` | `VARCHAR(50)` | `silver.crm_prd_info` | Extracted product key |
| `product_name` | `VARCHAR(50)` | `silver.crm_prd_info` | Cleaned product name |
| `category_id` | `VARCHAR(50)` | `silver.crm_prd_info` | Extracted category identifier |
| `category` | `VARCHAR(50)` | `silver.erp_px_cat_g1v2` | Top-level product category |
| `sub_category` | `VARCHAR(50)` | `silver.erp_px_cat_g1v2` | Product subcategory |
| `maintenance` | `VARCHAR(50)` | `silver.erp_px_cat_g1v2` | Maintenance required flag |
| `cost` | `INT` | `silver.crm_prd_info` | Product unit cost |
| `product_line` | `VARCHAR(50)` | `silver.crm_prd_info` | `Mountain`, `Road`, `Other Sales`, `Touring`, or `n/a` |
| `start_date` | `DATE` | `silver.crm_prd_info` | Product availability date |

#### Keys & Relationships

| Key Type | Column | Notes |
|---|---|---|
| Surrogate Key (PK) | `product_key` | Non-persistent — regenerated per query execution |
| Natural Key | `product_id` | Unique per product version |
| Business Key | `product_number` | Extracted from composite CRM key |

#### Joins

```
silver.crm_prd_info p
  LEFT JOIN silver.erp_px_cat_g1v2 pc  ON p.cat_id = pc.id
WHERE p.prd_end_dt IS NULL
```

#### Business Usage

- Product mix analysis by category and subcategory
- Product line performance comparison
- Cost analysis and margin calculations
- Maintenance planning by product category

---

### `gold.fact_sales`

**Description:**
Central fact table at the **sales order line** grain. Each row represents a single product sold to a single customer within a sales order. Joins to both dimension views to resolve surrogate keys for star-schema querying.

**Type:** View (fact)

#### Columns

| Column Name | Data Type | Source Table(s) | Description |
|---|---|---|---|
| `order_number` | `VARCHAR(50)` | `silver.crm_sales_details` | Sales order number |
| `product_key` | `INT` | `gold.dim_products` | FK to product dimension |
| `customer_key` | `INT` | `gold.dim_customers` | FK to customer dimension |
| `order_date` | `DATE` | `silver.crm_sales_details` | Date of sale |
| `ship_date` | `DATE` | `silver.crm_sales_details` | Shipment date |
| `due_date` | `DATE` | `silver.crm_sales_details` | Payment due date |
| `sales` | `INT` | `silver.crm_sales_details` | Total sales amount (`quantity × price`) |
| `quantity` | `INT` | `silver.crm_sales_details` | Units sold |
| `price` | `INT` | `silver.crm_sales_details` | Unit price |

#### Keys & Relationships

| Key Type | Column | References |
|---|---|---|
| Foreign Key | `product_key` | → `gold.dim_products.product_key` |
| Foreign Key | `customer_key` | → `gold.dim_customers.customer_key` |

#### Joins

```
silver.crm_sales_details s
  LEFT JOIN gold.dim_products p   ON s.sls_prd_key = p.product_number
  LEFT JOIN gold.dim_customers c  ON s.sls_cust_id = c.customer_id
```

#### Measures & Calculations

| Measure | Formula | Description |
|---|---|---|
| Total Sales | `SUM(sales)` | Aggregate revenue |
| Total Quantity | `SUM(quantity)` | Total units sold |
| Average Price | `AVG(price)` | Average unit price |
| Sales Validation | `sales = quantity × price` | Business rule |

#### Business Usage

- Revenue and sales performance analysis
- Order fulfillment tracking (order → ship → due date pipeline)
- Customer purchasing behavior analysis
- Product demand forecasting
- Time-series trending by order date
- Top-N customer / product / region reporting

---

## Appendix: Cross-System Key Mapping

The following table summarizes how keys from different source systems are aligned for integration:

| CRM Column | ERP Column | Transformation | Join Point |
|---|---|---|---|
| `crm_cust_info.cst_key` | `erp_cust_az12.cid` | Strip `NAS` prefix from ERP | Silver → Gold (dim_customers) |
| `crm_cust_info.cst_key` | `erp_loc_a101.cid` | Strip `NAS` prefix from ERP | Silver → Gold (dim_customers) |
| `crm_prd_info.prd_key` (extracted `cat_id`) | `erp_px_cat_g1v2.id` | `REPLACE(SUBSTRING(...), '-', '_')` | Silver → Gold (dim_products) |
| `crm_sales_details.sls_prd_key` | `crm_prd_info.prd_key` (extracted) | Direct match after Silver extraction | Silver → Gold (fact_sales) |
| `crm_sales_details.sls_cust_id` | `crm_cust_info.cst_id` | Direct match | Silver → Gold (fact_sales) |

---

<div align="center">

*Last updated: June 2026*

</div>
