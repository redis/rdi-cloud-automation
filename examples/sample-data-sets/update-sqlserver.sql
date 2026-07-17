-- Mutations against the inventory schema (SQL Server).
-- Re-runnable; respects FK constraints. See update-mysql.sql for the strategy.

USE inventory;
GO

DECLARE @ts VARCHAR(20) = CAST(DATEDIFF(SECOND, '1970-01-01', GETUTCDATE()) AS VARCHAR(20));

-- customers
INSERT INTO customers (first_name, last_name, email) VALUES
  ('TestUser', 'New',   'test-' + @ts + '-1@example.com'),
  ('TestUser', 'Other', 'test-' + @ts + '-2@example.com');
UPDATE customers SET last_name = 'Edit-' + @ts WHERE id = 1001;
DELETE FROM customers
  WHERE id = (SELECT MIN(id) FROM customers WHERE first_name = 'TestUser');

-- products
INSERT INTO products (name, description, weight) VALUES
  ('TestProd-' + @ts, 'CDC test product', 1.0);
UPDATE products SET description = 'Updated-' + @ts WHERE id = 101;
DELETE FROM products
  WHERE id = (SELECT MIN(id) FROM products WHERE name LIKE 'TestProd-%');

-- addresses
INSERT INTO addresses (customer_id, street, city, state, zip, type) VALUES
  (1001, 'Test St ' + @ts, 'TestCity', 'TestState', '00000', 'LIVING');
UPDATE addresses SET street = 'Updated ' + @ts WHERE id = 10;
DELETE FROM addresses
  WHERE id = (SELECT MIN(id) FROM addresses WHERE city = 'TestCity');

-- orders
INSERT INTO orders (order_date, purchaser, quantity, product_id) VALUES
  (GETDATE(), 1001, 1, 101);
UPDATE orders SET quantity = quantity + 1 WHERE order_number = 10001;
DELETE FROM orders
  WHERE order_number = (SELECT MIN(order_number) FROM orders
                        WHERE purchaser = 1001 AND quantity = 1 AND product_id = 101);
GO
