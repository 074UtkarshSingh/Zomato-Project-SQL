create database zomato_project;
use zomato_project;

DROP TABLE IF EXISTS goldusers_signup;
CREATE TABLE goldusers_signup(userid INTEGER, gold_signup_date DATE); 

INSERT INTO goldusers_signup(userid, gold_signup_date) 
VALUES (1, '2017-09-22'),
       (3, '2017-04-21');

DROP TABLE IF EXISTS users;
CREATE TABLE users(userid INTEGER, signup_date DATE); 

INSERT INTO users(userid, signup_date) 
VALUES (1, '2014-09-02'),
       (2, '2015-01-15'),
       (3, '2014-04-11');

DROP TABLE IF EXISTS sales;
CREATE TABLE sales(userid INTEGER, created_date DATE, product_id INTEGER); 

INSERT INTO sales(userid, created_date, product_id) 
VALUES (1, '2017-04-19', 2),
       (3, '2019-12-18', 1),
       (2, '2020-07-20', 3),
       (1, '2019-10-23', 2),
       (1, '2018-03-19', 3),
       (3, '2016-12-20', 2),
       (1, '2016-11-09', 1),
       (1, '2016-05-20', 3),
       (2, '2017-09-24', 1),
       (1, '2017-03-11', 2),
       (1, '2016-03-11', 1),
       (3, '2016-11-10', 1),
       (3, '2017-12-07', 2),
       (3, '2016-12-15', 2),
       (2, '2017-11-08', 2),
       (2, '2018-09-10', 3);

DROP TABLE IF EXISTS product;
CREATE TABLE product(product_id INTEGER, product_name TEXT, price INTEGER); 

INSERT INTO product(product_id, product_name, price) 
VALUES (1, 'p1', 980),
       (2, 'p2', 870),
       (3, 'p3', 330);

select*from goldusers_signup;
select*from porduct;
select*from sales;
select*from users;

 -- 1. What is the total amount each customer spent on zomato ? 


select  s.userid, price  from product p inner join sales s on p.product_id= s.product_id
group by userid order by userid;
	
-- 2. How many days has each customer visited zomato ?

select userid, count(distinct created_date)as total_days_visited from sales
group by userid;

-- 3. What was the first product purchased by each customer?

select * from (select *, rank() over(partition by userid order by created_date) as rnk from sales) temp1 
where rnk =1;
    
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select product_id,count(product_id) buy_count from sales 
group by product_id order by buy_count desc limit 1;

select userid,count(product_id) from sales 
where product_id =
(select product_id from sales 
group by product_id order by count(product_id) desc limit 1)
group by userid order by userid;

-- 5. which item was the most popular for each customer?

SELECT * FROM (
SELECT *, RANK () OVER (PARTITION BY userid ORDER BY cnt DESC) rnk FROM
(SELECT userid, product_id, COUNT(product_id) AS cnt FROM sales
GROUP BY userid, product_id) temp1 ) AS temp2
WHERE rnk = 1;

-- 6. which item was purchased first by the customer after they become a member ?

SELECT * from goldusers_signup;

SELECT*FROM
(SELECT c.*, RANK() OVER(PARTITION BY userid ORDER BY created_date) RNK FROM
(SELECT s.userid, s.created_date, s.product_id, g.gold_signup_date FROM sales s INNER JOIN 
goldusers_signup g ON s.userid = g.userid AND s.created_date >= g.gold_signup_date) C) D
WHERE rnk=1;

-- 7. Which item was purchased just before the customer became a member ?

SELECT*FROM
(SELECT c.*, RANK() OVER(PARTITION BY userid ORDER BY created_date DESC) RNK FROM
(SELECT s.userid, s.created_date, s.product_id, g.gold_signup_date FROM sales s INNER JOIN 
goldusers_signup g ON s.userid = g.userid AND s.created_date <= g.gold_signup_date) C) D
WHERE rnk=1;

-- 8. what is the total orders and amount spent for each member before they became a member ?

SELECT userid, COUNT (created_date), SUM(price) FROM
(SELECT c.*, p.price from  
(SELECT s.userid, s.created_date, s.product_id, g.gold_signup_date FROM sales s INNER JOIN 
goldusers_signup g ON s.userid = g.userid AND s.created_date <= g.gold_signup_date) C INNER JOIN product p on p.product_id=c.product_id) D
GROUP BY userid;	

SELECT userid, COUNT(created_date) order_purchased, SUM(price) total_amt_spent
FROM (
    SELECT c.*, p.price
    FROM (
        SELECT s.userid, s.created_date, s.product_id, g.gold_signup_date
        FROM sales s
        INNER JOIN goldusers_signup g ON s.userid = g.userid AND s.created_date <= g.gold_signup_date
    ) c
    INNER JOIN product p ON p.product_id = c.product_id
) d
GROUP BY userid;

-- 9. If buying each product generates points for eg 5rs=2 zomato point and each zomato point has different purchasing points for eg for p1 5rs = 1 zomato point, for p2 10rs = 5 zomato point and p3 5rs = 1 zomato point 
--    calculate points collectes by each customers and for which product most points have been given till now.

-- total points
select userid, sum(points_earned)Total_points_earned from 
(select c.*, total_amt/points as points_earned 
  from (select b.*, case when product_id=1 then 5
				 when product_id=2 then 2
				 when product_id=3 then 5
                 else 0 end as points
  from (select a.userid, a.product_id, sum(price) total_amt
    from (select s.*, p.price 
		   from sales s inner join product p on s.product_id = p.product_id) a
  group by a.userid, a.product_id order by userid) b) c) d
group by userid;

-- total cashback
select userid, sum(points_earned)*2.5 Total_Cashback_earned from 
(select c.*, total_amt/points as points_earned 
  from (select b.*, case when product_id=1 then 5
				 when product_id=2 then 2
				 when product_id=3 then 5
                 else 0 end as points
  from (select a.userid, a.product_id, sum(price) total_amt
    from (select s.*, p.price 
		   from sales s inner join product p on s.product_id = p.product_id) a
  group by a.userid, a.product_id order by userid) b) c) d
group by userid;

select product_id, sum(points_earned) total_points_earned from
(select c.*, total_amt/points as points_earned 
  from (select b.*, case when product_id=1 then 5
				 when product_id=2 then 2
				 when product_id=3 then 5
                 else 0 end as points
  from (select a.userid, a.product_id, sum(price) total_amt
    from (select s.*, p.price 
		   from sales s inner join product p on s.product_id = p.product_id) a
  group by a.userid, a.product_id order by userid) b) c) d
group by product_id order by total_points_earned desc limit 1 ;

-- 10. In the first one year after a customer joins the gold program (including their join date)
--     irrespective of what the customer has purchased they earn 5 zomato points for every 10 rs spent 
--     who earned more  1 or 3 and what was their points earnings in thier first yr?

select userid, sum(cashback) from 
 (select b.*, (price/2) cashback from 
    (select a.*,p.price from product p inner join 
	  (select g.userid,  gold_signup_date, created_date, product_id
        from sales s inner join goldusers_signup g  on g.userid = s.userid and created_date >= gold_signup_date 
		where created_date <= date_add(gold_signup_date, interval 1 year))a
	    on p.product_id = a.product_id) b) c
group by userid order by userid;

-- 11. rank all the transaction of the customers

-- by date
select *, rank() over(partition by userid order by created_date)ranks from sales;

-- by price
select userid, product_id, rank () over (partition by userid order by price) ranks
  from (select userid,s.product_id, price from sales s inner join product p on s. product_id = p. product_id)a ; 
 
 -- 12. rank all the transactions for each member whenever they are a gold member for every non gold member transaction mark as NA

select a.*, case 
	when gold_signup_date is null then "NA"  
    else rank() over(partition by userid order by created_date desc) 
    end ranks
from (SELECT s.userid, s.created_date, s.product_id, g.gold_signup_date FROM sales s LEFT JOIN 
goldusers_signup g ON s.userid = g.userid AND s.created_date >= g.gold_signup_date) a
