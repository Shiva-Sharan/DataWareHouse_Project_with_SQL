TRUNCATE TABLE silver.crm_cust_info;

INSERT INTO silver.crm_cust_info (
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
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,

    CASE
        WHEN UPPER(TRIM(cst_martial_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_martial_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
    END AS cst_martial_status,

    CASE
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'n/a'
    END AS cst_gndr,

    cst_create_date

FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY cst_id
               ORDER BY cst_create_date DESC
           ) AS flag_test
    FROM bronze.crm_cust_info
    WHERE cst_id IS NOT NULL
) t

WHERE flag_test = 1;

TRUNCATE TABLE silver.crm_prd_info;
INSERT INTO silver.crm_prd_info(
prd_id, 
cat_id, 
prd_key, 
prd_nm, 
prd_cost, 
prd_line,
prd_start_dt, 
prd_end_dt
)

select 
prd_id,
cast(replace(substring(prd_key,1,5),'-','_') as Varchar(50)) as cat_id,
cast(substring(prd_key,7, length(prd_key)) as varchar(50)) as prd_key,
prd_nm, 
coalesce(prd_cost, 0) as prd_cost,
case upper(trim(prd_line))
	when 'M' then 'Mountain'
	when 'R' then 'Road'
	when 'S' then 'Other Sales'
	when 'T' then 'Touring'
	else 'n/a'
end as prd_line,
cast(prd_start_dt as date) as prd_start_dt,
cast(lead(prd_start_dt) over(
partition by prd_key order by prd_start_dt
) - interval '1 day' as date) as prd_end_dt
from bronze.crm_prd_info;



TRUNCATE TABLE silver.crm_sales_details;

INSERT INTO silver.crm_sales_details (
    sls_ord_num          ,
    sls_prd_key          ,
    sls_cust_id          ,
    sls_order_dt         ,
    sls_ship_dt          ,
    sls_due_dt           ,
    sls_sales            ,
    sls_quantity         ,
    sls_price                  
)

select 
sls_ord_num, 
sls_prd_key,
sls_cust_id,
case 
	when sls_order_dt = 0 or char_length(sls_order_dt:: text) != 8 then NULL
	else cast(cast(sls_order_dt as varchar) as date) 
end as sls_order_dt,
case 
	when sls_ship_dt = 0 or char_length(sls_ship_dt:: text) != 8 then NULL
	else cast(cast(sls_ship_dt as varchar) as date) 
end as sls_ship_dt,
case 
	when sls_due_dt = 0 or char_length(sls_due_dt:: text) != 8 then NULL
	else cast(cast(sls_due_dt as varchar) as date) 
end as sls_due_dt,
case 
	when sls_sales is null 
	or sls_sales <=0 
	or sls_sales = sls_quantity * abs(sls_price)
	then sls_quantity * abs(sls_price)
	else sls_sales
end	as sls_sales, 
sls_quantity, 
case 
	when sls_price is null
	or sls_price <= 0 
	then sls_sales / nullif(sls_quantity,0)
	else sls_price
end as sls_price 
from bronze.crm_sales_details
