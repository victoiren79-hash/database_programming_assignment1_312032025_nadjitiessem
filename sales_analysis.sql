-- ============================================================
-- Assignment I: CTEs & SQL Window Functions
-- Course: DPR400210 - Database Programming
-- Student: Nadjitiessem Gondje Victoire| ID: 31603/2025
-- Business Scenario: Sales Management System
-- ============================================================

-- ============================================================
-- SECTION 1: DATABASE SCHEMA
-- ============================================================

CREATE TABLE customers (
    customer_id   NUMBER PRIMARY KEY,
    customer_name VARCHAR2(100),
    city          VARCHAR2(50),
    country       VARCHAR2(50)
);

CREATE TABLE products (
    product_id   NUMBER PRIMARY KEY,
    product_name VARCHAR2(100),
    category     VARCHAR2(50),
    price        NUMBER(10,2)
);

CREATE TABLE sales (
    sale_id     NUMBER PRIMARY KEY,
    customer_id NUMBER REFERENCES customers(customer_id),
    product_id  NUMBER REFERENCES products(product_id),
    sale_date   DATE,
    quantity    NUMBER,
    total_amount NUMBER(10,2)
);

-- ============================================================
-- SECTION 2: SAMPLE DATA
-- ============================================================

INSERT INTO customers VALUES (1, 'James Carter',    'Paris',         'France');
INSERT INTO customers VALUES (2, 'Sofia Hernandez', 'Madrid',        'Spain');
INSERT INTO customers VALUES (3, 'Luca Bianchi',    'Milan',         'Italy');
INSERT INTO customers VALUES (4, 'Emma Wilson',     'London',        'UK');
INSERT INTO customers VALUES (5, 'Ahmed Hassan',    'Cairo',         'Egypt');

INSERT INTO products VALUES (1, 'Laptop',     'Electronics', 850.00);
INSERT INTO products VALUES (2, 'Phone',      'Electronics', 450.00);
INSERT INTO products VALUES (3, 'Desk',       'Furniture',   200.00);
INSERT INTO products VALUES (4, 'Chair',      'Furniture',   150.00);
INSERT INTO products VALUES (5, 'Headphones', 'Electronics', 100.00);

INSERT INTO sales VALUES (1,  1, 1, DATE '2026-01-15', 2, 1700.00);
INSERT INTO sales VALUES (2,  2, 2, DATE '2026-01-20', 1,  450.00);
INSERT INTO sales VALUES (3,  3, 3, DATE '2026-02-05', 3,  600.00);
INSERT INTO sales VALUES (4,  1, 5, DATE '2026-02-10', 4,  400.00);
INSERT INTO sales VALUES (5,  4, 2, DATE '2026-03-01', 2,  900.00);
INSERT INTO sales VALUES (6,  5, 1, DATE '2026-03-15', 1,  850.00);
INSERT INTO sales VALUES (7,  2, 4, DATE '2026-04-01', 5,  750.00);
INSERT INTO sales VALUES (8,  3, 5, DATE '2026-04-10', 2,  200.00);
INSERT INTO sales VALUES (9,  4, 3, DATE '2026-05-01', 1,  200.00);
INSERT INTO sales VALUES (10, 5, 4, DATE '2026-05-20', 3,  450.00);

COMMIT;

-- ============================================================
-- SECTION 3: COMMON TABLE EXPRESSIONS (CTEs)
-- ============================================================

-- CTE 1: Simple CTE
-- Business value: Identify top customers by total spending
WITH customer_spending AS (
    SELECT c.customer_name,
           SUM(s.total_amount) AS total_spent
    FROM customers c
    JOIN sales s ON c.customer_id = s.customer_id
    GROUP BY c.customer_name
)
SELECT customer_name, total_spent
FROM customer_spending
ORDER BY total_spent DESC;

-- CTE 2: Multiple CTEs
-- Business value: Compare customer spending vs product category revenue
WITH customer_spending AS (
    SELECT c.customer_name,
           SUM(s.total_amount) AS total_spent
    FROM customers c
    JOIN sales s ON c.customer_id = s.customer_id
    GROUP BY c.customer_name
),
category_revenue AS (
    SELECT p.category,
           SUM(s.total_amount) AS category_total
    FROM products p
    JOIN sales s ON p.product_id = s.product_id
    GROUP BY p.category
)
SELECT cs.customer_name, cs.total_spent, cr.category, cr.category_total
FROM customer_spending cs
CROSS JOIN category_revenue cr
ORDER BY cs.total_spent DESC, cr.category_total DESC;

-- CTE 3: Recursive CTE
-- Business value: Traverse a chain of sales records sequentially
WITH RECURSIVE_SALES (sale_id, customer_id, total_amount, lvl) AS (
    SELECT sale_id, customer_id, total_amount, 1
    FROM sales
    WHERE sale_id = 1
    UNION ALL
    SELECT s.sale_id, s.customer_id, s.total_amount, r.lvl + 1
    FROM sales s
    JOIN RECURSIVE_SALES r ON s.sale_id = r.sale_id + 1
    WHERE r.lvl < 5
)
SELECT sale_id, customer_id, total_amount, lvl AS lvl_level
FROM RECURSIVE_SALES;

-- CTE 4: CTE with Aggregation
-- Business value: Monthly sales revenue summary for trend analysis
WITH monthly_revenue AS (
    SELECT TO_CHAR(sale_date, 'YYYY-MM') AS sale_month,
           SUM(total_amount)             AS monthly_total,
           COUNT(*)                      AS num_sales,
           AVG(total_amount)             AS avg_sale
    FROM sales
    GROUP BY TO_CHAR(sale_date, 'YYYY-MM')
)
SELECT sale_month, monthly_total, num_sales, ROUND(avg_sale, 2) AS avg_sale
FROM monthly_revenue
ORDER BY sale_month;

-- CTE 5: CTE with JOIN
-- Business value: Identify best-performing products by revenue and customer reach
WITH product_sales AS (
    SELECT p.product_name,
           p.category,
           COUNT(DISTINCT s.customer_id) AS num_customers,
           SUM(s.total_amount)           AS total_revenue
    FROM products p
    JOIN sales s ON p.product_id = s.product_id
    GROUP BY p.product_name, p.category
)
SELECT product_name, category, num_customers, total_revenue
FROM product_sales
ORDER BY total_revenue DESC;

-- ============================================================
-- SECTION 4: WINDOW FUNCTIONS
-- ============================================================

-- 4.1 Ranking Functions: ROW_NUMBER, RANK, DENSE_RANK, PERCENT_RANK
-- Business value: Rank sales transactions by amount to identify top deals
SELECT s.sale_id,
       c.customer_name,
       s.total_amount,
       ROW_NUMBER()   OVER (ORDER BY s.total_amount DESC)        AS row_num,
       RANK()         OVER (ORDER BY s.total_amount DESC)        AS rank_num,
       DENSE_RANK()   OVER (ORDER BY s.total_amount DESC)        AS dense_rank_num,
       ROUND(PERCENT_RANK() OVER (ORDER BY s.total_amount DESC), 2) AS pct_rank
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
ORDER BY s.total_amount DESC;

-- 4.2 Aggregate Window Functions: SUM, AVG, MIN, MAX OVER
-- Business value: Compare each sale against overall revenue benchmarks
SELECT c.customer_name,
       s.total_amount,
       SUM(s.total_amount)          OVER () AS total_revenue,
       ROUND(AVG(s.total_amount)    OVER (), 2) AS avg_revenue,
       MIN(s.total_amount)          OVER () AS min_sale,
       MAX(s.total_amount)          OVER () AS max_sale
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
ORDER BY s.total_amount DESC;

-- 4.3 Navigation Functions: LAG and LEAD
-- Business value: Track sales momentum by comparing each sale to previous and next
SELECT c.customer_name,
       s.sale_date,
       s.total_amount,
       LAG(s.total_amount)  OVER (ORDER BY s.sale_date) AS prev_sale,
       LEAD(s.total_amount) OVER (ORDER BY s.sale_date) AS next_sale
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
ORDER BY s.sale_date;

-- 4.4 Distribution Functions: NTILE and CUME_DIST
-- Business value: Segment customers into performance quartiles
SELECT c.customer_name,
       s.total_amount,
       NTILE(4)     OVER (ORDER BY s.total_amount DESC)        AS quartile,
       ROUND(CUME_DIST() OVER (ORDER BY s.total_amount DESC), 2) AS cume_dist
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
ORDER BY s.total_amount DESC;
