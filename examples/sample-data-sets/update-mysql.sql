-- Mutations against the inventory schema. Works for MySQL, MariaDB,
-- and Aurora-MySQL (shared SQL dialect). Designed to be re-run safely;
-- each invocation emits fresh CDC events without breaking FK constraints.
--
-- Strategy:
--   - INSERT 2 new rows in customers + 1 in products + 1 in addresses + 1 in orders.
--   - UPDATE one existing row per table (touches values with a timestamp).
--   - DELETE one "TestUser/TestProd/TestCity" marker row inserted by a previous run.
-- Customers and products are never deleted while they have FK references.

-- customers
INSERT INTO customers (first_name, last_name, email) VALUES
  ('TestUser', 'New',   CONCAT('test-', UNIX_TIMESTAMP(), '-1@example.com')),
  ('TestUser', 'Other', CONCAT('test-', UNIX_TIMESTAMP(), '-2@example.com'));
UPDATE customers SET last_name = CONCAT('Edit-', UNIX_TIMESTAMP()) WHERE id = 1001;
DELETE FROM customers WHERE first_name = 'TestUser' ORDER BY id LIMIT 1;

-- products
INSERT INTO products (name, description, weight) VALUES
  (CONCAT('TestProd-', UNIX_TIMESTAMP()), 'CDC test product', 1.0);
UPDATE products SET description = CONCAT('Updated-', UNIX_TIMESTAMP()) WHERE id = 101;
DELETE FROM products WHERE name LIKE 'TestProd-%' ORDER BY id LIMIT 1;

-- addresses (FK -> customers.id 1001 always exists)
INSERT INTO addresses (customer_id, street, city, state, zip, type) VALUES
  (1001, CONCAT('Test St ', UNIX_TIMESTAMP()), 'TestCity', 'TestState', '00000', 'LIVING');
UPDATE addresses SET street = CONCAT('Updated ', UNIX_TIMESTAMP()) WHERE id = 10;
DELETE FROM addresses WHERE city = 'TestCity' ORDER BY id LIMIT 1;

-- orders (FK -> customers.id 1001 + products.id 101)
INSERT INTO orders (order_date, purchaser, quantity, product_id) VALUES
  (CURRENT_DATE, 1001, 1, 101);
UPDATE orders SET quantity = quantity + 1 WHERE order_number = 10001;
DELETE FROM orders
  WHERE purchaser = 1001 AND quantity = 1 AND product_id = 101
  ORDER BY order_number LIMIT 1;
