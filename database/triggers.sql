USE iwes_db;

DROP TRIGGER IF EXISTS before_txn_insert;
DROP TRIGGER IF EXISTS after_txn_insert;

DELIMITER $$

-- Trigger: before_txn_insert
-- WHAT: Validates every transaction before it is saved.
-- WHY: Quantity overbooking must be blocked inside MySQL, not in Flask.
-- It rejects missing, inactive, completed, expired, or insufficient listings.
-- This keeps listing stock/demand reliable even if data is inserted outside the app.
CREATE TRIGGER before_txn_insert
BEFORE INSERT ON Transactions
FOR EACH ROW
BEGIN
    DECLARE v_available_qty DECIMAL(10,2);
    DECLARE v_status ENUM('ACTIVE','COMPLETED','EXPIRED');

    SELECT available_qty, status
    INTO v_available_qty, v_status
    FROM Listings
    WHERE listing_id = NEW.listing_id;

    IF v_available_qty IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Listing does not exist';
    END IF;

    IF v_status <> 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Listing is not active';
    END IF;

    IF NEW.qty_exchanged <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Transaction quantity must be greater than zero';
    END IF;

    IF NEW.qty_exchanged > v_available_qty THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Requested quantity exceeds available quantity';
    END IF;
END$$

-- Trigger: after_txn_insert
-- WHAT: Updates the listing after a transaction is inserted.
-- WHY: total_qty should never change, but available_qty must reduce automatically.
-- When the remaining quantity reaches zero, the listing is marked COMPLETED.
-- This also creates a DB-level notification for the seller on new requests.
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
