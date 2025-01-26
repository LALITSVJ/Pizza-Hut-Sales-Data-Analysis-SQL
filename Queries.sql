create database pizzahut;
use pizzahut;

create table orders(
	order_id int primary key,
    order_date date,
    order_time time
);

create table order_details(
	order_details_id int primary key,
    order_id int,
    pizza_id varchar(50),
    quantity int
);

-- Basic:
-- Retrieve the total number of orders placed.
select count(order_id) as numbers_of_orders_placed 
from orders;

-- Calculate the total revenue generated from pizza sales.
select round(sum(o.quantity*p.price),2) as total_revenue_generated
from order_details o
join pizzas p
on o.pizza_id = p.pizza_id;

-- Identify the highest-priced pizza.
select pt.name, p.price 
from pizzas p
join pizza_types pt
on p.pizza_type_id = pt.pizza_type_id
order by price desc
limit 1;

-- Identify the most common pizza size ordered.
select p.size, count(p.size) as quantity_sold
from order_details o
join pizzas p
on o.pizza_id = p.pizza_id
group by p.size
order by quantity_sold desc;

-- List the top 5 most ordered pizza types along with their quantities.
select p.pizza_type_id, sum(o.quantity) as quantity
from order_details o
join pizzas p
on o.pizza_id = p.pizza_id
group by p.pizza_type_id
order by quantity desc
limit 5;


-- Intermediate:
-- Join the necessary tables to find the total quantity of each pizza category ordered.
select pt.category, sum(o.quantity) as pizza_category_orders
from order_details o
join pizzas p
on o.pizza_id = p.pizza_id
join pizza_types pt
on p.pizza_type_id = pt.pizza_type_id
group by pt.category;

-- Determine the distribution of orders by hour of the day.
select hour(order_time) as hour_of_the_day, count(order_time) as Orders
from orders
group by hour(order_time)
order by hour(order_time);

-- Join relevant tables to find the category-wise distribution of pizzas.
select pt.category, sum(o.quantity) as pizza_category_orders
from order_details o
join pizzas p
on o.pizza_id = p.pizza_id
join pizza_types pt
on p.pizza_type_id = pt.pizza_type_id
group by pt.category;

-- Group the orders by date and calculate the average number of pizzas ordered per day.
select round(avg(total_quantity),0) as avg_pizzas_ordered_per_day
from
	(select o.order_date, sum(od.quantity) as total_quantity
	from orders o
	join order_details od
	on o.order_id = od.order_id
	group by o.order_date) as total_quantity_per_day;


-- Determine the top 3 most ordered pizza types based on revenue.
select p.pizza_type_id, sum(o.quantity * p.price) as revenue
from order_details o
join pizzas p
on o.pizza_id = p.pizza_id
group by p.pizza_type_id
order by revenue desc
limit 3;

select pt.name, sum(o.quantity * p.price) as revenue
from order_details o
join pizzas p
on o.pizza_id = p.pizza_id
join pizza_types pt
on p.pizza_type_id = pt.pizza_type_id
group by pt.name
order by revenue desc
limit 3;

-- Advanced:
-- Calculate the percentage contribution of each pizza type to total revenue.
-- solution: a) using cte,
with total_revenue as (
	select sum(o.quantity * p.price) as total_revenue1
	from order_details o
	join pizzas p
	on o.pizza_id = p.pizza_id)

select 
	pt.category,
	round(sum(o.quantity * p.price),2) as revenue,
	round(SUM(o.quantity * p.price) * 100 / (SELECT total_revenue1 FROM total_revenue),2) 
	AS percentage_revenue
from 
	order_details o
	join pizzas p
	on o.pizza_id = p.pizza_id
	join pizza_types pt
	on p.pizza_type_id = pt.pizza_type_id
	group by pt.category
	order by percentage_revenue desc;

-- b) using subquery
SELECT 
    pt.category,
    SUM(o.quantity * p.price) AS revenue,
    SUM(o.quantity * p.price) * 100 / (SELECT SUM(o1.quantity * p1.price)
        FROM 
			order_details o1
			JOIN pizzas p1
			ON o1.pizza_id = p1.pizza_id) AS percentage_revenue
FROM 
	order_details o
	JOIN pizzas p
	ON o.pizza_id = p.pizza_id
	JOIN pizza_types pt
	ON p.pizza_type_id = pt.pizza_type_id
	GROUP BY pt.category;

-- Analyze the cumulative revenue generated over time.
select 
	order_date, revenue, 
	round(sum(revenue) over (order by order_date),2) as cumulative_revenue
from
	(select o.order_date, round(sum(od.quantity*p.price),2) as revenue
	from orders o
	join order_details od
	on o.order_id = od.order_id
	join pizzas p
	on od.pizza_id = p.pizza_id
	group by o.order_date) as daily_revenue;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
-- select pt.category, sum(od.quantity * p.price) as revenue
select category, name, revenue
from
	(select 
		category, name, revenue,
		rank() over (partition by category order by revenue desc) as most_selling
	from
		(select pt.category, pt.name, round(sum(od.quantity*p.price),2) as revenue
		from order_details od
		join pizzas p
		on od.pizza_id = p.pizza_id
		join pizza_types pt
		on p.pizza_type_id = pt.pizza_type_id
		group by pt.category, pt.name) as category_revenue) as cat_rev_with_rank
where most_selling <=3;

