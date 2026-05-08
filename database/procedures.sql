USE iwes_db;

DROP PROCEDURE IF EXISTS create_transaction;
DROP PROCEDURE IF EXISTS match_listings;
DROP PROCEDURE IF EXISTS get_user_summary;
DROP EVENT IF EXISTS expire_old_listings;

DELIMITER $$

-- Procedure: create_transaction
-- WHAT: Creates a transaction for an active BUY or SELL listing.
-- WHY: Flask should only call this procedure; MySQL decides buyer/seller roles.
-- For SELL listings, the acting user buys from the listing owner.
-- For BUY listings, the acting user sells to the listing owner.
-- Triggers then validate quantity and decrement available_qty automatically.
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
        'DONE'
    );

    SELECT
        LAST_INSERT_ID() AS txn_id,
        p_listing_id AS listing_id,
        v_buyer_id AS buyer_id,
        v_seller_id AS seller_id,
        p_qty AS qty_exchanged,
        'DONE' AS status;
END$$

-- Procedure: match_listings
-- WHAT: Finds active SELL listings for a requested product and quantity.
-- WHY: Matching is core DBMS logic, so it belongs in MySQL instead of Flask.
-- Results are ordered by cheapest price first, then newest listing.
-- Flask can pass product_id and qty_needed, then return this result as JSON.
CREATE PROCEDURE match_listings(
    IN p_product_id INT,
    IN p_qty_needed DECIMAL(10,2)
)
BEGIN
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
        l.created_at
    FROM Listings l
    INNER JOIN Users u ON u.user_id = l.user_id
    INNER JOIN Products p ON p.product_id = l.product_id
    WHERE l.product_id = p_product_id
      AND l.listing_type = 'SELL'
      AND l.status = 'ACTIVE'
      AND l.available_qty >= p_qty_needed
    ORDER BY l.price_per_unit ASC, l.created_at DESC;
END$$

-- Procedure: get_user_summary
-- WHAT: Returns one user's listing count, buyer/seller transaction counts,
-- and average rating received.
-- WHY: The dashboard needs multiple aggregates, but Flask should not assemble
-- analytics with several separate SQL queries.
-- This procedure gives the app one simple CALL for user statistics.
CREATE PROCEDURE get_user_summary(
    IN p_user_id INT
)
BEGIN
    SELECT
        u.user_id,
        u.name,
        (
            SELECT COUNT(*)
            FROM Listings l
            WHERE l.user_id = u.user_id
        ) AS total_listings,
        (
            SELECT COUNT(*)
            FROM Listings l
            WHERE l.user_id = u.user_id
              AND l.status = 'ACTIVE'
        ) AS active_listings,
        (
            SELECT COUNT(*)
            FROM Transactions t
            WHERE t.buyer_id = u.user_id
              AND t.status = 'DONE'
        ) AS transactions_as_buyer,
        (
            SELECT COUNT(*)
            FROM Transactions t
            WHERE t.seller_id = u.user_id
              AND t.status = 'DONE'
        ) AS transactions_as_seller,
        (
            SELECT COALESCE(ROUND(AVG(r.score), 2), 0)
            FROM Ratings r
            WHERE r.ratee_id = u.user_id
        ) AS average_rating_received
    FROM Users u
    WHERE u.user_id = p_user_id
    LIMIT 1;
END$$

-- Event: expire_old_listings
-- WHAT: Runs once per day and expires active listings older than 90 days.
-- WHY: Stale listings should not remain available forever during demos.
-- MySQL handles the maintenance task automatically through its event scheduler.
-- Completed listings are left unchanged because they already finished normally.
CREATE EVENT expire_old_listings
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    UPDATE Listings
    SET status = 'EXPIRED'
    WHERE status = 'ACTIVE'
      AND available_qty > 0
      AND created_at < NOW() - INTERVAL 90 DAY;
END$$

DELIMITER ;
