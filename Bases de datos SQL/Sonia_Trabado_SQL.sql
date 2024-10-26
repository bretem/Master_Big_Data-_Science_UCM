
## EJERCICIO 1. MODELO FÍSICO
CREATE SCHEMA IF NOT EXISTS `prestamos_2015`;
USE `prestamos_2015`;

CREATE TABLE IF NOT EXISTS `prestamos_2015`.`merchants` (
  `merchant_id` VARCHAR(50) NOT NULL,
  `name` VARCHAR(20) NOT NULL,
  PRIMARY KEY (`merchant_id`));

CREATE TABLE IF NOT EXISTS `prestamos_2015`.`refunds` (
  `order_id` VARCHAR(50) NOT NULL,
  `refunded_at` DATETIME NOT NULL,
  `amount` DECIMAL NOT NULL,
  PRIMARY KEY (`order_id`, `refunded_at`));

CREATE TABLE IF NOT EXISTS `prestamos_2015`.`orders` (
  `order_id` VARCHAR(50) NOT NULL,
  `created_at` DATETIME NOT NULL,
  `status` VARCHAR(20) NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `merchant_id` VARCHAR(50) NOT NULL,
  `country` VARCHAR(30) NOT NULL,
  PRIMARY KEY (`order_id`));
 
 # EJERCICIOS 2
 DELETE FROM merchants WHERE name=”name”;
 
# QUERY 1
SELECT country, status, COUNT(*) AS total_operaciones, ROUND(AVG(amount), 2) AS importe_promedio
FROM orders
WHERE created_at > '2015-07-01' AND country IN ('Francia', 'Portugal', 'España') AND amount > 100 AND amount < 1500
GROUP BY country,
 status
ORDER BY
    importe_promedio DESC;
    
# QUERY 2
SELECT country,
       COUNT(*) AS total_operaciones,
       SUM(amount) AS total_valor_operaciones,
       MAX(amount) AS operacion_valor_maximo,
       MIN(amount) AS operacion_valor_minimo
FROM orders
WHERE status NOT IN ('Delinquent', 'Cancelled') AND amount > 100
GROUP BY country
ORDER BY total_operaciones DESC
LIMIT 3;

#EJERCICIO 3
# QUERY 1
SELECT orders.country, merchants.merchant_id, merchants.name, COUNT(orders.order_id) AS total_operaciones, ROUND(AVG(orders.amount), 2) AS valor_promedio, 
CASE
    WHEN SUM(CASE WHEN refunds.amount IS NOT NULL THEN 1 ELSE 0 END) > 0 THEN 'Si'
    ELSE 'No'
END AS acepta_devoluciones,
COUNT(DISTINCT refunds.order_id) AS total_devoluciones
FROM orders
JOIN merchants ON orders.merchant_id = merchants.merchant_id
LEFT JOIN refunds ON orders.order_id = refunds.order_id
WHERE orders.amount > 0 AND orders.country IN ('Marruecos', 'Italia', 'España', 'Portugal')
GROUP BY orders.country, merchants.merchant_id, merchants.name
HAVING COUNT(orders.order_id) > 10
ORDER BY total_operaciones ASC;
 
 #QUERY 2

 SELECT *
FROM merchants
JOIN orders ON merchants.merchant_id = orders.merchant_id;
SELECT order_id, COUNT(*) AS conteo_devoluciones, SUM(amount) AS suma_devoluciones
FROM refunds
GROUP BY order_id;
########################################
CREATE VIEW orders_view AS
SELECT r.order_id, 
       COUNT(*) AS conteo_devoluciones, 
       SUM(r.amount) AS suma_devoluciones
FROM refunds r
GROUP BY r.order_id;
###################################
# Ejercidio 4
#4.1.1 Números de pedido por establecimiento y país
SELECT m.name, 
       o.country,
       COUNT(o.order_id) AS num_orders
FROM merchants m 
JOIN orders o 
ON m.merchant_id = o.merchant_id 
GROUP BY m.name, o.country;
###############################
#4.1.2 Ratio de impagos
SELECT name, 
       country,
       num_orders,
       CONCAT(ROUND(delinquent_rate), '%') AS delinquent_rate
FROM (
  SELECT m.name, 
         o.country,
         COUNT(o.order_id) AS num_orders,
         SUM(CASE WHEN o.status = 'Delinquent' THEN 1 ELSE 0 END) / COUNT(o.order_id) * 100 AS delinquent_rate,
         ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN o.status = 'Delinquent' THEN 1 
		 ELSE 0 END) / COUNT(o.order_id) DESC) AS row_num
  FROM merchants m 
  JOIN orders o 
  ON m.merchant_id = o.merchant_id 
  GROUP BY m.name, o.country
) AS t
WHERE row_num <= 10;

#############################
#4.1.2 Ratio  Devoluciones
SELECT name,
country,
num_orders,
CONCAT(ROUND(refund_rate * 100, 2), '%') AS refund_rate
FROM (
SELECT m.name,
o.country,
COUNT(o.order_id) AS num_orders,
SUM(r.amount) / SUM(o.amount) AS refund_rate,
ROW_NUMBER() OVER (ORDER BY SUM(r.amount) / SUM(o.amount) DESC) AS row_num
FROM merchants m
JOIN orders o
ON m.merchant_id = o.merchant_id
LEFT JOIN refunds r
ON o.order_id = r.order_id
WHERE o.status IS NOT NULL AND r.amount IS NOT NULL
GROUP BY m.name, o.country
HAVING refund_rate IS NOT NULL
) AS t
WHERE row_num <= 10;

