create view gold.dim_customers as 
select
row_number() over(order by cu.cst_id) as customer_key,
cu.cst_id as customer_id,
cu.cst_key as customer_number,
cu.cst_firstname as first_name,
cu.cst_lastname as last_name,
l.cntry as country,
cu.cst_martial_status as martial_status,
case 
	when cu.cst_gndr != 'n/a' then cu.cst_gndr
	else coalesce(e.gen, 'n/a')
end as gender,
e.bdate as birth_date,
cu.cst_create_date as create_date
from silver.crm_cust_info cu
left join silver.erp_cust_az12 e
on cu.cst_key = e.cid
left join silver.erp_loc_a101 l
on cu.cst_key = l.cid;
