-- MySQL dump 10.13  Distrib 8.0.45, for Win64 (x86_64)
--
-- Host: localhost    Database: iwes_db
-- ------------------------------------------------------
-- Server version	8.0.45

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `listings`
--

DROP TABLE IF EXISTS `listings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `listings` (
  `listing_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `product_id` int NOT NULL,
  `listing_type` enum('BUY','SELL') NOT NULL,
  `total_qty` decimal(10,2) NOT NULL,
  `available_qty` decimal(10,2) NOT NULL,
  `price_per_unit` decimal(10,2) DEFAULT NULL,
  `location` varchar(150) DEFAULT NULL,
  `status` enum('ACTIVE','COMPLETED','EXPIRED') DEFAULT 'ACTIVE',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`listing_id`),
  KEY `fk_listings_user` (`user_id`),
  KEY `idx_listing_cat_status` (`product_id`,`status`),
  KEY `idx_listing_qty` (`available_qty`),
  CONSTRAINT `fk_listings_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_listings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_listing_available_qty` CHECK (((`available_qty` >= 0) and (`available_qty` <= `total_qty`))),
  CONSTRAINT `chk_listing_total_qty` CHECK ((`total_qty` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `listings`
--

LOCK TABLES `listings` WRITE;
/*!40000 ALTER TABLE `listings` DISABLE KEYS */;
INSERT INTO `listings` VALUES (1,1,4,'SELL',500.00,380.00,42.00,'Noida Sector 63','ACTIVE','2026-05-07 08:01:40'),(2,2,1,'BUY',1000.00,790.00,800.00,'Greater Noida','ACTIVE','2026-05-07 08:01:40'),(3,3,3,'SELL',750.00,600.00,6.50,'Ghaziabad Industrial Area','ACTIVE','2026-05-07 08:01:40'),(4,1,5,'SELL',300.00,220.00,18.00,'Dadri','ACTIVE','2026-05-07 08:01:40'),(5,2,8,'SELL',1200.00,950.00,650.00,'Noida Sector 80','ACTIVE','2026-05-07 08:01:40'),(6,5,1,'SELL',1800.00,1500.00,760.00,'Sikandrabad','ACTIVE','2026-05-07 12:51:32'),(7,7,10,'SELL',900.00,660.00,11.50,'Sahibabad Site 4','ACTIVE','2026-05-07 12:51:32'),(8,4,5,'BUY',650.00,550.00,20.00,'Noida Sector 65','ACTIVE','2026-05-07 12:51:32'),(9,7,9,'SELL',420.00,420.00,9.00,'Meerut Road Industrial Area','ACTIVE','2026-05-07 12:51:32'),(10,8,6,'SELL',700.00,540.00,4.75,'Greater Noida West','ACTIVE','2026-05-07 12:51:32'),(11,5,2,'BUY',1100.00,800.00,5.25,'Bulandshahr Road','ACTIVE','2026-05-07 12:51:32'),(12,6,2,'SELL',1400.00,1200.00,4.80,'Hapur Road','ACTIVE','2026-05-07 12:51:32'),(13,6,4,'BUY',900.00,890.00,40.00,'Loni Industrial Area','ACTIVE','2026-05-07 12:51:32'),(14,7,10,'SELL',1600.00,1600.00,10.75,'Modinagar','ACTIVE','2026-05-07 12:51:32'),(15,8,6,'BUY',500.00,500.00,5.10,'Surajpur','ACTIVE','2026-05-07 12:51:32'),(16,5,1,'BUY',2500.00,2500.00,790.00,'Dadri Eco Park','ACTIVE','2026-05-07 12:51:32'),(17,4,7,'SELL',330.00,0.00,13.50,'Noida Sector 10','COMPLETED','2026-05-07 12:51:32'),(18,3,3,'SELL',200.00,200.00,5.90,'Ghaziabad Industrial Area','EXPIRED','2026-05-07 12:51:32'),(19,12,9,'SELL',10.00,10.00,NULL,'Merut','ACTIVE','2026-05-07 19:49:39');
/*!40000 ALTER TABLE `listings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `products` (
  `product_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `category` varchar(80) NOT NULL,
  `unit` varchar(20) NOT NULL,
  `possible_uses` text,
  PRIMARY KEY (`product_id`),
  UNIQUE KEY `name` (`name`),
  KEY `idx_product_category` (`category`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `products`
--

LOCK TABLES `products` WRITE;
/*!40000 ALTER TABLE `products` DISABLE KEYS */;
INSERT INTO `products` VALUES (1,'Fly Ash','Industrial Byproduct','tonne','Used in cement, bricks, road base, and concrete blocks.'),(2,'Wood Waste','Biomass','kg','Used for biomass fuel, particle board, compost bulking, and pallets.'),(3,'Organic Waste','Biodegradable','kg','Used for composting, biogas generation, and soil conditioners.'),(4,'Scrap Metal','Metal','kg','Used for recycling, foundry feedstock, and fabrication.'),(5,'Plastic','Polymer','kg','Used for recycling, plastic lumber, packaging reuse, and pellets.'),(6,'Glass','Inert Material','kg','Used for glass recycling, tiles, aggregates, and insulation material.'),(7,'Rubber','Polymer','kg','Used for crumb rubber, mats, tyre-derived fuel, and playground flooring.'),(8,'Slag','Industrial Byproduct','tonne','Used in cement blending, road construction, and aggregate replacement.'),(9,'Textile Waste','Fabric','kg','Used for insulation, wiping cloth, fibre recovery, and upcycled products.'),(10,'Paper','Recyclable','kg','Used for paper recycling, packaging, pulp recovery, and compost carbon balance.');
/*!40000 ALTER TABLE `products` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ratings`
--

DROP TABLE IF EXISTS `ratings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ratings` (
  `rating_id` int NOT NULL AUTO_INCREMENT,
  `txn_id` int NOT NULL,
  `rater_id` int NOT NULL,
  `ratee_id` int NOT NULL,
  `score` tinyint NOT NULL,
  `comment` text,
  `rated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`rating_id`),
  UNIQUE KEY `uq_rating_once_per_user` (`txn_id`,`rater_id`),
  KEY `fk_ratings_rater` (`rater_id`),
  KEY `fk_ratings_ratee` (`ratee_id`),
  CONSTRAINT `fk_ratings_ratee` FOREIGN KEY (`ratee_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ratings_rater` FOREIGN KEY (`rater_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_ratings_transaction` FOREIGN KEY (`txn_id`) REFERENCES `transactions` (`txn_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_rating_score` CHECK ((`score` between 1 and 5))
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ratings`
--

LOCK TABLES `ratings` WRITE;
/*!40000 ALTER TABLE `ratings` DISABLE KEYS */;
INSERT INTO `ratings` VALUES (1,1,2,1,5,'Good quality scrap and quick handover.','2026-05-07 12:51:32'),(2,1,1,2,4,'Payment and pickup were smooth.','2026-05-07 12:51:32'),(3,2,2,1,4,'Fly ash supply matched the requirement.','2026-05-07 12:51:32'),(4,3,5,3,5,'Organic waste was well segregated.','2026-05-07 12:51:32'),(5,4,4,1,4,'Plastic was clean enough for reprocessing.','2026-05-07 12:51:32'),(6,5,5,2,5,'Slag quantity and documentation were clear.','2026-05-07 12:51:32'),(7,6,2,5,4,'Consistent fly ash supply.','2026-05-07 12:51:32'),(8,7,4,7,5,'Paper waste was sorted properly.','2026-05-07 12:51:32'),(9,8,4,1,4,'Useful plastic feedstock.','2026-05-07 12:51:32'),(10,9,5,8,5,'Glass cullet was ready for reuse.','2026-05-07 12:51:32'),(11,10,5,6,4,'Wood waste pickup was on time.','2026-05-07 12:51:32'),(12,11,3,6,5,'Good biomass fuel material.','2026-05-07 12:51:32'),(13,12,6,4,4,'Rubber stock was accurately listed.','2026-05-07 12:51:32'),(14,13,12,6,5,NULL,'2026-05-08 18:46:55'),(15,14,12,2,5,NULL,'2026-05-08 18:47:56');
/*!40000 ALTER TABLE `ratings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transactions`
--

DROP TABLE IF EXISTS `transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transactions` (
  `txn_id` int NOT NULL AUTO_INCREMENT,
  `listing_id` int NOT NULL,
  `buyer_id` int NOT NULL,
  `seller_id` int NOT NULL,
  `qty_exchanged` decimal(10,2) NOT NULL,
  `txn_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `status` enum('PENDING','DONE','CANCELLED') DEFAULT 'DONE',
  PRIMARY KEY (`txn_id`),
  KEY `fk_transactions_seller` (`seller_id`),
  KEY `idx_txn_listing` (`listing_id`),
  KEY `idx_txn_buyer` (`buyer_id`),
  CONSTRAINT `fk_transactions_buyer` FOREIGN KEY (`buyer_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_transactions_listing` FOREIGN KEY (`listing_id`) REFERENCES `listings` (`listing_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_transactions_seller` FOREIGN KEY (`seller_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_txn_qty` CHECK ((`qty_exchanged` > 0))
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transactions`
--

LOCK TABLES `transactions` WRITE;
/*!40000 ALTER TABLE `transactions` DISABLE KEYS */;
INSERT INTO `transactions` VALUES (1,1,2,1,120.00,'2026-05-07 12:51:32','DONE'),(2,2,2,1,200.00,'2026-05-07 12:51:32','DONE'),(3,3,5,3,150.00,'2026-05-07 12:51:32','DONE'),(4,4,4,1,80.00,'2026-05-07 12:51:32','DONE'),(5,5,5,2,250.00,'2026-05-07 12:51:32','DONE'),(6,6,2,5,300.00,'2026-05-07 12:51:32','DONE'),(7,7,4,7,240.00,'2026-05-07 12:51:32','DONE'),(8,8,4,1,100.00,'2026-05-07 12:51:32','DONE'),(9,10,5,8,160.00,'2026-05-07 12:51:32','DONE'),(10,11,5,6,300.00,'2026-05-07 12:51:32','DONE'),(11,12,3,6,200.00,'2026-05-07 12:51:32','DONE'),(12,17,6,4,330.00,'2026-05-07 12:51:32','DONE'),(13,13,6,12,10.00,'2026-05-08 18:46:51','DONE'),(14,2,2,12,10.00,'2026-05-08 18:47:53','DONE');
/*!40000 ALTER TABLE `transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `phone` varchar(15) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'Aarav Metals','aarav.metals@example.com','$2b$12$YE4Ge3ZYzgY/A0qYZLSanO.8Ha8tgu5B9DwQ1I.Xcd7LgmHEbT61W','9876543210','2026-05-07 08:01:40'),(2,'Noida Cement Works','cement.works@example.com','$2b$12$Gxd4iToQ.Y0pWoxbxRT73ukvIVkqfiYHDYm6XgEOXDkeQvjEaOAdS','9876543211','2026-05-07 08:01:40'),(3,'Green Bio Energy','green.bio@example.com','$2b$12$Gh3w7OIcsKjsusV2HgIyK.t7mUYqSaDXQDVmIh/kfn59HSWQPou.u','9876543212','2026-05-07 08:01:40'),(4,'NCR Plastics Recycler','ncr.plastics@example.com','$2b$12$YE4Ge3ZYzgY/A0qYZLSanO.8Ha8tgu5B9DwQ1I.Xcd7LgmHEbT61W','9876543213','2026-05-07 12:51:32'),(5,'EcoBrick Solutions','ecobrick@example.com','$2b$12$Gxd4iToQ.Y0pWoxbxRT73ukvIVkqfiYHDYm6XgEOXDkeQvjEaOAdS','9876543214','2026-05-07 12:51:32'),(6,'Urban Timber Works','urban.timber@example.com','$2b$12$Gh3w7OIcsKjsusV2HgIyK.t7mUYqSaDXQDVmIh/kfn59HSWQPou.u','9876543215','2026-05-07 12:51:32'),(7,'Shakti Paper Mills','shakti.paper@example.com','$2b$12$YE4Ge3ZYzgY/A0qYZLSanO.8Ha8tgu5B9DwQ1I.Xcd7LgmHEbT61W','9876543216','2026-05-07 12:51:32'),(8,'Metro Glass Recyclers','metro.glass@example.com','$2b$12$Gxd4iToQ.Y0pWoxbxRT73ukvIVkqfiYHDYm6XgEOXDkeQvjEaOAdS','9876543217','2026-05-07 12:51:32'),(12,'test user','ar.officialprime@gmail.com','$2b$12$cqWjhjuhRxAaS0MkEMdKcOgqK7JG3saQxAhHL1suDPHARnNyCYNyi','9999999999','2026-05-07 11:46:38');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `vw_active_listings`
--

DROP TABLE IF EXISTS `vw_active_listings`;
/*!50001 DROP VIEW IF EXISTS `vw_active_listings`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_active_listings` AS SELECT 
 1 AS `listing_id`,
 1 AS `user_id`,
 1 AS `user_name`,
 1 AS `user_email`,
 1 AS `user_phone`,
 1 AS `product_id`,
 1 AS `product_name`,
 1 AS `category`,
 1 AS `unit`,
 1 AS `possible_uses`,
 1 AS `listing_type`,
 1 AS `total_qty`,
 1 AS `available_qty`,
 1 AS `price_per_unit`,
 1 AS `location`,
 1 AS `status`,
 1 AS `created_at`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_recent_transactions`
--

DROP TABLE IF EXISTS `vw_recent_transactions`;
/*!50001 DROP VIEW IF EXISTS `vw_recent_transactions`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_recent_transactions` AS SELECT 
 1 AS `txn_id`,
 1 AS `listing_id`,
 1 AS `buyer_id`,
 1 AS `buyer_name`,
 1 AS `seller_id`,
 1 AS `seller_name`,
 1 AS `product_id`,
 1 AS `product_name`,
 1 AS `category`,
 1 AS `unit`,
 1 AS `listing_type`,
 1 AS `qty_exchanged`,
 1 AS `status`,
 1 AS `txn_date`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_top_waste_types`
--

DROP TABLE IF EXISTS `vw_top_waste_types`;
/*!50001 DROP VIEW IF EXISTS `vw_top_waste_types`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_top_waste_types` AS SELECT 
 1 AS `category`,
 1 AS `transaction_count`,
 1 AS `total_qty_exchanged`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_user_activity`
--

DROP TABLE IF EXISTS `vw_user_activity`;
/*!50001 DROP VIEW IF EXISTS `vw_user_activity`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_user_activity` AS SELECT 
 1 AS `user_id`,
 1 AS `name`,
 1 AS `email`,
 1 AS `total_listings`,
 1 AS `active_listings`,
 1 AS `transactions_as_buyer`,
 1 AS `transactions_as_seller`,
 1 AS `average_rating_received`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `wastemapping`
--

DROP TABLE IF EXISTS `wastemapping`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `wastemapping` (
  `mapping_id` int NOT NULL AUTO_INCREMENT,
  `product_id` int NOT NULL,
  `alternative_use` varchar(200) NOT NULL,
  `industry` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`mapping_id`),
  KEY `fk_wastemapping_product` (`product_id`),
  CONSTRAINT `fk_wastemapping_product` FOREIGN KEY (`product_id`) REFERENCES `products` (`product_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wastemapping`
--

LOCK TABLES `wastemapping` WRITE;
/*!40000 ALTER TABLE `wastemapping` DISABLE KEYS */;
INSERT INTO `wastemapping` VALUES (1,1,'Cement and concrete additive','Construction'),(2,2,'Biomass boiler fuel','Energy'),(3,3,'Biogas feedstock','Renewable Energy'),(4,4,'Metal recycling feedstock','Manufacturing'),(5,5,'Reprocessed plastic pellets','Packaging'),(6,6,'Recycled glass aggregate','Construction'),(7,7,'Crumb rubber flooring','Civil Works'),(8,8,'Cement clinker substitute','Construction'),(9,9,'Recovered fibre insulation','Textiles'),(10,10,'Recycled paper pulp','Paper Manufacturing');
/*!40000 ALTER TABLE `wastemapping` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Final view structure for view `vw_active_listings`
--

/*!50001 DROP VIEW IF EXISTS `vw_active_listings`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_active_listings` AS select `l`.`listing_id` AS `listing_id`,`l`.`user_id` AS `user_id`,`u`.`name` AS `user_name`,`u`.`email` AS `user_email`,`u`.`phone` AS `user_phone`,`l`.`product_id` AS `product_id`,`p`.`name` AS `product_name`,`p`.`category` AS `category`,`p`.`unit` AS `unit`,`p`.`possible_uses` AS `possible_uses`,`l`.`listing_type` AS `listing_type`,`l`.`total_qty` AS `total_qty`,`l`.`available_qty` AS `available_qty`,`l`.`price_per_unit` AS `price_per_unit`,`l`.`location` AS `location`,`l`.`status` AS `status`,`l`.`created_at` AS `created_at` from ((`listings` `l` join `users` `u` on((`u`.`user_id` = `l`.`user_id`))) join `products` `p` on((`p`.`product_id` = `l`.`product_id`))) where (`l`.`status` = 'ACTIVE') */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_recent_transactions`
--

/*!50001 DROP VIEW IF EXISTS `vw_recent_transactions`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_recent_transactions` AS select `t`.`txn_id` AS `txn_id`,`t`.`listing_id` AS `listing_id`,`t`.`buyer_id` AS `buyer_id`,`buyer`.`name` AS `buyer_name`,`t`.`seller_id` AS `seller_id`,`seller`.`name` AS `seller_name`,`p`.`product_id` AS `product_id`,`p`.`name` AS `product_name`,`p`.`category` AS `category`,`p`.`unit` AS `unit`,`l`.`listing_type` AS `listing_type`,`t`.`qty_exchanged` AS `qty_exchanged`,`t`.`status` AS `status`,`t`.`txn_date` AS `txn_date` from ((((`transactions` `t` join `listings` `l` on((`l`.`listing_id` = `t`.`listing_id`))) join `products` `p` on((`p`.`product_id` = `l`.`product_id`))) join `users` `buyer` on((`buyer`.`user_id` = `t`.`buyer_id`))) join `users` `seller` on((`seller`.`user_id` = `t`.`seller_id`))) where (`t`.`txn_date` >= (now() - interval 30 day)) order by `t`.`txn_date` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_top_waste_types`
--

/*!50001 DROP VIEW IF EXISTS `vw_top_waste_types`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_top_waste_types` AS select `p`.`category` AS `category`,count(`t`.`txn_id`) AS `transaction_count`,coalesce(sum(`t`.`qty_exchanged`),0) AS `total_qty_exchanged` from ((`products` `p` left join `listings` `l` on((`l`.`product_id` = `p`.`product_id`))) left join `transactions` `t` on((`t`.`listing_id` = `l`.`listing_id`))) group by `p`.`category` order by `transaction_count` desc,`total_qty_exchanged` desc,`p`.`category` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_user_activity`
--

/*!50001 DROP VIEW IF EXISTS `vw_user_activity`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = cp850 */;
/*!50001 SET character_set_results     = cp850 */;
/*!50001 SET collation_connection      = cp850_general_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_user_activity` AS select `u`.`user_id` AS `user_id`,`u`.`name` AS `name`,`u`.`email` AS `email`,(select count(0) from `listings` `l` where (`l`.`user_id` = `u`.`user_id`)) AS `total_listings`,(select count(0) from `listings` `l` where ((`l`.`user_id` = `u`.`user_id`) and (`l`.`status` = 'ACTIVE'))) AS `active_listings`,(select count(0) from `transactions` `t` where ((`t`.`buyer_id` = `u`.`user_id`) and (`t`.`status` = 'DONE'))) AS `transactions_as_buyer`,(select count(0) from `transactions` `t` where ((`t`.`seller_id` = `u`.`user_id`) and (`t`.`status` = 'DONE'))) AS `transactions_as_seller`,(select coalesce(round(avg(`r`.`score`),2),0) from `ratings` `r` where (`r`.`ratee_id` = `u`.`user_id`)) AS `average_rating_received` from `users` `u` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-05-09  3:02:58
