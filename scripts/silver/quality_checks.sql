select cst_id, count(*) from 
silver.crm_cust_info
group by cst_id
having count(*) > 1 or cst_id is null;

select *, length(cst_firstname), length(trim(cst_firstname)) 
from silver.crm_cust_info
where crm_cust_info.cst_firstname != trim(cst_firstname);

select *, length(cst_lastname), length(trim(cst_lastname)) 
from silver.crm_cust_info
where crm_cust_info.cst_lastname != trim(cst_lastname);

select distinct cst_martial_status 
from silver.crm_cust_info

select prd_id, count(*) from 
silver.crm_prd_info
group by prd_id
having count(*) > 1 or prd_id is null;

select prd_nm 
from silver.crm_prd_info
where prd_nm != trim(prd_nm);

select coalesce(prd_cost,0) from silver.crm_prd_info
where prd_cost < 0 or prd_cost is null;

select distinct prd_line
from silver.crm_prd_info;

select * from silver.crm_prd_info
where prd_end_dt < prd_start_dt ;

select prd_id,
prd_key,
prd_nm,
prd_start_dt,
lead(prd_start_dt) 
over(partition by prd_key 
order by prd_start_dt) - interval '1 day' as prd_end_dt,
prd_end_dt
from silver.crm_prd_info;

select 
sls_order_dt
from SILVER.crm_sales_details
where sls_order_dt <= 0 or char_length(sls_order_dt:: text) != 8 
or sls_order_dt > 20500101 or sls_order_dt < 19000101

select 
nullif(sls_ship_dt,0) as sls_ship_dt
from SILVER.crm_sales_details
where sls_ship_dt <= 0 or char_length(sls_ship_dt:: text) != 8 
or sls_ship_dt > 20500101 or sls_ship_dt < 19000101


select 
nullif(sls_due_dt,0) as sls_due_dt
from SILVER.crm_sales_details
where sls_due_dt <= 0 or char_length(sls_due_dt:: text) != 8 
or sls_due_dt > 20500101 or sls_due_dt < 19000101

select * 
from SILVER.crm_sales_details
where sls_ship_dt < sls_order_dt or sls_order_dt > sls_due_dt

select sls_sales, sls_quantity, sls_price 
from SILVER.crm_sales_details
where sls_sales != sls_quantity * sls_price 
or sls_sales is null or sls_quantity is null or sls_price is null
or sls_sales <= 0 or sls_quantity <=0 or sls_price <= 0
order by sls_sales, sls_quantity, sls_price 

select * from (select 
case 
	when cid like 'NAS%' then substring(cid, 4, length(cid)) 
	else cid 
end as cid,
bdate,
gen
from silver.erp_cust_az12
)t 
where cid not in (select cst_key from silver.crm_cust_info);

select distinct bdate
from silver.erp_cust_az12
where  bdate > '2020-01-01';
