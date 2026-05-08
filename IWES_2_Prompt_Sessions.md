**IWES — Prompt Sessions**

8 Phased Coding Sessions for Codex

Use one session at a time. Always read codex.md first. Always update it last.


## **Session Overview**

|**#**|**What gets built**|
| :- | :- |
|**Session 1**|Project Setup & Scaffolding|
|**Session 2**|MySQL Schema — All Tables + Seed Data|
|**Session 3**|DBMS Features — Triggers, Procedures, Views, Event|
|**Session 4**|Flask Backend — Auth & Listings Routes|
|**Session 5**|Flask Backend — Transactions, Match & Analytics|
|**Session 6**|Frontend — Login, Register & Dashboard|
|**Session 7**|Frontend — Listings, Match & Analytics Pages|
|**Session 8**|Polish, Testing & Viva Prep|

|<p>**Rule for every session**</p><p>Read codex.md FIRST → Build → Test → Update codex.md LAST. Never skip the codex update — it is how the next session knows where to continue.</p>|
| :- |



|<p>**Session 1**</p><p>**Project Setup & Scaffolding**</p>|
| :- |

|<p>**Goal**</p><p>Create the complete folder structure, environment files, codex.md, and confirm everything runs with a test Flask route.</p>|
| :- |

**What to build in this session**

- Create the full folder structure: backend/, frontend/, database/
- Create .env with DB credentials placeholder and SECRET\_KEY
- Create .gitignore (venv, .env, \_\_pycache\_\_, .DS\_Store)
- Create requirements.txt with all dependencies
- Create venv and install requirements
- Create backend/db.py — MySQL connection helper using mysql-connector-python and .env
- Create backend/config.py — loads .env with python-dotenv
- Create backend/app.py — Flask app skeleton with one test route GET /ping that returns {status: ok}
- Create codex.md with initial structure (all sections blank/pending)
- Create README.md with setup instructions

**How to test**

1. Activate venv, run python app.py
1. Open browser to http://localhost:5000/ping — should return {"status": "ok"}
1. Confirm .env is not tracked by git (git status should not show it)

|<p>**Codex update — end of this session**</p><p>Mark Setup as DONE. List all files created. Note DB connection not yet tested.</p>|
| :- |

**Prompt to use with Codex**

[PASTE PROMPT PREAMBLE HERE]

SESSION 1: PROJECT SETUP & SCAFFOLDING

Goal: Create the complete folder structure, environment files, codex.md, and confirm everything runs with a test Flask route.

Please build the following in this session:

1\. Create the full folder structure: backend/, frontend/, database/

2\. Create .env with DB credentials placeholder and SECRET\_KEY

3\. Create .gitignore (venv, .env, \_\_pycache\_\_, .DS\_Store)

4\. Create requirements.txt with all dependencies

5\. Create venv and install requirements

6\. Create backend/db.py — MySQL connection helper using mysql-connector-python and .env

7\. Create backend/config.py — loads .env with python-dotenv

8\. Create backend/app.py — Flask app skeleton with one test route GET /ping that returns {status: ok}

9\. Create codex.md with initial structure (all sections blank/pending)

10\. Create README.md with setup instructions

At the end of this session, update codex.md: Mark Setup as DONE. List all files created. Note DB connection not yet tested.




|<p>**Session 2**</p><p>**MySQL Schema — All Tables**</p>|
| :- |

|<p>**Goal**</p><p>Create the full database with all 6 tables, foreign key constraints, and indexes. Run seed data.</p>|
| :- |

**What to build in this session**

- Create database/schema.sql — CREATE DATABASE iwes\_db, then all 6 tables: Users, Products, Listings, Transactions, WasteMapping, Ratings
- Add FK constraints on all foreign keys with ON DELETE CASCADE where appropriate
- Add indexes: idx\_listing\_cat\_status on Listings(category, status), idx\_listing\_qty on Listings(available\_qty), idx\_txn\_listing on Transactions(listing\_id), idx\_txn\_buyer on Transactions(buyer\_id)
- Create database/seed\_data.sql — 10 waste categories in Products (fly ash, wood waste, organic waste, scrap metal, plastic, glass, rubber, slag, textile waste, paper), 3 test users (already hashed passwords for testing), 5 sample listings
- Update backend/db.py to test the connection on startup and log success

**How to test**

1. Run: mysql -u root -p < database/schema.sql
1. Run: mysql -u root -p < database/seed\_data.sql
1. Open MySQL Workbench, verify all 6 tables exist with correct columns
1. Run SELECT \* FROM Products — should show 10 waste categories
1. Run SHOW INDEX FROM Listings — verify indexes created
1. Start Flask, check terminal shows DB connection success

|<p>**Codex update — end of this session**</p><p>Mark Schema as DONE. List all 6 tables and their columns. Note seed data loaded.</p>|
| :- |

**Prompt to use with Codex**

[PASTE PROMPT PREAMBLE HERE]

SESSION 2: MYSQL SCHEMA — ALL TABLES

Goal: Create the full database with all 6 tables, foreign key constraints, and indexes. Run seed data.

Please build the following in this session:

1\. Create database/schema.sql — CREATE DATABASE iwes\_db, then all 6 tables: Users, Products, Listings, Transactions, WasteMapping, Ratings

2\. Add FK constraints on all foreign keys with ON DELETE CASCADE where appropriate

3\. Add indexes: idx\_listing\_cat\_status on Listings(category, status), idx\_listing\_qty on Listings(available\_qty), idx\_txn\_listing on Transactions(listing\_id), idx\_txn\_buyer on Transactions(buyer\_id)

4\. Create database/seed\_data.sql — 10 waste categories in Products (fly ash, wood waste, organic waste, scrap metal, plastic, glass, rubber, slag, textile waste, paper), 3 test users (already hashed passwords for testing), 5 sample listings

5\. Update backend/db.py to test the connection on startup and log success

At the end of this session, update codex.md: Mark Schema as DONE. List all 6 tables and their columns. Note seed data loaded.




|<p>**Session 3**</p><p>**DBMS Features — Triggers, Procedures, Views, Event**</p>|
| :- |

|<p>**Goal**</p><p>Implement all MySQL DBMS features. This is the core of the project.</p>|
| :- |

**What to build in this session**

- Create database/triggers.sql:
  - TRIGGER before\_txn\_insert: BEFORE INSERT on Transactions, check qty\_exchanged <= available\_qty, SIGNAL if not
  - TRIGGER after\_txn\_insert: AFTER INSERT on Transactions, UPDATE Listings SET available\_qty = available\_qty - qty\_exchanged WHERE listing\_id = NEW.listing\_id, then if available\_qty = 0 set status = COMPLETED
- Create database/procedures.sql:
  - PROCEDURE create\_transaction(IN p\_listing\_id INT, IN p\_buyer\_id INT, IN p\_qty DECIMAL) — gets seller\_id from listing, inserts into Transactions, triggers handle the rest
  - PROCEDURE match\_listings(IN p\_product\_id INT, IN p\_qty DECIMAL) — SELECT from vw\_active\_listings where product\_id matches and available\_qty >= p\_qty ORDER BY price\_per\_unit ASC
  - PROCEDURE get\_user\_summary(IN p\_user\_id INT) — SELECT COUNT of listings, transactions as buyer/seller, AVG rating
- Create database/views.sql:
  - VIEW vw\_active\_listings: JOIN Listings + Users + Products WHERE status = ACTIVE
  - VIEW vw\_top\_waste\_types: GROUP BY product category with COUNT of transactions
  - VIEW vw\_user\_activity: per-user listing and transaction counts
  - VIEW vw\_recent\_transactions: last 30 days with buyer/seller/product names
- Add scheduled EVENT expire\_old\_listings (runs daily, sets status=EXPIRED for listings > 90 days old)

**How to test**

1. Run all .sql files in order
1. In MySQL Workbench: SHOW TRIGGERS — verify 2 triggers
1. SHOW PROCEDURE STATUS WHERE Db = 'iwes\_db' — verify 3 procedures
1. SHOW FULL TABLES WHERE Table\_type = 'VIEW' — verify 4 views
1. Test trigger: manually INSERT a transaction with qty > available\_qty — should fail with error
1. Test trigger: INSERT a valid transaction — SELECT from Listings to confirm available\_qty decreased
1. CALL match\_listings(1, 100) — should return matching SELL listings
1. SELECT \* FROM vw\_active\_listings LIMIT 5 — should return seeded listings

|<p>**Codex update — end of this session**</p><p>Mark all DBMS features as DONE. List all triggers, procedures, views by name. Note test results.</p>|
| :- |

**Prompt to use with Codex**

[PASTE PROMPT PREAMBLE HERE]

SESSION 3: DBMS FEATURES — TRIGGERS, PROCEDURES, VIEWS, EVENT

Goal: Implement all MySQL DBMS features. This is the core of the project.

Please build the following in this session:

1\. Create database/triggers.sql:

2\. Create database/procedures.sql:

3\. Create database/views.sql:

4\. Add scheduled EVENT expire\_old\_listings (runs daily, sets status=EXPIRED for listings > 90 days old)

At the end of this session, update codex.md: Mark all DBMS features as DONE. List all triggers, procedures, views by name. Note test results.




|<p>**Session 4**</p><p>**Flask Backend — Auth & Listings Routes**</p>|
| :- |

|<p>**Goal**</p><p>Build the authentication system and listing CRUD endpoints. Flask talks to MySQL through db.py.</p>|
| :- |

**What to build in this session**

- Create backend/routes/auth.py:
  - POST /auth/register: validate input, hash password with bcrypt, INSERT into Users, return {message, user\_id}
  - POST /auth/login: SELECT user by email, verify bcrypt hash, set session['user\_id'], return {message, user\_id, name}
  - POST /auth/logout: session.clear(), return {message: logged out}
  - GET /auth/me: return current session user info (used by frontend to check login state)
- Create backend/routes/listings.py:
  - GET /listings: query vw\_active\_listings with optional filters ?category=&type=&min\_qty=, return JSON array
  - POST /listings/create: require login, INSERT into Listings, available\_qty = total\_qty on create
  - DELETE /listings/<id>: require login, only allow if listing belongs to current user
  - GET /listings/my: return all listings created by current user
- Create backend/routes/products.py: GET /products — return all rows from Products table (for dropdowns in frontend)
- Register all blueprints in app.py, add CORS header for local development
- Add a login\_required decorator in a shared utils.py

**How to test**

1. Use Postman or curl:
1. POST /auth/register with {name, email, password} — should return success
1. POST /auth/login with same credentials — should return user\_id
1. GET /listings — should return active listings from seed data
1. POST /listings/create with valid body — listing appears in GET /listings
1. DELETE /listings/<id> — listing removed, test with wrong user\_id for rejection
1. GET /auth/me — returns current user or 401 if not logged in

|<p>**Codex update — end of this session**</p><p>Mark Auth and Listings routes as DONE. Note any route that is not yet working.</p>|
| :- |

**Prompt to use with Codex**

[PASTE PROMPT PREAMBLE HERE]

SESSION 4: FLASK BACKEND — AUTH & LISTINGS ROUTES

Goal: Build the authentication system and listing CRUD endpoints. Flask talks to MySQL through db.py.

Please build the following in this session:

1\. Create backend/routes/auth.py:

2\. Create backend/routes/listings.py:

3\. Create backend/routes/products.py: GET /products — return all rows from Products table (for dropdowns in frontend)

4\. Register all blueprints in app.py, add CORS header for local development

5\. Add a login\_required decorator in a shared utils.py

At the end of this session, update codex.md: Mark Auth and Listings routes as DONE. Note any route that is not yet working.




|<p>**Session 5**</p><p>**Flask Backend — Transactions, Match & Analytics**</p>|
| :- |

|<p>**Goal**</p><p>Complete the backend. Wire stored procedures and views to Flask routes.</p>|
| :- |

**What to build in this session**

- Create backend/routes/transactions.py:
  - POST /transact: require login, CALL create\_transaction(listing\_id, buyer\_id, qty), return result
  - GET /transactions/history: SELECT from vw\_recent\_transactions WHERE buyer\_id or seller\_id = current user
- Create backend/routes/match.py:
  - POST /match: require login, CALL match\_listings(product\_id, qty), return JSON of matching listings
- Create backend/routes/analytics.py:
  - GET /analytics/top-waste: SELECT \* FROM vw\_top\_waste\_types LIMIT 10
  - GET /analytics/summary: CALL get\_user\_summary(current user\_id), return stats
  - GET /analytics/recent: SELECT \* FROM vw\_recent\_transactions LIMIT 20
- Create backend/routes/ratings.py: POST /rate — INSERT into Ratings, check txn belongs to rater
- Register all new blueprints in app.py

**How to test**

1. POST /transact with a valid listing\_id and qty — check Listings.available\_qty decreased
1. POST /transact with qty > available\_qty — should return error (trigger blocked it)
1. POST /match with product\_id and qty — returns matching SELL listings
1. GET /transactions/history — returns user's past transactions
1. GET /analytics/top-waste — returns waste categories ordered by demand
1. GET /analytics/summary — returns personal stats

|<p>**Codex update — end of this session**</p><p>Mark all backend routes as DONE. Confirm all stored procedure calls work. List any known edge cases.</p>|
| :- |

**Prompt to use with Codex**

[PASTE PROMPT PREAMBLE HERE]

SESSION 5: FLASK BACKEND — TRANSACTIONS, MATCH & ANALYTICS

Goal: Complete the backend. Wire stored procedures and views to Flask routes.

Please build the following in this session:

1\. Create backend/routes/transactions.py:

2\. Create backend/routes/match.py:

3\. Create backend/routes/analytics.py:

4\. Create backend/routes/ratings.py: POST /rate — INSERT into Ratings, check txn belongs to rater

5\. Register all new blueprints in app.py

At the end of this session, update codex.md: Mark all backend routes as DONE. Confirm all stored procedure calls work. List any known edge cases.




|<p>**Session 6**</p><p>**Frontend — Login, Register & Dashboard**</p>|
| :- |

|<p>**Goal**</p><p>Build the first three pages with professional styling. All forms call the Flask API using Fetch.</p>|
| :- |

**What to build in this session**

- Create frontend/style.css — colour palette: deep blue (#1F4E79) primary, white background, clean card layout, responsive grid, form styles, button hover states, notification toasts
- Create frontend/main.js — shared utilities: checkLogin() redirects to login if no session, apiCall(url, method, body) wrapper for fetch with JSON + credentials, showToast(message, type) for success/error messages
- Create frontend/login.html — clean centred card with email + password fields, Log In button, link to register. On success, save user to sessionStorage, redirect to dashboard.
- Create frontend/register.html — name, email, password, phone fields. On success redirect to login.
- Create frontend/dashboard.html — top navbar with user name + logout button. Three stat cards from GET /analytics/summary (listings created, total transactions, avg rating). Table of GET /listings/my (user's own listings). Table of GET /transactions/history (recent 5). All data loaded via fetch on page load.

**How to test**

1. Open login.html in browser (serve with python -m http.server from frontend/)
1. Register a new user, verify they appear in MySQL Users table
1. Log in, verify redirect to dashboard
1. Dashboard loads with real data from Flask
1. Logout clears session and redirects to login
1. Refresh dashboard after logout — should redirect to login (auth check works)

|<p>**Codex update — end of this session**</p><p>Mark first 3 frontend pages as DONE. Note any CSS or API issues encountered.</p>|
| :- |

**Prompt to use with Codex**

[PASTE PROMPT PREAMBLE HERE]

SESSION 6: FRONTEND — LOGIN, REGISTER & DASHBOARD

Goal: Build the first three pages with professional styling. All forms call the Flask API using Fetch.

Please build the following in this session:

1\. Create frontend/style.css — colour palette: deep blue (#1F4E79) primary, white background, clean card layout, responsive grid, form styles, button hover states, notification toasts

2\. Create frontend/main.js — shared utilities: checkLogin() redirects to login if no session, apiCall(url, method, body) wrapper for fetch with JSON + credentials, showToast(message, type) for success/error messages

3\. Create frontend/login.html — clean centred card with email + password fields, Log In button, link to register. On success, save user to sessionStorage, redirect to dashboard.

4\. Create frontend/register.html — name, email, password, phone fields. On success redirect to login.

5\. Create frontend/dashboard.html — top navbar with user name + logout button. Three stat cards from GET /analytics/summary (listings created, total transactions, avg rating). Table of GET /listings/my (user's own listings). Table of GET /transactions/history (recent 5). All data loaded via fetch on page load.

At the end of this session, update codex.md: Mark first 3 frontend pages as DONE. Note any CSS or API issues encountered.




|<p>**Session 7**</p><p>**Frontend — Listings, Match & Analytics Pages**</p>|
| :- |

|<p>**Goal**</p><p>Complete the frontend. Build the three functional pages that show off the DBMS features.</p>|
| :- |

**What to build in this session**

- Create frontend/listings.html:
  - Filter bar: Category dropdown (populated from GET /products), Type (BUY/SELL), Min Qty input, Apply button
  - Results table showing listing owner, category, qty available, price, a Transact button
  - Transact modal: enter qty, confirm — calls POST /transact, shows success toast
  - Create Listing button opens a modal: select product, choose BUY/SELL, enter qty, price, location
  - After creating or transacting, reload the listings table
- Create frontend/match.html:
  - Dropdown to select waste category/product, input for qty needed
  - Find Matches button calls POST /match
  - Results shown as cards with seller info, price, available qty, Transact button
  - WasteMapping suggestions shown below (call GET /products/<id>/uses)
- Create frontend/analytics.html:
  - Horizontal bar chart using plain canvas API showing top 10 waste types by transaction count (from GET /analytics/top-waste)
  - My Stats card: listings, transactions, avg rating (from GET /analytics/summary)
  - Recent Transactions table with pagination (from GET /analytics/recent)
  - Active vs Completed listing count (quick SQL count in a new small endpoint)
- Update navbar in all pages to link to all 6 pages

**How to test**

1. listings.html — filter by category, results update correctly
1. Create a listing, it appears in the table
1. Transact on a listing — check qty decreased in MySQL
1. Try to transact more than available — shows error toast (trigger fired)
1. match.html — search for a category, matching sellers appear
1. analytics.html — bar chart renders with real data
1. All pages redirect to login when not authenticated

|<p>**Codex update — end of this session**</p><p>Mark ALL frontend as DONE. Note any pending bug fixes. Write final test checklist. Update project state to COMPLETE.</p>|
| :- |

**Prompt to use with Codex**

[PASTE PROMPT PREAMBLE HERE]

SESSION 7: FRONTEND — LISTINGS, MATCH & ANALYTICS PAGES

Goal: Complete the frontend. Build the three functional pages that show off the DBMS features.

Please build the following in this session:

1\. Create frontend/listings.html:

2\. Create frontend/match.html:

3\. Create frontend/analytics.html:

4\. Update navbar in all pages to link to all 6 pages

At the end of this session, update codex.md: Mark ALL frontend as DONE. Note any pending bug fixes. Write final test checklist. Update project state to COMPLETE.




|<p>**Session 8**</p><p>**Polish, Testing & Viva Prep**</p>|
| :- |

|<p>**Goal**</p><p>Fix edge cases, add final touches, and create the viva demo script.</p>|
| :- |

**What to build in this session**

- Add proper error handling in all Flask routes — return meaningful JSON error messages with correct HTTP status codes
- Add input validation on both frontend (disable submit if fields empty) and backend (check required fields)
- Add loading states to all fetch calls (disable button + show spinner while waiting)
- Create a ratings flow — after a transaction, show a Rate button, open a 1-5 star modal
- Test the scheduled event by manually calling the UPDATE query to expire a 90-day-old listing
- Create a viva demo script: a clear walkthrough from register → create listing → match → transact → see in analytics
- Clean up any console.log statements, unused files
- Final codex.md update with complete project summary and full test checklist

**How to test**

1. Full end-to-end test: two browser tabs, two users, one lists waste, other finds it via match, transact, check analytics
1. Test all error states: wrong password, duplicate email, over-quantity transaction
1. Test on a fresh DB (drop and re-run all .sql files)
1. Read codex.md — it should fully describe the complete project

|<p>**Codex update — end of this session**</p><p>Final update — project state COMPLETE. Full file inventory. Full test checklist. Viva notes.</p>|
| :- |

**Prompt to use with Codex**

[PASTE PROMPT PREAMBLE HERE]

SESSION 8: POLISH, TESTING & VIVA PREP

Goal: Fix edge cases, add final touches, and create the viva demo script.

Please build the following in this session:

1\. Add proper error handling in all Flask routes — return meaningful JSON error messages with correct HTTP status codes

2\. Add input validation on both frontend (disable submit if fields empty) and backend (check required fields)

3\. Add loading states to all fetch calls (disable button + show spinner while waiting)

4\. Create a ratings flow — after a transaction, show a Rate button, open a 1-5 star modal

5\. Test the scheduled event by manually calling the UPDATE query to expire a 90-day-old listing

6\. Create a viva demo script: a clear walkthrough from register → create listing → match → transact → see in analytics

7\. Clean up any console.log statements, unused files

8\. Final codex.md update with complete project summary and full test checklist

At the end of this session, update codex.md: Final update — project state COMPLETE. Full file inventory. Full test checklist. Viva notes.


