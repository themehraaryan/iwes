USE iwes_db;

INSERT INTO Products (product_id, name, category, unit, possible_uses) VALUES
(1, 'Fly Ash', 'Industrial Byproduct', 'tonne', 'Used in cement, bricks, road base, and concrete blocks.'),
(2, 'Wood Waste', 'Biomass', 'kg', 'Used for biomass fuel, particle board, compost bulking, and pallets.'),
(3, 'Organic Waste', 'Biodegradable', 'kg', 'Used for composting, biogas generation, and soil conditioners.'),
(4, 'Scrap Metal', 'Metal', 'kg', 'Used for recycling, foundry feedstock, and fabrication.'),
(5, 'Plastic', 'Polymer', 'kg', 'Used for recycling, plastic lumber, packaging reuse, and pellets.'),
(6, 'Glass', 'Inert Material', 'kg', 'Used for glass recycling, tiles, aggregates, and insulation material.'),
(7, 'Rubber', 'Polymer', 'kg', 'Used for crumb rubber, mats, tyre-derived fuel, and playground flooring.'),
(8, 'Slag', 'Industrial Byproduct', 'tonne', 'Used in cement blending, road construction, and aggregate replacement.'),
(9, 'Textile Waste', 'Fabric', 'kg', 'Used for insulation, wiping cloth, fibre recovery, and upcycled products.'),
(10, 'Paper', 'Recyclable', 'kg', 'Used for paper recycling, packaging, pulp recovery, and compost carbon balance.')
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    category = VALUES(category),
    unit = VALUES(unit),
    possible_uses = VALUES(possible_uses);

INSERT INTO Users (user_id, name, email, password_hash, phone, city) VALUES
(1, 'Aarav Metals', 'aarav.metals@example.com', '$2b$12$YE4Ge3ZYzgY/A0qYZLSanO.8Ha8tgu5B9DwQ1I.Xcd7LgmHEbT61W', '9876543210', 'Noida'),
(2, 'Noida Cement Works', 'cement.works@example.com', '$2b$12$Gxd4iToQ.Y0pWoxbxRT73ukvIVkqfiYHDYm6XgEOXDkeQvjEaOAdS', '9876543211', 'Greater Noida'),
(3, 'Green Bio Energy', 'green.bio@example.com', '$2b$12$Gh3w7OIcsKjsusV2HgIyK.t7mUYqSaDXQDVmIh/kfn59HSWQPou.u', '9876543212', 'Ghaziabad'),
(4, 'NCR Plastics Recycler', 'ncr.plastics@example.com', '$2b$12$YE4Ge3ZYzgY/A0qYZLSanO.8Ha8tgu5B9DwQ1I.Xcd7LgmHEbT61W', '9876543213', 'Noida'),
(5, 'EcoBrick Solutions', 'ecobrick@example.com', '$2b$12$Gxd4iToQ.Y0pWoxbxRT73ukvIVkqfiYHDYm6XgEOXDkeQvjEaOAdS', '9876543214', 'Dadri'),
(6, 'Urban Timber Works', 'urban.timber@example.com', '$2b$12$Gh3w7OIcsKjsusV2HgIyK.t7mUYqSaDXQDVmIh/kfn59HSWQPou.u', '9876543215', 'Hapur'),
(7, 'Shakti Paper Mills', 'shakti.paper@example.com', '$2b$12$YE4Ge3ZYzgY/A0qYZLSanO.8Ha8tgu5B9DwQ1I.Xcd7LgmHEbT61W', '9876543216', 'Sahibabad'),
(8, 'Metro Glass Recyclers', 'metro.glass@example.com', '$2b$12$Gxd4iToQ.Y0pWoxbxRT73ukvIVkqfiYHDYm6XgEOXDkeQvjEaOAdS', '9876543217', 'Greater Noida')
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    email = VALUES(email),
    password_hash = VALUES(password_hash),
    phone = VALUES(phone),
    city = VALUES(city);

INSERT INTO Listings (
    listing_id,
    user_id,
    product_id,
    listing_type,
    total_qty,
    available_qty,
    price_per_unit,
    location,
    city,
    status
) VALUES
(1, 1, 4, 'SELL', 500.00, 500.00, 42.00, 'Noida Sector 63', 'Noida', 'ACTIVE'),
(2, 2, 1, 'BUY', 1000.00, 1000.00, 800.00, 'Greater Noida', 'Greater Noida', 'ACTIVE'),
(3, 3, 3, 'SELL', 750.00, 750.00, 6.50, 'Ghaziabad Industrial Area', 'Ghaziabad', 'ACTIVE'),
(4, 1, 5, 'SELL', 300.00, 300.00, 18.00, 'Dadri', 'Dadri', 'ACTIVE'),
(5, 2, 8, 'SELL', 1200.00, 1200.00, 650.00, 'Noida Sector 80', 'Noida', 'ACTIVE'),
(6, 5, 1, 'SELL', 1800.00, 1800.00, 760.00, 'Sikandrabad', 'Sikandrabad', 'ACTIVE'),
(7, 7, 10, 'SELL', 900.00, 900.00, 11.50, 'Sahibabad Site 4', 'Sahibabad', 'ACTIVE'),
(8, 4, 5, 'BUY', 650.00, 650.00, 20.00, 'Noida Sector 65', 'Noida', 'ACTIVE'),
(9, 7, 9, 'SELL', 420.00, 420.00, 9.00, 'Meerut Road Industrial Area', 'Meerut', 'ACTIVE'),
(10, 8, 6, 'SELL', 700.00, 700.00, 4.75, 'Greater Noida West', 'Greater Noida', 'ACTIVE'),
(11, 5, 2, 'BUY', 1100.00, 1100.00, 5.25, 'Bulandshahr Road', 'Bulandshahr', 'ACTIVE'),
(12, 6, 2, 'SELL', 1400.00, 1400.00, 4.80, 'Hapur Road', 'Hapur', 'ACTIVE'),
(13, 6, 4, 'BUY', 900.00, 900.00, 40.00, 'Loni Industrial Area', 'Loni', 'ACTIVE'),
(14, 7, 10, 'SELL', 1600.00, 1600.00, 10.75, 'Modinagar', 'Modinagar', 'ACTIVE'),
(15, 8, 6, 'BUY', 500.00, 500.00, 5.10, 'Surajpur', 'Surajpur', 'ACTIVE'),
(16, 5, 1, 'BUY', 2500.00, 2500.00, 790.00, 'Dadri Eco Park', 'Dadri', 'ACTIVE'),
(17, 4, 7, 'SELL', 330.00, 330.00, 13.50, 'Noida Sector 10', 'Noida', 'ACTIVE'),
(18, 3, 3, 'SELL', 200.00, 200.00, 5.90, 'Ghaziabad Industrial Area', 'Ghaziabad', 'EXPIRED')
ON DUPLICATE KEY UPDATE
    user_id = VALUES(user_id),
    product_id = VALUES(product_id),
    listing_type = VALUES(listing_type),
    total_qty = VALUES(total_qty),
    available_qty = VALUES(available_qty),
    price_per_unit = VALUES(price_per_unit),
    location = VALUES(location),
    city = VALUES(city),
    status = VALUES(status);

INSERT INTO Transactions (
    txn_id,
    listing_id,
    buyer_id,
    seller_id,
    qty_exchanged,
    status
) VALUES
(1, 1, 2, 1, 120.00, 'COMPLETED'),
(2, 2, 2, 1, 200.00, 'COMPLETED'),
(3, 3, 5, 3, 150.00, 'COMPLETED'),
(4, 4, 4, 1, 80.00, 'COMPLETED'),
(5, 5, 5, 2, 250.00, 'COMPLETED'),
(6, 6, 2, 5, 300.00, 'COMPLETED'),
(7, 7, 4, 7, 240.00, 'COMPLETED'),
(8, 8, 4, 1, 100.00, 'COMPLETED'),
(9, 10, 5, 8, 160.00, 'COMPLETED'),
(10, 11, 5, 6, 300.00, 'COMPLETED'),
(11, 12, 3, 6, 200.00, 'COMPLETED'),
(12, 17, 6, 4, 330.00, 'COMPLETED')
ON DUPLICATE KEY UPDATE
    listing_id = VALUES(listing_id),
    buyer_id = VALUES(buyer_id),
    seller_id = VALUES(seller_id),
    qty_exchanged = VALUES(qty_exchanged),
    status = VALUES(status);

UPDATE Listings SET available_qty = 380.00, status = 'ACTIVE' WHERE listing_id = 1;
UPDATE Listings SET available_qty = 800.00, status = 'ACTIVE' WHERE listing_id = 2;
UPDATE Listings SET available_qty = 600.00, status = 'ACTIVE' WHERE listing_id = 3;
UPDATE Listings SET available_qty = 220.00, status = 'ACTIVE' WHERE listing_id = 4;
UPDATE Listings SET available_qty = 950.00, status = 'ACTIVE' WHERE listing_id = 5;
UPDATE Listings SET available_qty = 1500.00, status = 'ACTIVE' WHERE listing_id = 6;
UPDATE Listings SET available_qty = 660.00, status = 'ACTIVE' WHERE listing_id = 7;
UPDATE Listings SET available_qty = 550.00, status = 'ACTIVE' WHERE listing_id = 8;
UPDATE Listings SET available_qty = 420.00, status = 'ACTIVE' WHERE listing_id = 9;
UPDATE Listings SET available_qty = 540.00, status = 'ACTIVE' WHERE listing_id = 10;
UPDATE Listings SET available_qty = 800.00, status = 'ACTIVE' WHERE listing_id = 11;
UPDATE Listings SET available_qty = 1200.00, status = 'ACTIVE' WHERE listing_id = 12;
UPDATE Listings SET available_qty = 900.00, status = 'ACTIVE' WHERE listing_id = 13;
UPDATE Listings SET available_qty = 1600.00, status = 'ACTIVE' WHERE listing_id = 14;
UPDATE Listings SET available_qty = 500.00, status = 'ACTIVE' WHERE listing_id = 15;
UPDATE Listings SET available_qty = 2500.00, status = 'ACTIVE' WHERE listing_id = 16;
UPDATE Listings SET available_qty = 0.00, status = 'COMPLETED' WHERE listing_id = 17;
UPDATE Listings SET available_qty = 200.00, status = 'EXPIRED' WHERE listing_id = 18;

INSERT INTO Ratings (rating_id, txn_id, rater_id, ratee_id, score, comment) VALUES
(1, 1, 2, 1, 5, 'Good quality scrap and quick handover.'),
(2, 1, 1, 2, 4, 'Payment and pickup were smooth.'),
(3, 2, 2, 1, 4, 'Fly ash supply matched the requirement.'),
(4, 3, 5, 3, 5, 'Organic waste was well segregated.'),
(5, 4, 4, 1, 4, 'Plastic was clean enough for reprocessing.'),
(6, 5, 5, 2, 5, 'Slag quantity and documentation were clear.'),
(7, 6, 2, 5, 4, 'Consistent fly ash supply.'),
(8, 7, 4, 7, 5, 'Paper waste was sorted properly.'),
(9, 8, 4, 1, 4, 'Useful plastic feedstock.'),
(10, 9, 5, 8, 5, 'Glass cullet was ready for reuse.'),
(11, 10, 5, 6, 4, 'Wood waste pickup was on time.'),
(12, 11, 3, 6, 5, 'Good biomass fuel material.'),
(13, 12, 6, 4, 4, 'Rubber stock was accurately listed.')
ON DUPLICATE KEY UPDATE
    txn_id = VALUES(txn_id),
    rater_id = VALUES(rater_id),
    ratee_id = VALUES(ratee_id),
    score = VALUES(score),
    comment = VALUES(comment);

INSERT INTO WasteMapping (mapping_id, product_id, alternative_use, industry) VALUES
(1, 1, 'Cement and concrete additive', 'Construction'),
(2, 2, 'Biomass boiler fuel', 'Energy'),
(3, 3, 'Biogas feedstock', 'Renewable Energy'),
(4, 4, 'Metal recycling feedstock', 'Manufacturing'),
(5, 5, 'Reprocessed plastic pellets', 'Packaging'),
(6, 6, 'Recycled glass aggregate', 'Construction'),
(7, 7, 'Crumb rubber flooring', 'Civil Works'),
(8, 8, 'Cement clinker substitute', 'Construction'),
(9, 9, 'Recovered fibre insulation', 'Textiles'),
(10, 10, 'Recycled paper pulp', 'Paper Manufacturing')
ON DUPLICATE KEY UPDATE
    product_id = VALUES(product_id),
    alternative_use = VALUES(alternative_use),
    industry = VALUES(industry);
