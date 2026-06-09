select * from gold.dim_customers

select distinct gender from gold.dim_customers;

select customer_id,count(*) from gold.dim_customers
group by customer_id
having count(*) > 1;

SELECT product_id, count(*) from gold.dim_products
group by product_id
HAVING count(*) > 1;

