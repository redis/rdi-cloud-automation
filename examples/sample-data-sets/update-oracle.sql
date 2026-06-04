-- Mutations against the inventory schema (Oracle).
-- Re-runnable; respects FK constraints. See update-mysql.sql for the strategy.

-- customers
INSERT INTO customers (first_name, last_name, email)
  VALUES ('TestUser', 'New',   'test-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3') || '-1@example.com');
INSERT INTO customers (first_name, last_name, email)
  VALUES ('TestUser', 'Other', 'test-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3') || '-2@example.com');
UPDATE customers SET last_name = 'Edit-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISS') WHERE id = 1001;
DELETE FROM customers WHERE id = (SELECT MIN(id) FROM customers WHERE first_name = 'TestUser');

-- products
INSERT INTO products (name, description, weight)
  VALUES ('TestProd-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3'), 'CDC test product', 1.0);
UPDATE products SET description = 'Updated-' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISS') WHERE id = 101;
DELETE FROM products WHERE id = (SELECT MIN(id) FROM products WHERE name LIKE 'TestProd-%');

-- addresses
INSERT INTO addresses (customer_id, street, city, state, zip, type)
  VALUES (1001, 'Test St ' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISS'),
          'TestCity', 'TestState', '00000', 'LIVING');
UPDATE addresses SET street = 'Updated ' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISS') WHERE id = 10;
DELETE FROM addresses WHERE id = (SELECT MIN(id) FROM addresses WHERE city = 'TestCity');

-- orders
INSERT INTO orders (order_date, purchaser, quantity, product_id)
  VALUES (SYSDATE, 1001, 1, 101);
UPDATE orders SET quantity = quantity + 1 WHERE order_number = 10001;
DELETE FROM orders WHERE order_number = (
  SELECT MIN(order_number) FROM orders
  WHERE purchaser = 1001 AND quantity = 1 AND product_id = 101
);

COMMIT;
EXIT;
