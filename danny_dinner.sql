/* 1.	What is the total amount each customer spent at the restaurant? */
select s.customer_id, sum(m.price) as total_amount_spent
from sales s
join menu m using(product_id)
group by 1;

/* 2.	How many days has each customer visited the restaurant? */
select s.customer_id, count(*) as no_of_days
from sales s
group by 1;

/* 3.	What was the first item from the menu purchased by each customer? */
with first_item as (select distinct s.customer_id, s.order_date, m.product_name, 
	dense_rank() over(partition by customer_id order by order_date) as rnk
from sales s
join menu m using(product_id))
select customer_id, product_name as first_order
from first_item
where rnk = 1;

/* 4.	What is the most purchased item on the menu and how many times was it purchased by all customers? */
select customer_id, count(*) as times_purchased
from sales
where product_id = (with item_name as (select s.product_id, count(*) as purchased_items
						from sales s
						join menu m using(product_id)
						group by 1 order by 2 desc limit 1
                        )
						select product_id
						from item_name)
group by 1;

/* 5.	Which item was the most popular for each customer? */
with popular as (select s.customer_id, m.product_name, count(*) as items_ordered
		from sales s 
		join menu m using(product_id)
		group by 1, 2
        )
select customer_id, product_name
from popular
where items_ordered = (select max(items_ordered) from popular);

/* 6.	Which item was purchased first by the customer after they became a member? */
with first_purchase as (
		select s.customer_id, m.join_date, s.order_date, m1.product_name, 
			rank() over(partition by customer_id order by order_date asc) as rnk
		from members m
		left join sales s using(customer_id)
		join menu m1 using(product_id)
		where m.join_date < s.order_date
        )
select customer_id, product_name, join_date, order_date
from first_purchase
where rnk = 1;

/* 7.	Which item was purchased just before the customer became a member? */
with before_member as (
		select s.customer_id, m.join_date, s.order_date, m1.product_name, 
			rank() over(partition by customer_id order by order_date desc) as rnk
		from members m
		left join sales s using(customer_id)
		join menu m1 using(product_id)
		where m.join_date > s.order_date
        )
select customer_id, product_name, join_date, order_date
from before_member
where rnk = 1;

/* 8.	What is the total items and amount spent for each member before they became a member? */
select s.customer_id, count(*) as total_items, sum(price) as amount_spent
from members m
left join sales s using(customer_id)
join menu m1 using(product_id)
where m.join_date > s.order_date
group by 1 order by 1;

/* 9.	If each $1 spent equates to 10 points and sushi has a 
2x points multiplier - how many points would each customer have? */
with customer_points as (
	select *, if(m.product_name = "sushi", m.price * 20, m.price * 10) as points
	from sales s
	join menu m using(product_id)
    )
select customer_id, sum(points) as total_points
from customer_points
group by 1;

/* 10.	In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
not just sushi - how many points do customer A and B have at the end of January? */
with cust_details as (
	select distinct *, datediff(order_date, join_date) as days, (m.price * 20) as points
	from members m1
	left join sales s using(customer_id)
	join menu m using(product_id)
	where m1.join_date <= s.order_date and s.order_date < '2021-01-31'
	order by 2
    )
select customer_id, sum(points) as total_points
from cust_details
where days <= 7
group by 1;