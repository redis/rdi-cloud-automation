-- SQL Server 2022 dataset matching the MySQL / Postgres inventory schema.
-- Skips the `geom` table - SQL Server has a native geometry type but it uses
-- different WKB constructors than MySQL; keep this lean for now.
--
-- SQL Server RDS doesn't accept `db_name` at instance creation, so this script
-- creates and selects the `inventory` database itself. Run it against `master`.

IF DB_ID('inventory') IS NULL CREATE DATABASE inventory;
GO

USE inventory;
GO

CREATE TABLE customers (
  id         INT          IDENTITY(1005, 1) NOT NULL PRIMARY KEY,
  first_name VARCHAR(255) NOT NULL,
  last_name  VARCHAR(255) NOT NULL,
  email      VARCHAR(255) NOT NULL UNIQUE
);

SET IDENTITY_INSERT customers ON;
INSERT INTO customers (id, first_name, last_name, email) VALUES (1001, 'Sally',  'Thomas',    'sally.thomas@acme.com');
INSERT INTO customers (id, first_name, last_name, email) VALUES (1002, 'George', 'Bailey',    'gbailey@foobar.com');
INSERT INTO customers (id, first_name, last_name, email) VALUES (1003, 'Edward', 'Walker',    'ed@walker.com');
INSERT INTO customers (id, first_name, last_name, email) VALUES (1004, 'Anne',   'Kretchmar', 'annek@noanswer.org');
SET IDENTITY_INSERT customers OFF;

CREATE TABLE products (
  id          INT          IDENTITY(110, 1) NOT NULL PRIMARY KEY,
  name        VARCHAR(255) NOT NULL,
  description VARCHAR(512),
  weight      FLOAT
);

SET IDENTITY_INSERT products ON;
INSERT INTO products (id, name, description, weight) VALUES (101, 'scooter',            'Small 2-wheel scooter',                                3.14);
INSERT INTO products (id, name, description, weight) VALUES (102, 'car battery',        '12V car battery',                                      8.1);
INSERT INTO products (id, name, description, weight) VALUES (103, '12-pack drill bits', '12-pack of drill bits with sizes ranging from #40 to #3', 0.8);
INSERT INTO products (id, name, description, weight) VALUES (104, 'hammer',             '12oz carpenter''s hammer',                             0.75);
INSERT INTO products (id, name, description, weight) VALUES (105, 'hammer',             '14oz carpenter''s hammer',                             0.875);
INSERT INTO products (id, name, description, weight) VALUES (106, 'hammer',             '16oz carpenter''s hammer',                             1);
INSERT INTO products (id, name, description, weight) VALUES (107, 'rocks',              'box of assorted rocks',                                5.3);
INSERT INTO products (id, name, description, weight) VALUES (108, 'jacket',             'water resistent black wind breaker',                   0.1);
INSERT INTO products (id, name, description, weight) VALUES (109, 'spare tire',         '24 inch spare tire',                                   22.2);
SET IDENTITY_INSERT products OFF;

CREATE TABLE addresses (
  id          INT          IDENTITY(17, 1) NOT NULL PRIMARY KEY,
  customer_id INT          NOT NULL,
  street      VARCHAR(255) NOT NULL,
  city        VARCHAR(255) NOT NULL,
  state       VARCHAR(255) NOT NULL,
  zip         VARCHAR(255) NOT NULL,
  type        VARCHAR(20)  NOT NULL CHECK (type IN ('SHIPPING', 'BILLING', 'LIVING')),
  CONSTRAINT addresses_customer_fk FOREIGN KEY (customer_id) REFERENCES customers(id)
);

SET IDENTITY_INSERT addresses ON;
INSERT INTO addresses (id, customer_id, street, city, state, zip, type) VALUES (10, 1001, '3183 Moore Avenue',         'Euless',     'Texas',        '76036', 'SHIPPING');
INSERT INTO addresses (id, customer_id, street, city, state, zip, type) VALUES (11, 1001, '2389 Hidden Valley Road',   'Harrisburg', 'Pennsylvania', '17116', 'BILLING');
INSERT INTO addresses (id, customer_id, street, city, state, zip, type) VALUES (12, 1002, '281 Riverside Drive',       'Augusta',    'Georgia',      '30901', 'BILLING');
INSERT INTO addresses (id, customer_id, street, city, state, zip, type) VALUES (13, 1003, '3787 Brownton Road',        'Columbus',   'Mississippi',  '39701', 'SHIPPING');
INSERT INTO addresses (id, customer_id, street, city, state, zip, type) VALUES (14, 1003, '2458 Lost Creek Road',      'Bethlehem',  'Pennsylvania', '18018', 'SHIPPING');
INSERT INTO addresses (id, customer_id, street, city, state, zip, type) VALUES (15, 1003, '4800 Simpson Square',       'Hillsdale',  'Oklahoma',     '73743', 'BILLING');
INSERT INTO addresses (id, customer_id, street, city, state, zip, type) VALUES (16, 1004, '1289 University Hill Road', 'Canehill',   'Arkansas',     '72717', 'LIVING');
SET IDENTITY_INSERT addresses OFF;

CREATE TABLE orders (
  order_number INT  IDENTITY(10005, 1) NOT NULL PRIMARY KEY,
  order_date   DATE NOT NULL,
  purchaser    INT  NOT NULL,
  quantity     INT  NOT NULL,
  product_id   INT  NOT NULL,
  CONSTRAINT orders_customer_fk FOREIGN KEY (purchaser)  REFERENCES customers(id),
  CONSTRAINT orders_product_fk  FOREIGN KEY (product_id) REFERENCES products(id)
);

SET IDENTITY_INSERT orders ON;
INSERT INTO orders (order_number, order_date, purchaser, quantity, product_id) VALUES (10001, '2016-01-16', 1001, 1, 102);
INSERT INTO orders (order_number, order_date, purchaser, quantity, product_id) VALUES (10002, '2016-01-17', 1002, 2, 105);
INSERT INTO orders (order_number, order_date, purchaser, quantity, product_id) VALUES (10003, '2016-02-19', 1002, 2, 106);
INSERT INTO orders (order_number, order_date, purchaser, quantity, product_id) VALUES (10004, '2016-02-21', 1003, 1, 107);
SET IDENTITY_INSERT orders OFF;
