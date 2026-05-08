USE iwes_db;

-- IWES V2.0 Migration
-- WHAT: Upgrades V1 schema and DB objects to V2.0 without rebuilding tables.
-- WHY: Existing local/demo databases should migrate in-place with data preserved.
-- This script adds city/location-aware fields, lifecycle statuses, notifications,
-- and refreshes trigger/procedure/view definitions used by dashboard and matching.

ALTER TABLE Users
    ADD COLUMN IF NOT EXISTS city VARCHAR(80) DEFAULT NULL;

ALTER TABLE Listings
    ADD COLUMN IF NOT EXISTS city VARCHAR(80) DEFAULT NULL;

CREATE TABLE IF NOT EXISTS Notifications (
    notif_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type ENUM('MATCH_FOUND','TXN_REQUESTED','TXN_UPDATED','LISTING_EXPIRED','RATING_RECEIVED') NOT NULL,
    message VARCHAR(300) NOT NULL,
    related_id INT DEFAULT NULL,
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_user
        FOREIGN KEY (user_id) REFERENCES Users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    INDEX idx_notif_user_unread (user_id, is_read)
) ENGINE=InnoDB;

-- Temporary enum includes old and new states so data can be transformed safely.
ALTER TABLE Transactions
    MODIFY COLUMN status ENUM(
        'PENDING',
        'DONE',
        'REQUESTED',
        'ACCEPTED',
        'IN_TRANSIT',
        'DELIVERED',
        'COMPLETED',
        'CANCELLED'
    ) DEFAULT 'REQUESTED';

UPDATE Transactions
SET status = 'REQUESTED'
WHERE status = 'PENDING';

UPDATE Transactions
SET status = 'COMPLETED'
WHERE status = 'DONE';

ALTER TABLE Transactions
    MODIFY COLUMN status ENUM(
        'REQUESTED',
        'ACCEPTED',
        'IN_TRANSIT',
        'DELIVERED',
        'COMPLETED',
        'CANCELLED'
    ) DEFAULT 'REQUESTED';

DROP TRIGGER IF EXISTS after_txn_insert;
DELIMITER $$
CREATE TRIGGER after_txn_insert
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN
    UPDATE Listings
    SET
        available_qty = available_qty - NEW.qty_exchanged,
        status = CASE
            WHEN available_qty - NEW.qty_exchanged <= 0 THEN 'COMPLETED'
            ELSE status
        END
    WHERE listing_id = NEW.listing_id;

    IF NEW.status = 'REQUESTED' THEN
        INSERT INTO Notifications (user_id, type, message, related_id)
        VALUES (
            NEW.seller_id,
            'TXN_REQUESTED',
            CONCAT('New transaction requested for listing #', NEW.listing_id),
            NEW.txn_id
        );
    END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS create_transaction;
DROP PROCEDURE IF EXISTS match_listings;
DELIMITER $$
CREATE PROCEDURE create_transaction(
    IN p_listing_id INT,
    IN p_buyer_id INT,
    IN p_qty DECIMAL(10,2)
)
BEGIN
    DECLARE v_owner_id INT;
    DECLARE v_listing_type ENUM('BUY','SELL');
    DECLARE v_status ENUM('ACTIVE','COMPLETED','EXPIRED');
    DECLARE v_available_qty DECIMAL(10,2);
    DECLARE v_buyer_id INT;
    DECLARE v_seller_id INT;

    SELECT user_id, listing_type, status, available_qty
    INTO v_owner_id, v_listing_type, v_status, v_available_qty
    FROM Listings
    WHERE listing_id = p_listing_id
    FOR UPDATE;

    IF v_owner_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Listing does not exist';
    END IF;

    IF v_status <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Listing is not active';
    END IF;

    IF p_qty <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Transaction quantity must be greater than zero';
    END IF;

    IF p_qty > v_available_qty THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Requested quantity exceeds available quantity';
    END IF;

    IF v_owner_id = p_buyer_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot transact on your own listing';
    END IF;

    IF v_listing_type = 'SELL' THEN
        SET v_buyer_id = p_buyer_id;
        SET v_seller_id = v_owner_id;
    ELSE
        SET v_buyer_id = v_owner_id;
        SET v_seller_id = p_buyer_id;
    END IF;

    INSERT INTO Transactions (
        listing_id,
        buyer_id,
        seller_id,
        qty_exchanged,
        status
    ) VALUES (
        p_listing_id,
        v_buyer_id,
        v_seller_id,
        p_qty,
        'REQUESTED'
    );

    SELECT
        LAST_INSERT_ID() AS txn_id,
        p_listing_id AS listing_id,
        v_buyer_id AS buyer_id,
        v_seller_id AS seller_id,
        p_qty AS qty_exchanged,
        'REQUESTED' AS status;
END$$

CREATE PROCEDURE match_listings(
    IN p_product_id INT,
    IN p_qty_needed DECIMAL(10,2),
    IN p_buy_city VARCHAR(80)
)
BEGIN
    SELECT
        ranked.listing_id,
        ranked.seller_id,
        ranked.seller_name,
        ranked.product_id,
        ranked.product_name,
        ranked.category,
        ranked.unit,
        ranked.total_qty,
        ranked.available_qty,
        ranked.price_per_unit,
        ranked.location,
        ranked.city,
        ranked.created_at,
        ranked.days_old,
        ranked.qty_score,
        ranked.city_bonus,
        ranked.freshness_bonus,
        LEAST(
            100,
            GREATEST(
                0,
                CAST(ROUND(ranked.qty_score + ranked.city_bonus + ranked.freshness_bonus, 0) AS UNSIGNED)
            )
        ) AS match_score
    FROM (
        SELECT
            l.listing_id,
            l.user_id AS seller_id,
            u.name AS seller_name,
            p.product_id,
            p.name AS product_name,
            p.category,
            p.unit,
            l.total_qty,
            l.available_qty,
            l.price_per_unit,
            l.location,
            l.city,
            l.created_at,
            DATEDIFF(CURDATE(), DATE(l.created_at)) AS days_old,
            IF(
                l.available_qty >= p_qty_needed,
                50,
                (l.available_qty / p_qty_needed) * 50
            ) AS qty_score,
            IF(
                p_buy_city IS NOT NULL
                AND l.city IS NOT NULL
                AND LOWER(TRIM(l.city)) = LOWER(TRIM(p_buy_city)),
                30,
                0
            ) AS city_bonus,
            CASE
                WHEN DATEDIFF(CURDATE(), DATE(l.created_at)) <= 7 THEN 20
                WHEN DATEDIFF(CURDATE(), DATE(l.created_at)) <= 30 THEN 10
                ELSE 5
            END AS freshness_bonus
        FROM Listings l
        INNER JOIN Users u ON u.user_id = l.user_id
        INNER JOIN Products p ON p.product_id = l.product_id
        WHERE l.product_id = p_product_id
          AND l.listing_type = 'SELL'
          AND l.status = 'ACTIVE'
          AND l.available_qty > 0
    ) AS ranked
    ORDER BY match_score DESC, ranked.price_per_unit ASC, ranked.created_at DESC;
END$$
DELIMITER ;

DROP VIEW IF EXISTS vw_activity_feed;
CREATE VIEW vw_activity_feed AS
SELECT
    'TRANSACTION' AS event_type,
    t.txn_id AS event_id,
    CONCAT(u_buyer.name, ' purchased ', t.qty_exchanged, ' ', p.unit, ' of ', p.name) AS message,
    t.txn_date AS event_time,
    t.buyer_id AS actor_user_id
FROM Transactions t
INNER JOIN Listings l ON t.listing_id = l.listing_id
INNER JOIN Products p ON l.product_id = p.product_id
INNER JOIN Users u_buyer ON t.buyer_id = u_buyer.user_id

UNION ALL

SELECT
    'LISTING' AS event_type,
    l.listing_id AS event_id,
    CONCAT(u.name, ' listed ', l.available_qty, ' ', p.unit, ' of ', p.name, ' (', l.listing_type, ')') AS message,
    l.created_at AS event_time,
    l.user_id AS actor_user_id
FROM Listings l
INNER JOIN Products p ON l.product_id = p.product_id
INNER JOIN Users u ON l.user_id = u.user_id
WHERE l.status = 'ACTIVE'

ORDER BY event_time DESC
LIMIT 20;
