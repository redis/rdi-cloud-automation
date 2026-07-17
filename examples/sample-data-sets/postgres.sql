/*M!999999\- enable the sandbox mode */
-- MariaDB dump 10.19-11.7.2-MariaDB, for osx10.20 (arm64)
--
-- Host: 127.0.0.1    Database: inventory
-- ------------------------------------------------------
-- Server version	8.2.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Table structure for table addresses
--

DROP TABLE IF EXISTS addresses;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE addresses (
                           id SERIAL PRIMARY KEY,
                           customer_id int NOT NULL,
                           street varchar(255) NOT NULL,
                           city varchar(255) NOT NULL,
                           state varchar(255) NOT NULL,
                           zip varchar(255) NOT NULL,
                           type varchar(255) NOT NULL
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table addresses
--

/*!40000 ALTER TABLE addresses DISABLE KEYS */;
INSERT INTO addresses VALUES
                          (10,1001,'3183 Moore Avenue','Euless','Texas','76036','SHIPPING'),
                          (11,1001,'2389 Hidden Valley Road','Harrisburg','Pennsylvania','17116','BILLING'),
                          (12,1002,'281 Riverside Drive','Augusta','Georgia','30901','BILLING'),
                          (13,1003,'3787 Brownton Road','Columbus','Mississippi','39701','SHIPPING'),
                          (14,1003,'2458 Lost Creek Road','Bethlehem','Pennsylvania','18018','SHIPPING'),
                          (15,1003,'4800 Simpson Square','Hillsdale','Oklahoma','73743','BILLING'),
                          (16,1004,'1289 University Hill Road','Canehill','Arkansas','72717','LIVING');
/*!40000 ALTER TABLE addresses ENABLE KEYS */;

--
-- Table structure for table customers
--

DROP TABLE IF EXISTS customers;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE customers (
                           id SERIAL PRIMARY KEY,
                           first_name varchar(255) NOT NULL,
                           last_name varchar(255) NOT NULL,
                           email varchar(255) NOT NULL UNIQUE
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table customers
--

/*!40000 ALTER TABLE customers DISABLE KEYS */;
INSERT INTO customers VALUES
                          (1001,'Sally','Thomas','sally.thomas@acme.com'),
                          (1002,'George','Bailey','gbailey@foobar.com'),
                          (1003,'Edward','Walker','ed@walker.com'),
                          (1004,'Anne','Kretchmar','annek@noanswer.org');
/*!40000 ALTER TABLE customers ENABLE KEYS */;

--
-- Table structure for table geom
--

--
-- Table structure for table orders
--

DROP TABLE IF EXISTS orders;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE orders (
                        order_number SERIAL PRIMARY KEY,
                        order_date date NOT NULL,
                        purchaser int NOT NULL,
                        quantity int NOT NULL,
                        product_id int NOT NULL
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table orders
--

/*!40000 ALTER TABLE orders DISABLE KEYS */;
INSERT INTO orders VALUES
                       (10001,'2016-01-16',1001,1,102),
                       (10002,'2016-01-17',1002,2,105),
                       (10003,'2016-02-19',1002,2,106),
                       (10004,'2016-02-21',1003,1,107);
/*!40000 ALTER TABLE orders ENABLE KEYS */;

--
-- Table structure for table products
--

DROP TABLE IF EXISTS products;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE products (
                          id SERIAL PRIMARY KEY,
                          name varchar(255) NOT NULL,
                          description varchar(512) DEFAULT NULL,
                          weight float DEFAULT NULL
);
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table products
--

/*!40000 ALTER TABLE products DISABLE KEYS */;
INSERT INTO products VALUES
                         (101,'scooter','Small 2-wheel scooter',3.14),
                         (102,'car battery','12V car battery',8.1),
                         (103,'12-pack drill bits','12-pack of drill bits with sizes ranging from #40 to #3',0.8),
                         (104,'hammer','12oz carpenter''s hammer',0.75),
                         (105,'hammer','14oz carpenter''s hammer',0.875),
                         (106,'hammer','16oz carpenter''s hammer',1),
                         (107,'rocks','box of assorted rocks',5.3),
                         (108,'jacket','water resistent black wind breaker',0.1),
                         (109,'spare tire','24 inch spare tire',22.2);
