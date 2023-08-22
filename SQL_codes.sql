##########################
#Q1
##########################

SELECT market FROM gdb023.dim_customer
where customer = "Atliq Exclusive" and region="APAC";

########################
#Q2
########################
WITH ProductCounts AS (
    SELECT
        fiscal_year,
        COUNT(DISTINCT product_code) AS unique_products
    FROM
        gdb023.fact_sales_monthly
    GROUP BY
        fiscal_year
)

SELECT
    p2020.unique_products AS unique_products_2020,
    p2021.unique_products AS unique_products_2021,
    CASE
        WHEN p2020.unique_products = 0 THEN NULL
        ELSE ((p2021.unique_products - p2020.unique_products) / p2020.unique_products) * 100
    END AS percentage_chg
FROM
    ProductCounts p2020
JOIN
    ProductCounts p2021 ON p2020.fiscal_year = 2020 AND p2021.fiscal_year = 2021;

##########################
#Q3
##########################

SELECT segment,count(distinct product_code) as product_count FROM gdb023.dim_product
group by segment
order by product_count desc;

##########################
#Q4
##########################

with c2020 as (
    SELECT dp.segment, COUNT(DISTINCT fs.product_code) AS count2020
FROM fact_sales_monthly fs
JOIN dim_product dp ON fs.product_code = dp.product_code
WHERE fs.fiscal_year = 2020
GROUP BY dp.segment
),
c2021 as (
   SELECT dp.segment, COUNT(DISTINCT fs.product_code) AS count2021
FROM fact_sales_monthly fs
JOIN dim_product dp ON fs.product_code = dp.product_code
WHERE fs.fiscal_year = 2021
GROUP BY dp.segment
)
select c.segment,c.count2020, d.count2021, (d.count2021 - c.count2020) as difference
from c2020 c
join c2021 d
on c.segment=d.segment
group by c.segment
order by difference desc;

##########################
#Q5
##########################

SELECT p.product_code, p.product, m.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost m ON p.product_code = m.product_code
where m.manufacturing_cost in (select min(manufacturing_cost) from fact_manufacturing_cost
union
select max(manufacturing_cost) from fact_manufacturing_cost);

##########################
#Q6
##########################

SELECT fd.customer_code,dc.customer,avg(fd.pre_invoice_discount_pct) as avg_preinv
FROM gdb023.fact_pre_invoice_deductions fd 
join dim_customer dc on
fd.customer_code=dc.customer_code
where fd.fiscal_year=2021 and dc.market="India" 
group by fd.customer_code,dc.customer
order by avg_preinv desc
limit 5;

##########################
#Q7
##########################

SELECT
    year(fm.date) as calender_year,
    CONCAT(MONTHNAME(fm.date), ' (', YEAR(fm.date), ')') AS 'month_m',
    round(SUM(fm.sold_quantity * fg.gross_price),2) AS total_gross_sales
FROM gdb023.fact_sales_monthly fm
JOIN fact_gross_price fg ON fm.product_code = fg.product_code
join dim_customer ds on
ds.customer_code=fm.customer_code
where ds.customer="Atliq Exclusive"
GROUP BY
    month_m,
    fm.date
order by fm.date,month_m;

##########################
#Q8
##########################

WITH cte1 AS (
    SELECT *,
        CASE
            WHEN MONTH(date) in (9,10,11) then CONCAT('Q1')
            WHEN MONTH(date)in (12,1,2) then CONCAT('Q2')
            WHEN MONTH(date) in (3,4,5) then  CONCAT('Q3')
            ELSE CONCAT('Q4')
        END AS fiscal_quarter
    FROM fact_sales_monthly
)

SELECT fiscal_quarter, SUM(sold_quantity) / 1000000 AS total_sold_quantity_in_millions
FROM cte1
WHERE fiscal_year = 2020
GROUP BY fiscal_quarter
ORDER BY total_sold_quantity_in_millions desc;

##########################
#Q9
##########################

with cte1 as (
SELECT
    ds.channel,
    round(SUM(fm.sold_quantity * fg.gross_price)/1000000,2) AS total_gross_sales
FROM gdb023.fact_sales_monthly fm
JOIN fact_gross_price fg ON fm.product_code = fg.product_code
join dim_customer ds on
ds.customer_code=fm.customer_code
where fm.fiscal_year=2021
GROUP BY
    ds.channel)
    
select channel,total_gross_sales,total_gross_sales*100/sum(total_gross_sales) over() as percentage_contro
from cte1
group by channel;

##########################
#Q10
##########################

WITH cte1 AS (
    SELECT
        dp.division,
        dp.product_code,
        dp.product,
        SUM(fs.sold_quantity) AS total_sold_qty
    FROM gdb023.dim_product dp
    JOIN fact_sales_monthly fs ON dp.product_code = fs.product_code
    WHERE fiscal_year = 2021
    GROUP BY dp.division, dp.product_code, dp.product
),
ranked AS (
    SELECT
        division,
        product_code,
        product,
        total_sold_qty,
        DENSE_RANK() OVER (PARTITION BY division ORDER BY total_sold_qty DESC) AS rnk
    FROM cte1
)

SELECT division, product_code, product, total_sold_qty, rnk
FROM ranked
WHERE rnk <= 3;


