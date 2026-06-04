-- Mutations against the inventory schema (Postgres / Aurora-Postgres).
-- Re-runnable; respects FK constraints. See update-mysql.sql for the strategy.

-- customers
INSERT INTO customers (first_name, last_name, email) VALUES
  ('TestUser', 'New',   'test-' || extract(epoch from now())::bigint || '-1@example.com'),
  ('TestUser', 'Other', 'test-' || extract(epoch from now())::bigint || '-2@example.com');
UPDATE customers SET last_name = 'Edit-' || extract(epoch from now())::bigint WHERE id = 1001;
DELETE FROM customers WHERE id IN (
  SELECT id FROM customers WHERE first_name = 'TestUser' ORDER BY id LIMIT 1
);

-- products
INSERT INTO products (name, description, weight) VALUES
  ('TestProd-' || extract(epoch from now())::bigint, 'CDC test product', 1.0);
UPDATE products SET description = 'Updated-' || extract(epoch from now())::bigint WHERE id = 101;
DELETE FROM products WHERE id IN (
  SELECT id FROM products WHERE name LIKE 'TestProd-%' ORDER BY id LIMIT 1
);

-- addresses
INSERT INTO addresses (customer_id, street, city, state, zip, type) VALUES
  (1001, 'Test St ' || extract(epoch from now())::bigint, 'TestCity', 'TestState', '00000', 'LIVING');
UPDATE addresses SET street = 'Updated ' || extract(epoch from now())::bigint WHERE id = 10;
DELETE FROM addresses WHERE id IN (
  SELECT id FROM addresses WHERE city = 'TestCity' ORDER BY id LIMIT 1
);

-- orders
INSERT INTO orders (order_date, purchaser, quantity, product_id) VALUES
  (CURRENT_DATE, 1001, 1, 101);
UPDATE orders SET quantity = quantity + 1 WHERE order_number = 10001;
DELETE FROM orders WHERE order_number IN (
  SELECT order_number FROM orders
  WHERE purchaser = 1001 AND quantity = 1 AND product_id = 101
  ORDER BY order_number LIMIT 1
);
