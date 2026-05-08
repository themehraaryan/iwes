CREATE DATABASE IF NOT EXISTS iwes_db;
USE iwes_db;

CREATE TABLE IF NOT EXISTS Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(15),
    city VARCHAR(80) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    category VARCHAR(80) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    possible_uses TEXT,
    INDEX idx_product_category (category)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Listings (
    listing_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    product_id INT NOT NULL,
    listing_type ENUM('BUY','SELL') NOT NULL,
    total_qty DECIMAL(10,2) NOT NULL,
    available_qty DECIMAL(10,2) NOT NULL,
    price_per_unit DECIMAL(10,2),
    location VARCHAR(150),
    city VARCHAR(80) DEFAULT NULL,
    status ENUM('ACTIVE','COMPLETED','EXPIRED') DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_listing_total_qty CHECK (total_qty > 0),
    CONSTRAINT chk_listing_available_qty CHECK (available_qty >= 0 AND available_qty <= total_qty),
    CONSTRAINT fk_listings_user
        FOREIGN KEY (user_id) REFERENCES Users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_listings_product
        FOREIGN KEY (product_id) REFERENCES Products(product_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    INDEX idx_listing_cat_status (product_id, status),
    INDEX idx_listing_qty (available_qty)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Transactions (
    txn_id INT AUTO_INCREMENT PRIMARY KEY,
    listing_id INT NOT NULL,
    buyer_id INT NOT NULL,
    seller_id INT NOT NULL,
    qty_exchanged DECIMAL(10,2) NOT NULL,
    txn_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status ENUM('REQUESTED','ACCEPTED','IN_TRANSIT','DELIVERED','COMPLETED','CANCELLED') DEFAULT 'REQUESTED',
    CONSTRAINT chk_txn_qty CHECK (qty_exchanged > 0),
    CONSTRAINT fk_transactions_listing
        FOREIGN KEY (listing_id) REFERENCES Listings(listing_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_transactions_buyer
        FOREIGN KEY (buyer_id) REFERENCES Users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_transactions_seller
        FOREIGN KEY (seller_id) REFERENCES Users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    INDEX idx_txn_listing (listing_id),
    INDEX idx_txn_buyer (buyer_id)
) ENGINE=InnoDB;

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

CREATE TABLE IF NOT EXISTS WasteMapping (
    mapping_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    alternative_use VARCHAR(200) NOT NULL,
    industry VARCHAR(100),
    CONSTRAINT fk_wastemapping_product
        FOREIGN KEY (product_id) REFERENCES Products(product_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Ratings (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    txn_id INT NOT NULL,
    rater_id INT NOT NULL,
    ratee_id INT NOT NULL,
    score TINYINT NOT NULL,
    comment TEXT,
    rated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_rating_score CHECK (score BETWEEN 1 AND 5),
    CONSTRAINT fk_ratings_transaction
        FOREIGN KEY (txn_id) REFERENCES Transactions(txn_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_ratings_rater
        FOREIGN KEY (rater_id) REFERENCES Users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_ratings_ratee
        FOREIGN KEY (ratee_id) REFERENCES Users(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT uq_rating_once_per_user UNIQUE (txn_id, rater_id)
) ENGINE=InnoDB;
