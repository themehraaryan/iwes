# IWES — Technical Design Document
**Industrial Waste Exchange System**  
B.Tech IV Semester · DBMS Project · JIIT Noida

> This document lives in the project root. It is the **permanent reference** for what this system is, how it is designed, and why every decision was made. Codex reads this alongside `codex.md` before every session.

---

## 1. Aim

Design and implement a database-driven web system that connects industrial waste producers with potential consumers. A factory producing fly ash can list it as available. A cement manufacturer needing fly ash can find and transact with that factory — all managed through a relational MySQL database.

---

## 2. Problem Statement

Waste materials with economic value are discarded daily because there is no structured way to connect suppliers and buyers. This system solves that with a centralised, query-driven database that tracks listings, enables matching, and records transactions — while demonstrating every key DBMS concept covered in the course.

---

## 3. Features

### Core Features
- Dual-role users — same account can list waste to sell AND request waste to buy
- Waste/material listing system with quantity tracking (total vs. available)
- Browse and filter listings by category, listing type, and quantity range
- Demand-supply matching engine (runs entirely as a MySQL stored procedure)
- Partial fulfilment — one listing can be fulfilled by multiple transactions
- Transaction recording with full history per user
- User rating system after a transaction completes

### DBMS Showcase Features
- **Triggers** — auto-decrement available quantity and auto-complete listings on transaction insert; block overbooking before insert
- **Stored Procedures** — transaction creation, matching engine, user summary
- **Views** — analytics queries saved as database views, queried directly by Flask
- **Indexes** — optimised queries on category, status, available_qty
- **Scheduled Event** — auto-expire stale listings every night

### Additional Features
- Waste-to-usage mapping (e.g. fly ash → cement, wood waste → biomass energy)
- Analytics dashboard with top waste types, active listings, completion rates
- Sign-in / sign-out with session management

---

## 4. System Workflow

```
User registers → logs in → session created in Flask
     ↓
Creates a SELL listing (has waste) or BUY listing (needs waste)
     ↓
Other users browse listings → filter by category / qty
     ↓
User clicks "Find Matches" → calls match_listings stored procedure in MySQL
     ↓
User initiates transaction → calls create_transaction stored procedure
     ↓
TRIGGER fires automatically → reduces available_qty on listing
     ↓
If available_qty = 0 → trigger sets listing status = COMPLETED
     ↓
Both parties rate each other → Ratings table updated
     ↓
Analytics page → reads views → shows top waste types, stats, recent transactions
```

---

## 5. Technology Stack

| Layer | Technology | Why |
|---|---|---|
| Frontend | HTML5 · CSS3 · Vanilla JS · Fetch API | Simple, no hidden complexity, viva-friendly |
| Backend | Python · Flask · mysql-connector-python · bcrypt · Flask-Session | Lightweight, thin layer over MySQL |
| Database | MySQL 8.0 | Core of the project — triggers, procedures, views live here |
| Dev Tools | VS Code · MySQL Workbench · Postman | Standard CS student toolkit |
| Environment | Python venv · .env · .gitignore | Proper project hygiene |

> **Why no frontend framework?** React/Vue would hide the DBMS work under component complexity. With plain HTML + JS, every fetch call maps directly to a SQL operation — easy to trace and explain in a viva.

> **Why no ORM?** SQLAlchemy would abstract away the SQL. This is a DBMS project — the examiner wants to see raw SQL, stored procedure calls, and trigger logic. Flask calls `CALL procedure_name()` directly.

---

## 6. Folder Structure

```
iwes/
├── TECHNICAL_PLAN.md        ← this file — permanent reference for Codex and you
├── codex.md                 ← living project log — what is built, what is not, test steps
├── README.md                ← setup instructions
├── .env                     ← DB_HOST, DB_USER, DB_PASS, DB_NAME, SECRET_KEY
├── .gitignore
│
├── backend/
│   ├── app.py               ← Flask entry point + blueprint registration + session config
│   ├── db.py                ← MySQL connection helper (pool, execute query, call procedure)
│   ├── config.py            ← loads .env variables using python-dotenv
│   ├── utils.py             ← login_required decorator, shared helpers
│   ├── requirements.txt
│   └── routes/
│       ├── auth.py          ← /auth/register  /auth/login  /auth/logout  /auth/me
│       ├── listings.py      ← /listings (GET, POST, DELETE)  /listings/my
│       ├── transactions.py  ← /transact  /transactions/history
│       ├── match.py         ← /match
│       ├── analytics.py     ← /analytics/top-waste  /analytics/summary  /analytics/recent
│       └── ratings.py       ← /rate
│
├── frontend/
│   ├── login.html
│   ├── register.html
│   ├── dashboard.html
│   ├── listings.html
│   ├── match.html
│   ├── analytics.html
│   ├── style.css            ← shared stylesheet, colour palette, card layout
│   └── main.js              ← shared JS: checkLogin(), apiCall(), showToast()
│
└── database/
    ├── schema.sql           ← CREATE DATABASE + all 6 tables + FK constraints + indexes
    ├── triggers.sql         ← before_txn_insert + after_txn_insert
    ├── procedures.sql       ← create_transaction + match_listings + get_user_summary
    ├── views.sql            ← all 4 views
    └── seed_data.sql        ← 10 waste categories + 3 test users + sample listings
```

---

## 7. Database Schema

### 7.1 Entity Relationship Summary

```
Users ──< Listings >── Products
Users ──< Transactions
Listings ──< Transactions
Transactions ──< Ratings
Products ──< WasteMapping
```

### 7.2 Table Definitions

#### Users
```sql
user_id       INT AUTO_INCREMENT PRIMARY KEY
name          VARCHAR(100) NOT NULL
email         VARCHAR(150) UNIQUE NOT NULL
password_hash VARCHAR(255) NOT NULL          -- bcrypt hash, never plain text
phone         VARCHAR(15)
created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
```

#### Products  *(the waste catalogue — normalised out of Listings)*
```sql
product_id    INT AUTO_INCREMENT PRIMARY KEY
name          VARCHAR(100) NOT NULL           -- e.g. "Fly Ash"
category      VARCHAR(80) NOT NULL            -- e.g. "Industrial Byproduct"
unit          VARCHAR(20) NOT NULL            -- kg / litre / tonne
possible_uses TEXT                            -- brief description
```

#### Listings
```sql
listing_id      INT AUTO_INCREMENT PRIMARY KEY
user_id         INT NOT NULL REFERENCES Users(user_id)
product_id      INT NOT NULL REFERENCES Products(product_id)
listing_type    ENUM('BUY','SELL') NOT NULL
total_qty       DECIMAL(10,2) NOT NULL        -- original quantity
available_qty   DECIMAL(10,2) NOT NULL        -- decremented by trigger on each transaction
price_per_unit  DECIMAL(10,2)
location        VARCHAR(150)
status          ENUM('ACTIVE','COMPLETED','EXPIRED') DEFAULT 'ACTIVE'
created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
```

> `total_qty` never changes. `available_qty` is decremented by the `after_txn_insert` trigger. When `available_qty = 0`, the trigger sets `status = 'COMPLETED'` automatically.

#### Transactions
```sql
txn_id         INT AUTO_INCREMENT PRIMARY KEY
listing_id     INT NOT NULL REFERENCES Listings(listing_id)
buyer_id       INT NOT NULL REFERENCES Users(user_id)
seller_id      INT NOT NULL REFERENCES Users(user_id)
qty_exchanged  DECIMAL(10,2) NOT NULL
txn_date       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
status         ENUM('PENDING','DONE','CANCELLED') DEFAULT 'DONE'
```

#### WasteMapping  *(alternative use suggestions per product)*
```sql
mapping_id      INT AUTO_INCREMENT PRIMARY KEY
product_id      INT NOT NULL REFERENCES Products(product_id)
alternative_use VARCHAR(200) NOT NULL       -- e.g. "Used in cement production"
industry        VARCHAR(100)                -- e.g. "Construction"
```

#### Ratings
```sql
rating_id   INT AUTO_INCREMENT PRIMARY KEY
txn_id      INT NOT NULL REFERENCES Transactions(txn_id)
rater_id    INT NOT NULL REFERENCES Users(user_id)
ratee_id    INT NOT NULL REFERENCES Users(user_id)
score       TINYINT NOT NULL CHECK (score BETWEEN 1 AND 5)
comment     TEXT
rated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
```

### 7.3 Normalisation

All tables are in **3NF**:
- Every non-key attribute depends only on the primary key
- No transitive dependencies
- Products is separated from Listings to avoid repeating category/unit in every listing row

---

## 8. DBMS Features

> This section is the core of the project. Flask is intentionally thin — all logic lives here.

### 8.1 Triggers

#### `before_txn_insert` — BEFORE INSERT on Transactions
**What it does:** Checks that `qty_exchanged <= available_qty` on the corresponding listing before the transaction row is written. If not, raises a MySQL SIGNAL error which bubbles up to Flask and returns an error to the user.

**Why BEFORE:** The row does not exist yet — we need to reject it before it is written.

```sql
-- Purpose: Block overbooking at the database level.
-- Fires before every INSERT into Transactions.
-- Rejects the insert if requested qty exceeds what is available.
CREATE TRIGGER before_txn_insert
BEFORE INSERT ON Transactions
FOR EACH ROW
BEGIN
  DECLARE avail DECIMAL(10,2);
  SELECT available_qty INTO avail FROM Listings WHERE listing_id = NEW.listing_id;
  IF NEW.qty_exchanged > avail THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Requested quantity exceeds available quantity';
  END IF;
END;
```

#### `after_txn_insert` — AFTER INSERT on Transactions
**What it does:** After a transaction row is successfully inserted, decrements `available_qty` on the listing. If `available_qty` drops to 0, sets `status = 'COMPLETED'` on the listing.

**Why AFTER:** The transaction row now exists — we can safely update the listing based on it.

```sql
-- Purpose: Keep listing quantity accurate after every transaction.
-- Fires after every successful INSERT into Transactions.
-- Auto-completes listings when all stock is gone.
CREATE TRIGGER after_txn_insert
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN
  UPDATE Listings
  SET available_qty = available_qty - NEW.qty_exchanged
  WHERE listing_id = NEW.listing_id;

  UPDATE Listings
  SET status = 'COMPLETED'
  WHERE listing_id = NEW.listing_id AND available_qty <= 0;
END;
```

---

### 8.2 Stored Procedures

#### `create_transaction(p_listing_id, p_buyer_id, p_qty)`
Gets `seller_id` from the listing, then inserts into Transactions. The two triggers fire automatically inside this call.

**Why a procedure:** Flask calls `CALL create_transaction(...)` — one DB round trip. The trigger logic runs inside MySQL without any Python involved.

#### `match_listings(p_product_id, p_qty_needed)`
Returns SELL listings of the same product where `available_qty >= p_qty_needed`, ordered by `price_per_unit ASC`. This is the matching engine — entirely in MySQL.

**Why a procedure:** The matching logic stays in the database. Flask just passes parameters and returns the result set as JSON.

#### `get_user_summary(p_user_id)`
Returns in a single call: total listings created, count of transactions as buyer, count as seller, average rating received.

**Why a procedure:** Replaces three separate SELECT queries with one `CALL`.

---

### 8.3 Views

| View | What it does |
|---|---|
| `vw_active_listings` | JOIN of Listings + Users + Products filtered to `status = 'ACTIVE'`. Used by the listings page. |
| `vw_top_waste_types` | GROUP BY product category with COUNT of transactions, ordered DESC. Powers the analytics chart. |
| `vw_user_activity` | Per-user count of listings created and transactions completed. |
| `vw_recent_transactions` | Last 30 days of transactions with buyer name, seller name, product name, quantity exchanged. |

**Why views:** Flask queries them with `SELECT * FROM vw_active_listings WHERE ...` — no complex JOIN written in Python. Query logic lives in MySQL, Flask stays thin.

---

### 8.4 Indexes

```sql
INDEX idx_listing_cat_status ON Listings(category, status)
INDEX idx_listing_qty        ON Listings(available_qty)
INDEX idx_txn_listing        ON Transactions(listing_id)
INDEX idx_txn_buyer          ON Transactions(buyer_id)
```

**Why:** The listings page filters by category + status on every load. The match procedure filters by available_qty. Indexes make these queries fast even with thousands of rows.

---

### 8.5 Scheduled Event

```sql
-- Runs every night at midnight.
-- Marks listings older than 90 days with remaining stock as EXPIRED.
CREATE EVENT expire_old_listings
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
  UPDATE Listings
  SET status = 'EXPIRED'
  WHERE status = 'ACTIVE'
    AND available_qty > 0
    AND DATEDIFF(NOW(), created_at) > 90;
```

---

## 9. Flask API Routes

> Flask is a thin HTTP layer. Every route does: check session → call DB → return JSON. No business logic in Python.

| Route | Method | Auth | What it does |
|---|---|---|---|
| `/auth/register` | POST | No | Hash password with bcrypt, INSERT into Users |
| `/auth/login` | POST | No | Verify bcrypt hash, set `session['user_id']` |
| `/auth/logout` | POST | Yes | `session.clear()` |
| `/auth/me` | GET | Yes | Return current user info from session |
| `/listings` | GET | No | Query `vw_active_listings` with optional `?category=&type=&min_qty=` |
| `/listings/create` | POST | Yes | INSERT into Listings, `available_qty = total_qty` |
| `/listings/my` | GET | Yes | Return listings owned by current user |
| `/listings/<id>` | DELETE | Yes | Delete listing if owned by current user |
| `/products` | GET | No | Return all Products rows (for dropdowns) |
| `/match` | POST | Yes | `CALL match_listings(product_id, qty)` |
| `/transact` | POST | Yes | `CALL create_transaction(listing_id, buyer_id, qty)` |
| `/transactions/history` | GET | Yes | User's transaction history from `vw_recent_transactions` |
| `/analytics/top-waste` | GET | Yes | `SELECT * FROM vw_top_waste_types LIMIT 10` |
| `/analytics/summary` | GET | Yes | `CALL get_user_summary(user_id)` |
| `/analytics/recent` | GET | Yes | `SELECT * FROM vw_recent_transactions LIMIT 20` |
| `/rate` | POST | Yes | INSERT into Ratings |

---

## 10. Frontend Pages

| Page | What it shows | Key API calls |
|---|---|---|
| `login.html` | Email + password form | POST /auth/login |
| `register.html` | Name, email, password, phone | POST /auth/register |
| `dashboard.html` | Stat cards + user's listings + recent transactions | GET /auth/me, GET /listings/my, GET /transactions/history, GET /analytics/summary |
| `listings.html` | Filterable table of all active listings + create listing modal + transact button | GET /listings, POST /listings/create, POST /transact |
| `match.html` | Select product + enter qty → ranked matching SELL listings | POST /match, POST /transact |
| `analytics.html` | Bar chart of top waste types + personal stats + recent transactions table | GET /analytics/top-waste, GET /analytics/summary, GET /analytics/recent |

### Shared JS (`main.js`)
```javascript
checkLogin()       // reads sessionStorage, redirects to login.html if no user_id
apiCall(url, method, body)  // fetch wrapper with JSON headers + credentials
showToast(message, type)    // shows success/error notification, no alert()
```

### CSS Colour Palette
```
Primary:    #1F4E79  (deep blue)
Accent:     #0E6655  (teal)
Background: #F8F9FA  (off white)
Card:       #FFFFFF
Text:       #212529
Error:      #C0392B
Success:    #1E8449
```

---

## 11. Environment Setup

### `.env` file
```
DB_HOST=localhost
DB_USER=root
DB_PASS=yourpassword
DB_NAME=iwes_db
SECRET_KEY=any_random_string_here
```

### `.gitignore`
```
.env
venv/
__pycache__/
*.pyc
.DS_Store
*.docx
```

### `requirements.txt`
```
flask==3.0.3
mysql-connector-python==8.4.0
bcrypt==4.1.3
flask-session==0.8.0
python-dotenv==1.0.1
```

### First-time setup commands
```bash
cd iwes/backend
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt

# Load database (run in order)
mysql -u root -p < ../database/schema.sql
mysql -u root -p < ../database/triggers.sql
mysql -u root -p < ../database/procedures.sql
mysql -u root -p < ../database/views.sql
mysql -u root -p < ../database/seed_data.sql

python app.py
```

---

## 12. codex.md — The Project Brain

`codex.md` is a Markdown file in the project root. It is the **living context** for every coding session.

**Rules:**
- Every session starts by reading `codex.md`
- Every session ends by updating `codex.md`
- It tracks exactly what is built, what is not, and how to test the current state

### codex.md structure
```markdown
# IWES Codex
## Project State: SETUP / IN PROGRESS / COMPLETE

## What is built
- list of completed components

## What is NOT built yet
- remaining items

## File Inventory
- list of all files created so far

## DB Features Status
- Triggers: done / pending
- Procedures: done / pending
- Views: done / pending
- Event: done / pending

## Known Issues
- any bugs or incomplete items

## How to Test This Session
- exact step-by-step test instructions for what was just built

## Session Log
- [Session 1] date — summary
- [Session 2] date — summary
```

---

## 13. Viva Preparation

### Why this architecture?
Flask is thin because this is a **DBMS project** — the database should do the work. Triggers, procedures, and views demonstrate that the database handles business logic, not just storage.

### Key questions and answers

**Q: What is a trigger? Show me one.**
A: A trigger is a database object that executes automatically when a specific event (INSERT/UPDATE/DELETE) occurs on a table. Our `after_txn_insert` trigger fires after every transaction insert and automatically updates the listing's available quantity.

**Q: Why use a BEFORE trigger for validation?**
A: Because we need to reject the row before it is written to disk. A BEFORE trigger runs before the INSERT completes, so we can raise a SIGNAL error that cancels the operation.

**Q: What does the matching stored procedure do?**
A: `match_listings(product_id, qty_needed)` runs inside MySQL and returns all active SELL listings of the same product where `available_qty >= qty_needed`, ordered by price. Flask passes the parameters and returns the result — no matching logic in Python.

**Q: Why normalise Products into a separate table?**
A: To avoid repeating `category`, `unit`, and `possible_uses` in every Listings row. If a category name changes, we update one row in Products, not hundreds in Listings. This is 3NF.

**Q: What is `available_qty` vs `total_qty`?**
A: `total_qty` is the original amount listed — it never changes. `available_qty` starts equal to `total_qty` and is decremented by the `after_txn_insert` trigger every time a transaction is made against that listing.

**Q: What does your analytics page query?**
A: It queries four MySQL views — `vw_top_waste_types`, `vw_user_activity`, `vw_recent_transactions`. The views are pre-defined JOINs and GROUP BYs stored in MySQL. Flask does `SELECT * FROM vw_top_waste_types` — one line of Python, the complex query lives in the database.

---

*IWES — Technical Design Document · JIIT Noida · B.Tech IV Semester*
