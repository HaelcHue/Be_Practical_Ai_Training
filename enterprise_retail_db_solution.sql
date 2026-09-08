/*
===============================================================================
STUDENT GRADED PORTFOLIO LAB
20 ADVANCED SQL INTERVIEW PROBLEMS
DATABASE: enterprise_retail_db
===============================================================================


===============================================================================

USE enterprise_retail_db;


/*
===============================================================================
PART A: JOINS, ADVANCED FILTERING & SUBQUERIES
Q1 - Q5
===============================================================================
*/


/*
===============================================================================
Q1
Find all customers from USA who placed completed orders in Q1 2024
(Jan-Mar).

Return:
    customer_name
    order_id
    order_date
    order net revenue
===============================================================================
*/

SELECT
    c.customer_name,
    o.order_id,
    o.order_date,
    ROUND(
        SUM(
            oi.quantity
            * oi.unit_price
            * (1 - oi.discount_pct)
        ),
        2
    ) AS order_net_revenue

FROM customers AS c

JOIN orders AS o
    ON c.customer_id = o.customer_id

JOIN order_items AS oi
    ON o.order_id = oi.order_id

WHERE c.country = 'USA'
  AND o.order_status = 'Completed'
  AND o.order_date BETWEEN '2024-01-01' AND '2024-03-31'

GROUP BY
    c.customer_name,
    o.order_id,
    o.order_date

ORDER BY
    o.order_date ASC,
    o.order_id ASC;


/*
===============================================================================
Q2
Identify all sales reps (department_id = 2) who have NEVER closed an order.

"Closed" is interpreted as a completed order.

Use an ANTI-JOIN pattern:
    LEFT JOIN + IS NULL
===============================================================================
*/

SELECT
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS sales_rep_name,
    e.email

FROM employees AS e

LEFT JOIN orders AS o
    ON e.employee_id = o.sales_rep_id
   AND o.order_status = 'Completed'

WHERE e.department_id = 2
  AND o.order_id IS NULL

ORDER BY
    e.employee_id;


/*
===============================================================================
Q3
List all products that have NEVER been ordered in the entire history
of the company.
===============================================================================
*/

SELECT
    p.product_id,
    p.product_name,
    p.unit_price

FROM products AS p

LEFT JOIN order_items AS oi
    ON p.product_id = oi.product_id

WHERE oi.product_id IS NULL

ORDER BY
    p.product_id;


/*
===============================================================================
Q4
Find all employees whose salary is strictly higher than the average salary
of their department.

Return:
    employee name
    department name
    salary
    department average salary
===============================================================================
*/

WITH department_avg AS
(
    SELECT
        department_id,
        AVG(salary) AS department_avg_salary
    FROM employees
    GROUP BY department_id
)

SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.department_name,
    e.salary,
    ROUND(da.department_avg_salary, 2) AS department_avg_salary

FROM employees AS e

JOIN departments AS d
    ON e.department_id = d.department_id

JOIN department_avg AS da
    ON e.department_id = da.department_id

WHERE e.salary > da.department_avg_salary

ORDER BY
    d.department_name,
    e.salary DESC;


/*
===============================================================================
Q5
Find all customer segments where total net revenue exceeds $30,000
across completed orders.

Return:
    segment
    total orders count
    net revenue

Sort descending by net revenue.
===============================================================================
*/

SELECT
    c.segment,
    COUNT(DISTINCT o.order_id) AS total_orders_count,

    ROUND(
        SUM(
            oi.quantity
            * oi.unit_price
            * (1 - oi.discount_pct)
        ),
        2
    ) AS net_revenue

FROM customers AS c

JOIN orders AS o
    ON c.customer_id = o.customer_id

JOIN order_items AS oi
    ON o.order_id = oi.order_id

WHERE o.order_status = 'Completed'

GROUP BY
    c.segment

HAVING
    SUM(
        oi.quantity
        * oi.unit_price
        * (1 - oi.discount_pct)
    ) > 30000

ORDER BY
    net_revenue DESC;


/*
===============================================================================
PART B: COMMON TABLE EXPRESSIONS (CTEs) & COMPLEX LOGIC
Q6 - Q8
===============================================================================
*/


/*
===============================================================================
Q6
Using a CTE, calculate Total Spend per customer.

Classify:
    >= 20,000       -> High Spender
    >= 5,000        -> Mid Spender
    < 5,000         -> Low Spender

Then count customers in each bracket.
===============================================================================
*/

WITH customer_spend AS
(
    SELECT
        c.customer_id,
        c.customer_name,

        COALESCE(
            SUM(
                CASE
                    WHEN o.order_status = 'Completed'
                    THEN oi.quantity
                         * oi.unit_price
                         * (1 - oi.discount_pct)
                    ELSE 0
                END
            ),
            0
        ) AS total_spend

    FROM customers AS c

    LEFT JOIN orders AS o
        ON c.customer_id = o.customer_id

    LEFT JOIN order_items AS oi
        ON o.order_id = oi.order_id

    GROUP BY
        c.customer_id,
        c.customer_name
),

spend_classification AS
(
    SELECT
        customer_id,
        customer_name,
        total_spend,

        CASE
            WHEN total_spend >= 20000
                THEN 'High Spender'

            WHEN total_spend >= 5000
                THEN 'Mid Spender'

            ELSE 'Low Spender'
        END AS spender_bracket

    FROM customer_spend
)

SELECT
    spender_bracket,
    COUNT(*) AS customer_count

FROM spend_classification

GROUP BY
    spender_bracket

ORDER BY
    CASE spender_bracket
        WHEN 'High Spender' THEN 1
        WHEN 'Mid Spender' THEN 2
        WHEN 'Low Spender' THEN 3
    END;


/*
===============================================================================
Q7
Find customers who placed MORE THAN ONE completed order.

Return:
    customer_id
    customer_name
    first order date
    most recent order date
===============================================================================
*/

SELECT
    c.customer_id,
    c.customer_name,

    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS most_recent_order_date

FROM customers AS c

JOIN orders AS o
    ON c.customer_id = o.customer_id

WHERE o.order_status = 'Completed'

GROUP BY
    c.customer_id,
    c.customer_name

HAVING COUNT(DISTINCT o.order_id) > 1

ORDER BY
    c.customer_id;


/*
===============================================================================
Q8
Using a RECURSIVE CTE:

Generate dates:
    2024-01-01 through 2024-01-10

Then count how many orders were placed on each day.

IMPORTANT:
Days with ZERO orders must also appear.
===============================================================================
*/

WITH RECURSIVE date_series AS
(
    SELECT
        DATE('2024-01-01') AS calendar_date

    UNION ALL

    SELECT
        DATE_ADD(calendar_date, INTERVAL 1 DAY)

    FROM date_series

    WHERE calendar_date < '2024-01-10'
)

SELECT
    ds.calendar_date,
    COUNT(o.order_id) AS order_count

FROM date_series AS ds

LEFT JOIN orders AS o
    ON o.order_date = ds.calendar_date

GROUP BY
    ds.calendar_date

ORDER BY
    ds.calendar_date;


/*
===============================================================================
PART C: RANKING WINDOW FUNCTIONS
Q9 - Q12
===============================================================================
*/


/*
===============================================================================
Q9
Find the highest-paid employee in EACH department.

Do NOT use GROUP BY or subquery filters.

Use DENSE_RANK() in a CTE.
===============================================================================
*/

WITH ranked_employees AS
(
    SELECT
        e.employee_id,
        CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
        d.department_name,
        e.salary,

        DENSE_RANK() OVER
        (
            PARTITION BY e.department_id
            ORDER BY e.salary DESC
        ) AS salary_rank

    FROM employees AS e

    JOIN departments AS d
        ON e.department_id = d.department_id
)

SELECT
    employee_id,
    employee_name,
    department_name,
    salary

FROM ranked_employees

WHERE salary_rank = 1

ORDER BY
    department_name;


/*
===============================================================================
Q10
Deduplication simulation.

If duplicate orders existed, pick ONLY the earliest order per customer.

Use ROW_NUMBER():
    PARTITION BY customer_id
    ORDER BY order_date ASC
===============================================================================
*/

WITH ranked_orders AS
(
    SELECT
        order_id,
        customer_id,
        order_date,
        ship_mode,
        order_status,

        ROW_NUMBER() OVER
        (
            PARTITION BY customer_id
            ORDER BY order_date ASC, order_id ASC
        ) AS row_num

    FROM orders
)

SELECT
    order_id,
    customer_id,
    order_date,
    ship_mode,
    order_status

FROM ranked_orders

WHERE row_num = 1

ORDER BY
    customer_id;


/*
===============================================================================
Q11
Divide all products into 4 equal price quartiles using NTILE(4).

    1 = lowest price
    4 = highest price
===============================================================================
*/

SELECT
    product_name,
    unit_price,

    NTILE(4) OVER
    (
        ORDER BY unit_price ASC
    ) AS price_quartile

FROM products

ORDER BY
    unit_price ASC;


/*
===============================================================================
Q12
Rank products by unit_price WITHIN their category.

Show BOTH:
    RANK()
    DENSE_RANK()

This demonstrates how ties are treated.
===============================================================================
*/

SELECT
    p.product_name,
    c.category_name,
    p.unit_price,

    RANK() OVER
    (
        PARTITION BY p.category_id
        ORDER BY p.unit_price DESC
    ) AS price_rank,

    DENSE_RANK() OVER
    (
        PARTITION BY p.category_id
        ORDER BY p.unit_price DESC
    ) AS dense_price_rank

FROM products AS p

JOIN categories AS c
    ON p.category_id = c.category_id

ORDER BY
    c.category_name,
    p.unit_price DESC;


/*
===============================================================================
RANK VS DENSE_RANK

Suppose prices are:

    100
    100
    90

RANK():

    1
    1
    3

DENSE_RANK():

    1
    1
    2

RANK skips a number after a tie.
DENSE_RANK does not.
===============================================================================
*/


/*
===============================================================================
PART D: OFFSET FUNCTIONS
LAG & LEAD
Q13 - Q15
===============================================================================
*/


/*
===============================================================================
Q13
Calculate total net revenue for each calendar month.

Then use LAG() to find:

    previous month's revenue
    MoM dollar growth
===============================================================================
*/

WITH monthly_revenue AS
(
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS month_start,

        ROUND(
            SUM(
                oi.quantity
                * oi.unit_price
                * (1 - oi.discount_pct)
            ),
            2
        ) AS monthly_net_revenue

    FROM orders AS o

    JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        DATE_FORMAT(o.order_date, '%Y-%m-01')
),

revenue_with_previous AS
(
    SELECT
        month_start,
        monthly_net_revenue,

        LAG(monthly_net_revenue) OVER
        (
            ORDER BY month_start
        ) AS previous_month_revenue

    FROM monthly_revenue
)

SELECT
    month_start,
    monthly_net_revenue,
    previous_month_revenue,

    ROUND(
        monthly_net_revenue
        - COALESCE(previous_month_revenue, 0),
        2
    ) AS mom_dollar_growth

FROM revenue_with_previous

ORDER BY
    month_start;


/*
===============================================================================
Q14
For each customer, list all their orders chronologically.

Use LAG() to calculate the number of days since their previous order.
===============================================================================
*/

WITH customer_orders AS
(
    SELECT
        customer_id,
        order_id,
        order_date,

        LAG(order_date) OVER
        (
            PARTITION BY customer_id
            ORDER BY order_date, order_id
        ) AS previous_order_date

    FROM orders
)

SELECT
    customer_id,
    order_id,
    order_date,
    previous_order_date,

    DATEDIFF(
        order_date,
        previous_order_date
    ) AS days_since_previous_order

FROM customer_orders

ORDER BY
    customer_id,
    order_date;


/*
===============================================================================
Q15
For each order, show:

    current order date
    customer_id
    next order date for that customer

Use LEAD().
===============================================================================
*/

SELECT
    customer_id,
    order_id,
    order_date,

    LEAD(order_date) OVER
    (
        PARTITION BY customer_id
        ORDER BY order_date, order_id
    ) AS next_order_date

FROM orders

ORDER BY
    customer_id,
    order_date;


/*
===============================================================================
PART E: AGGREGATE WINDOW FUNCTIONS & FRAMES
Q16 - Q20
===============================================================================
*/


/*
===============================================================================
Q16
Calculate a running cumulative total of net revenue.

Use completed orders and order_date chronologically.
===============================================================================
*/

WITH order_revenue AS
(
    SELECT
        o.order_id,
        o.order_date,

        ROUND(
            SUM(
                oi.quantity
                * oi.unit_price
                * (1 - oi.discount_pct)
            ),
            2
        ) AS order_net_revenue

    FROM orders AS o

    JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        o.order_id,
        o.order_date
)

SELECT
    order_id,
    order_date,
    order_net_revenue,

    ROUND(
        SUM(order_net_revenue) OVER
        (
            ORDER BY order_date, order_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS running_total_revenue

FROM order_revenue

ORDER BY
    order_date,
    order_id;


/*
===============================================================================
Q17
For each order date:

    1. Calculate daily revenue.
    2. Calculate a 3-row moving average.

The required window frame is:

    ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
===============================================================================
*/

WITH daily_revenue AS
(
    SELECT
        o.order_date,

        ROUND(
            SUM(
                oi.quantity
                * oi.unit_price
                * (1 - oi.discount_pct)
            ),
            2
        ) AS daily_net_revenue

    FROM orders AS o

    JOIN order_items AS oi
        ON o.order_id = oi.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        o.order_date
)

SELECT
    order_date,
    daily_net_revenue,

    ROUND(
        AVG(daily_net_revenue) OVER
        (
            ORDER BY order_date
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_3_rows

FROM daily_revenue

ORDER BY
    order_date;


/*
IMPORTANT:

"ROWS BETWEEN 2 PRECEDING AND CURRENT ROW"

means:

    current row
    + previous row
    + row before previous row

It means THREE ROWS.

It does NOT necessarily mean three calendar days if some dates have no orders.
*/


/*
===============================================================================
Q18
For each product sold in completed orders:

    product_name
    category_name
    product revenue
    percentage of its category's total revenue

Use a window function.
===============================================================================
*/

WITH product_revenue AS
(
    SELECT
        p.product_id,
        p.product_name,
        c.category_id,
        c.category_name,

        ROUND(
            SUM(
                oi.quantity
                * oi.unit_price
                * (1 - oi.discount_pct)
            ),
            2
        ) AS product_revenue

    FROM products AS p

    JOIN categories AS c
        ON p.category_id = c.category_id

    JOIN order_items AS oi
        ON p.product_id = oi.product_id

    JOIN orders AS o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'Completed'

    GROUP BY
        p.product_id,
        p.product_name,
        c.category_id,
        c.category_name
)

SELECT
    product_name,
    category_name,
    product_revenue,

    ROUND(
        product_revenue
        / SUM(product_revenue) OVER
          (
              PARTITION BY category_id
          )
        * 100,
        2
    ) AS category_revenue_percentage

FROM product_revenue

ORDER BY
    category_name,
    product_revenue DESC;


/*
===============================================================================
Q19
For every employee, calculate:

    employee salary
    highest salary in their department
    difference between their salary and that highest salary

Use:

    MAX() OVER (PARTITION BY ...)
===============================================================================
*/

SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.department_name,
    e.salary,

    MAX(e.salary) OVER
    (
        PARTITION BY e.department_id
    ) AS department_highest_salary,

    MAX(e.salary) OVER
    (
        PARTITION BY e.department_id
    ) - e.salary AS difference_from_department_max

FROM employees AS e

JOIN departments AS d
    ON e.department_id = d.department_id

ORDER BY
    d.department_name,
    e.salary DESC;


/*
===============================================================================
Q20
Executive Retention Challenge:

Identify customers who placed orders in TWO CONSECUTIVE MONTHS in 2024.

Return:

    distinct customer_id
    customer_name
===============================================================================
*/

WITH customer_months AS
(
    SELECT DISTINCT
        customer_id,
        EXTRACT(YEAR FROM order_date) AS order_year,
        EXTRACT(MONTH FROM order_date) AS order_month

    FROM orders

    WHERE order_date >= '2024-01-01'
      AND order_date < '2025-01-01'
),

consecutive_customers AS
(
    SELECT DISTINCT
        cm1.customer_id

    FROM customer_months AS cm1

    JOIN customer_months AS cm2
        ON cm1.customer_id = cm2.customer_id

       AND (
            (
                cm2.order_year = cm1.order_year
                AND cm2.order_month = cm1.order_month + 1
            )
            OR
            (
                cm1.order_month = 12
                AND cm2.order_year = cm1.order_year + 1
                AND cm2.order_month = 1
            )
       )
)

SELECT DISTINCT
    c.customer_id,
    c.customer_name

FROM customers AS c

JOIN consecutive_customers AS cc
    ON c.customer_id = cc.customer_id

ORDER BY
    c.customer_id;
