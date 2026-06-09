select * from gold.dim_customers

select distinct gender from gold.dim_customers;

select customer_id,count(*) from gold.dim_customers
group by customer_id
having count(*) > 1;

SELECT product_id, count(*) from gold.dim_products
group by product_id
HAVING count(*) > 1;

select * from gold.fact_sales f
left join gold.dim_customers c
on f.customer_key = c.customer_key
left join gold.dim_products p
on f.product_key = p.product_key
where c.customer_key is null or p.product_number is null;
