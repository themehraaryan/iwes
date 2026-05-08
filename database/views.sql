USE iwes_db;

DROP VIEW IF EXISTS vw_recent_transactions;
DROP VIEW IF EXISTS vw_user_activity;
DROP VIEW IF EXISTS vw_top_waste_types;
DROP VIEW IF EXISTS vw_active_listings;

-- View: vw_active_listings
-- WHAT: Shows all active listings with user and product details joined in.
-- WHY: Flask and frontend pages should not repeat JOIN logic everywhere.
-- This is the main read model for browsing and filtering listings.
-- It keeps product category/unit and owner name easy to query.
CREATE VIEW vw_active_listings AS
SELECT
    l.listing_id,
    l.user_id,
    u.name AS user_name,
    u.email AS user_email,
    u.phone AS user_phone,
    l.product_id,
    p.name AS product_name,
    p.category,
    p.unit,
    p.possible_uses,
    l.listing_type,
    l.total_qty,
    l.available_qty,
    l.price_per_unit,
    l.location,
    l.status,
    l.created_at
FROM Listings l
INNER JOIN Users u ON u.user_id = l.user_id
INNER JOIN Products p ON p.product_id = l.product_id
WHERE l.status = 'ACTIVE';

-- View: vw_top_waste_types
-- WHAT: Aggregates transaction activity by product category.
-- WHY: The analytics page needs top waste categories without writing GROUP BY
-- logic in Flask. Categories with no transactions still appear with zero count.
-- This view supports simple chart/table queries during the viva.
CREATE VIEW vw_top_waste_types AS
SELECT
    p.category,
    COUNT(t.txn_id) AS transaction_count,
    COALESCE(SUM(t.qty_exchanged), 0) AS total_qty_exchanged
FROM Products p
LEFT JOIN Listings l ON l.product_id = p.product_id
LEFT JOIN Transactions t ON t.listing_id = l.listing_id
GROUP BY p.category
ORDER BY transaction_count DESC, total_qty_exchanged DESC, p.category ASC;

-- View: vw_user_activity
-- WHAT: Summarises listings and transactions for every user.
-- WHY: User-level analytics are easier to explain when stored as a database
-- view instead of scattered across Python route code.
-- It counts completed transactions separately as buyer and seller.
CREATE VIEW vw_user_activity AS
SELECT
    u.user_id,
    u.name,
    u.email,
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
FROM Users u;

-- View: vw_recent_transactions
-- WHAT: Shows recent transactions with buyer, seller, product, and listing data.
-- WHY: History and analytics pages need readable names, not just foreign keys.
-- The last-30-days filter keeps the view focused for dashboard use.
-- Flask can query this directly for transaction history.
CREATE VIEW vw_recent_transactions AS
SELECT
    t.txn_id,
    t.listing_id,
    t.buyer_id,
    buyer.name AS buyer_name,
    t.seller_id,
    seller.name AS seller_name,
    p.product_id,
    p.name AS product_name,
    p.category,
    p.unit,
    l.listing_type,
    t.qty_exchanged,
    t.status,
    t.txn_date
FROM Transactions t
INNER JOIN Listings l ON l.listing_id = t.listing_id
INNER JOIN Products p ON p.product_id = l.product_id
INNER JOIN Users buyer ON buyer.user_id = t.buyer_id
INNER JOIN Users seller ON seller.user_id = t.seller_id
WHERE t.txn_date >= NOW() - INTERVAL 30 DAY
ORDER BY t.txn_date DESC;
