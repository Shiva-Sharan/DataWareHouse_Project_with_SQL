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

