# 📐 Naming Conventions

> Enterprise naming standards for the SQL Data Warehouse project.
> Ensures consistency, readability, and maintainability across all database objects, ETL scripts, and documentation.

---

## Table of Contents

- [General Principles](#general-principles)
- [Schema Naming](#schema-naming)
- [Table Naming](#table-naming)
- [View Naming](#view-naming)
- [Column Naming](#column-naming)
- [Key & Constraint Naming](#key--constraint-naming)
- [Stored Procedure Naming](#stored-procedure-naming)
- [SQL Keyword Style](#sql-keyword-style)
- [File Naming](#file-naming)
- [Documentation File Naming](#documentation-file-naming)
- [Dataset File Naming](#dataset-file-naming)
- [Quick Reference](#quick-reference)

---

## General Principles

| Principle | Standard |
|---|---|
| **Case** | `snake_case` for all identifiers (schemas, tables, columns, files) |
| **Letter Case** | All lowercase for database objects |
| **Abbreviations** | Use consistent, well-known abbreviations (see table below) |
| **Clarity** | Names should be self-documenting — avoid cryptic encodings |
| **Consistency** | Once a pattern is established, apply it uniformly |
| **Reserved Words** | Never use SQL reserved words as identifiers |

### Standard Abbreviations

| Abbreviation | Full Form | Usage Context |
|---|---|---|
| `cst` | Customer | Column prefix |
| `prd` | Product | Column prefix |
| `sls` | Sales | Column prefix |
| `dt` | Date | Column suffix |
| `ts` | Timestamp | Column suffix |
| `nm` | Name | Column suffix |
| `num` | Number | Column suffix |
| `id` | Identifier | Column suffix (natural key) |
| `key` | Key | Column suffix (surrogate/business key) |
| `dim` | Dimension | Table prefix (Gold layer) |
| `fact` | Fact | Table prefix (Gold layer) |
| `dwh` | Data Warehouse | Audit column prefix |
| `cat` | Category | Column/table segment |
| `gndr` | Gender | Column name |
| `cntry` | Country | Column name |

---

## Schema Naming

Schemas follow the **Medallion Architecture** layer names. All lowercase, single-word.

| Schema | Purpose | Convention |
|---|---|---|
| `bronze` | Raw data ingestion | Layer name, lowercase |
| `silver` | Cleansed and standardized data | Layer name, lowercase |
| `gold` | Business-ready dimensional model | Layer name, lowercase |

**Rule:** One schema per warehouse layer. No additional schemas for staging, temp, or utility objects within this project scope.

---

## Table Naming

### Bronze & Silver Layers

Tables follow the pattern:

```
{source_system}_{source_entity}
```

| Component | Convention | Examples |
|---|---|---|
| Source System | Lowercase system abbreviation | `crm`, `erp` |
| Source Entity | Original source entity name, lowercase | `cust_info`, `prd_info`, `sales_details` |
| Separator | Underscore `_` | — |

**Examples:**

| Table | Breakdown |
|---|---|
| `bronze.crm_cust_info` | CRM system → Customer Info entity |
| `bronze.erp_loc_a101` | ERP system → Location A101 entity |
| `silver.crm_sales_details` | CRM system → Sales Details entity |
| `silver.erp_px_cat_g1v2` | ERP system → Product Category G1V2 entity |

> **Note:** Bronze and Silver tables retain source system naming to maintain clear data lineage back to the originating system.

### Gold Layer

Gold tables follow **dimensional modeling** conventions:

```
{table_type}_{business_entity}
```

| Type Prefix | Purpose | Examples |
|---|---|---|
| `dim_` | Dimension table | `dim_customers`, `dim_products` |
| `fact_` | Fact table | `fact_sales` |
| `bridge_` | Bridge / association table | `bridge_customer_region` (future) |
| `agg_` | Pre-aggregated summary table | `agg_monthly_sales` (future) |

**Examples:**

| Table | Type | Description |
|---|---|---|
| `gold.dim_customers` | Dimension | Customer master dimension |
| `gold.dim_products` | Dimension | Product master dimension |
| `gold.fact_sales` | Fact | Sales transaction fact |

---

## View Naming

Views follow the same naming convention as tables. In this project, all Gold layer objects are implemented as views.

```
{schema}.{table_type}_{business_entity}
```

No special prefix or suffix is added to distinguish views from tables — the object type is determined by the schema context:
- **Bronze / Silver:** Always tables
- **Gold:** Always views

---

## Column Naming

### General Pattern

```
{entity_prefix}_{attribute_name}
```

| Component | Convention | Examples |
|---|---|---|
| Entity Prefix | 2–4 character abbreviation of the entity | `cst_`, `prd_`, `sls_` |
| Attribute Name | Descriptive name in `snake_case` | `firstname`, `order_dt`, `sales` |

### Suffix Conventions

| Suffix | Data Type | Examples |
|---|---|---|
| `_id` | Natural/business identifier | `cst_id`, `prd_id`, `sls_cust_id` |
| `_key` | Surrogate key or business key | `customer_key`, `product_key`, `cst_key` |
| `_dt` | Date (DATE type) | `sls_order_dt`, `prd_start_dt`, `cst_create_date` |
| `_ts` | Timestamp (TIMESTAMP type) | `dwh_create_date` (exception: uses `_date` suffix) |
| `_nm` | Name field | `prd_nm` |
| `_num` | Order/sequence number | `sls_ord_num` |
| `_status` | Status or state value | `cst_martial_status` |

### Gold Layer Column Naming

Gold layer columns use **full, business-readable names** without entity prefixes:

| Bronze/Silver Column | Gold Column | Reason |
|---|---|---|
| `cst_id` | `customer_id` | Business clarity |
| `cst_firstname` | `first_name` | Readability |
| `prd_nm` | `product_name` | Readability |
| `sls_order_dt` | `order_date` | Full word for business users |
| `sls_sales` | `sales` | Simplified for reporting |

### Audit Columns

| Column | Type | Convention |
|---|---|---|
| `dwh_create_date` | `TIMESTAMP DEFAULT CURRENT_TIMESTAMP` | Present in all Silver layer tables |

### Boolean / Flag Columns

For future expansion, use the `is_` or `has_` prefix:

```
is_active, is_deleted, has_warranty
```

---

## Key & Constraint Naming

### Surrogate Keys

Generated via `ROW_NUMBER()` in Gold layer views. Named with the `_key` suffix.

| Key | Table | Generation Logic |
|---|---|---|
| `customer_key` | `gold.dim_customers` | `ROW_NUMBER() OVER (ORDER BY cst_id)` |
| `product_key` | `gold.dim_products` | `ROW_NUMBER() OVER (ORDER BY prd_start_dt, prd_key)` |

### Foreign Keys

Named to match the dimension's surrogate key column:

| FK Column | Fact Table | References |
|---|---|---|
| `customer_key` | `gold.fact_sales` | → `gold.dim_customers.customer_key` |
| `product_key` | `gold.fact_sales` | → `gold.dim_products.product_key` |

### Constraint Naming (Future)

If formal constraints are added, follow this pattern:

```
{constraint_type}_{table}_{column(s)}
```

| Type | Prefix | Example |
|---|---|---|
| Primary Key | `pk_` | `pk_dim_customers_customer_key` |
| Foreign Key | `fk_` | `fk_fact_sales_customer_key` |
| Unique | `uq_` | `uq_dim_customers_customer_id` |
| Check | `ck_` | `ck_fact_sales_quantity_positive` |
| Index | `ix_` | `ix_fact_sales_order_date` |

---

## Stored Procedure Naming

Procedures follow the pattern:

```
{schema}.{action}_{layer}
```

| Procedure | Schema | Description |
|---|---|---|
| `bronze.load_bronze()` | `bronze` | Loads raw data into Bronze layer |
| `silver.load_silver()` | `silver` | Transforms and loads into Silver layer |

### Convention Rules

- **Schema:** Matches the target layer
- **Action Prefix:** `load_` for data loading procedures
- **Layer Suffix:** Target layer name

### Future Patterns

| Pattern | Use Case | Example |
|---|---|---|
| `load_{layer}` | Full layer reload | `load_bronze()` |
| `load_{table}` | Single-table reload | `load_crm_cust_info()` |
| `validate_{layer}` | Data quality checks | `validate_silver()` |
| `refresh_{view}` | Materialized view refresh | `refresh_dim_customers()` |

---

## SQL Keyword Style

| Rule | Standard | Example |
|---|---|---|
| **Keywords** | UPPERCASE | `SELECT`, `FROM`, `WHERE`, `INSERT INTO` |
| **Identifiers** | lowercase | `silver.crm_cust_info`, `customer_key` |
| **Aliases** | lowercase, short, meaningful | `cu`, `p`, `s`, `pc`, `e`, `l` |
| **Indentation** | 4 spaces (no tabs) | — |
| **Comma Style** | Trailing commas | — |
| **Blank Lines** | Between logical query blocks | — |

### Comment Style

```sql
-- Single-line comments for inline notes

/*
===============================================================================
Block headers for major sections
===============================================================================
*/

/*
-------------------------------------------------------------------------------
Sub-section headers for individual checks or steps
-------------------------------------------------------------------------------
*/
```

---

## File Naming

### SQL Script Files

SQL files follow the pattern:

```
{action}_{layer_or_target}.sql
```

| File | Convention | Description |
|---|---|---|
| `init_database.sql` | `{action}_{target}` | Database initialization |
| `ddl_bronze.sql` | `{type}_{layer}` | DDL for Bronze layer |
| `load_bronze.sql` | `{action}_{layer}` | Load procedure for Bronze layer |
| `ddl_silver.sql` | `{type}_{layer}` | DDL for Silver layer |
| `load_silver.sql` | `{action}_{layer}` | Load procedure for Silver layer |
| `ddl_gold.sql` | `{type}_{layer}` | DDL (views) for Gold layer |

### Quality Check Files

```
quality_checks_{layer}.sql
```

| File | Description |
|---|---|
| `quality_checks_silver.sql` | Silver layer data quality validation |
| `quality_checks_gold.sql` | Gold layer data quality validation |

### Rules

- All lowercase
- `snake_case` with underscores
- No spaces in filenames
- Descriptive and self-documenting
- File extension: `.sql` for SQL, `.md` for Markdown, `.csv` for data

---

## Documentation File Naming

Documentation files use `snake_case` with the `.md` extension:

| File | Purpose |
|---|---|
| `README.md` | Project overview (uppercase per GitHub convention) |
| `data_catalog.md` | Enterprise data catalog |
| `naming_conventions.md` | Naming standards (this document) |

### Image / Diagram Files

Stored in `docs/`. Use `PascalCase` or `snake_case` consistently:

| File | Description |
|---|---|
| `Architecture.png` | High-level system architecture |
| `Data-Flow.png` | Table-level data flow diagram |
| `Data_mart.png` | Star Schema ER diagram |
| `Integration_Model.png` | Cross-system integration model |

> **Note:** Image naming uses the existing convention. For new images, prefer `snake_case` (e.g., `data_flow.png`).

---

## Dataset File Naming

Source data files in `datasets/` retain their original filenames to maintain traceability back to the source system:

| File | Source System | Convention |
|---|---|---|
| `cust_info.csv` | CRM | `snake_case` (CRM convention) |
| `prd_info.csv` | CRM | `snake_case` |
| `sales_details.csv` | CRM | `snake_case` |
| `CUST_AZ12.csv` | ERP | `UPPER_CASE` (ERP convention) |
| `LOC_A101.csv` | ERP | `UPPER_CASE` |
| `PX_CAT_G1V2.csv` | ERP | `UPPER_CASE` |

> **Design Decision:** Source file names are intentionally preserved as-is to reflect realistic enterprise scenarios where different systems export data in different naming formats.

---

## Quick Reference

| Object | Convention | Example |
|---|---|---|
| Schema | `{layer_name}` | `bronze`, `silver`, `gold` |
| Bronze/Silver Table | `{source}_{entity}` | `crm_cust_info`, `erp_loc_a101` |
| Gold Dimension | `dim_{entity}` | `dim_customers`, `dim_products` |
| Gold Fact | `fact_{entity}` | `fact_sales` |
| Surrogate Key | `{entity}_key` | `customer_key`, `product_key` |
| Natural Key | `{prefix}_id` | `cst_id`, `prd_id` |
| Date Column | `{prefix}_{name}_dt` | `sls_order_dt`, `prd_start_dt` |
| Audit Column | `dwh_{action}_date` | `dwh_create_date` |
| Stored Procedure | `{schema}.load_{layer}()` | `bronze.load_bronze()` |
| DDL Script | `ddl_{layer}.sql` | `ddl_bronze.sql` |
| Load Script | `load_{layer}.sql` | `load_silver.sql` |
| Quality Checks | `quality_checks_{layer}.sql` | `quality_checks_gold.sql` |

---

<div align="center">

*Last updated: June 2026*

</div>
