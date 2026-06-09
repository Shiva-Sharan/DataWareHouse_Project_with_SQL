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

create view gold.dim_products as 
select 
row_number() over(order by p.prd_start_dt, p.prd_key) as product_key,
p.prd_id as product_id,
p.prd_key as product_number,
p.prd_nm as product_name,
p.cat_id as category_id,
pc.cat as category,
pc.subcat as sub_category,
pc.maintenance ,
p.prd_cost as cost,
p.prd_line as product_line,
p.prd_start_dt as start_date
from silver.crm_prd_info p
left join silver.erp_px_cat_g1v2 pc
on p.cat_id = pc.id
where p.prd_end_dt is null
