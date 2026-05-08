# IWES Codex

## Project State: COMPLETE

## What is built
- IWES is complete for the planned college DBMS project scope.
- Required directories are present: `backend/`, `backend/routes/`, `frontend/`, and `database/`.
- Root setup files are present: `.env`, `.gitignore`, `README.md`, `TECHNICAL_PLAN.md`, `codex.md`, and `VIVA_DEMO_SCRIPT.md`.
- Backend Flask app is complete in `backend/app.py`:
  - Registers auth, listings, products, transactions, match, analytics, and ratings blueprints.
  - Uses Flask-Session.
  - Adds local-development CORS headers for frontend origins on ports `5500` and `8000`.
  - Returns JSON for 404, 405, and unhandled 500 errors.
  - Provides `GET /ping`.
- Backend config and DB helpers are complete:
  - `backend/config.py` loads `.env` through `python-dotenv`.
  - `backend/db.py` creates raw MySQL connections and supports stored procedure result reads.
  - `backend/utils.py` provides `login_required` and JSON serialization helpers.
- Backend routes are complete with backend validation, JSON errors, and HTTP status codes:
  - `POST /auth/register`
  - `POST /auth/login`
  - `POST /auth/logout`
  - `GET /auth/me`
  - `GET /products`
  - `GET /listings`
  - `POST /listings/create`
  - `GET /listings/my`
  - `DELETE /listings/<id>`
  - `POST /match`
  - `POST /transact`
  - `GET /transactions/history`
  - `GET /analytics/top-waste`
  - `GET /analytics/summary`
  - `GET /analytics/recent`
  - `POST /rate`
- Ratings flow is complete:
  - Transaction pages can open a 1-5 star rating modal.
  - Dashboard and analytics transaction tables include Rate buttons.
  - Backend validates transaction ownership, completed status, score range, comment length, and duplicate ratings.
  - `Ratings` has `uq_rating_once_per_user (txn_id, rater_id)` in `schema.sql`, and the same constraint was applied to the current local DB.
- Python virtual environment exists under `backend/venv` with required dependencies installed.
- MySQL schema is complete in `database/schema.sql`.
- Seed data is complete in `database/seed_data.sql`.
- Demo seed data has been expanded for a better viva presentation:
  - 8 fixed demo companies.
  - 18 listings across BUY and SELL use cases.
  - 12 completed transactions.
  - 13 ratings.
  - Populated active listings, recent transactions, and top-waste analytics.
- All 6 core tables are implemented:
  - `Users`
  - `Products`
  - `Listings`
  - `Transactions`
  - `WasteMapping`
  - `Ratings`
- Foreign keys, checks, and indexes are implemented.
- MySQL triggers are complete in `database/triggers.sql`:
  - `before_txn_insert`
  - `after_txn_insert`
- MySQL stored procedures are complete in `database/procedures.sql`:
  - `create_transaction`
  - `match_listings`
  - `get_user_summary`
- MySQL scheduled event is complete in `database/procedures.sql`:
  - `expire_old_listings`
- MySQL views are complete in `database/views.sql`:
  - `vw_active_listings`
  - `vw_top_waste_types`
  - `vw_user_activity`
  - `vw_recent_transactions`
- Every trigger, procedure, event, and view SQL file includes plain-English comment blocks for viva explanation.
- Shared frontend stylesheet is complete in `frontend/style.css`:
  - Deep blue `#1F4E79` primary palette.
  - White card layout.
  - Responsive grids, forms, tables, badges, modals, toast notifications, spinner loading states, and star rating styles.
  - Visual polish pass added richer page headers, improved card shadows, stronger auth forms, material avatars, category color tones, and more polished analytics bars.
- Shared frontend JavaScript is complete in `frontend/main.js`:
  - `checkLogin()`
  - `apiCall(url, method, body)`
  - `showToast(message, type)`
  - `setButtonLoading()`
  - `bindRequiredForm()`
  - Shared rating modal helpers.
  - Shared `materialCell()` and category tone helpers for better visual table rows.
- Frontend pages are complete:
  - `frontend/login.html`
  - `frontend/register.html`
  - `frontend/dashboard.html`
  - `frontend/listings.html`
  - `frontend/match.html`
  - `frontend/analytics.html`
- Frontend validation and loading polish is complete:
  - Required forms disable submit buttons until required fields are filled.
  - Fetch actions disable buttons and show spinner text while waiting.
  - No raw `alert()` calls are used.
  - Toast notifications are used for success and error messages.
- Viva preparation is complete:
  - `VIVA_DEMO_SCRIPT.md` walks through register -> login -> create listing -> browse/filter -> match -> transact -> rate -> analytics -> expiry event.
  - It includes DBMS talking points and common viva Q&A.
- Scheduled event logic was tested manually with a temporary 91-day-old listing. The manual UPDATE changed it to `EXPIRED`, then the temporary row was deleted.

## What is NOT built yet
- Nothing pending for the planned IWES DBMS project scope.

## File Inventory

### Root files
- `.env`
- `.gitignore`
- `README.md`
- `TECHNICAL_PLAN.md`
- `codex.md`
- `VIVA_DEMO_SCRIPT.md`
- `PROMPT_PREAMBLE.md`
- `IWES_2_Prompt_Sessions.md`
- `IWES_dbms_project_synopsis.docx`

### Backend files
- `backend/app.py`
- `backend/config.py`
- `backend/db.py`
- `backend/utils.py`
- `backend/requirements.txt`
- `backend/routes/auth.py`
- `backend/routes/listings.py`
- `backend/routes/products.py`
- `backend/routes/transactions.py`
- `backend/routes/match.py`
- `backend/routes/analytics.py`
- `backend/routes/ratings.py`
- `backend/venv/`

### Frontend files
- `frontend/login.html`
- `frontend/register.html`
- `frontend/dashboard.html`
- `frontend/listings.html`
- `frontend/match.html`
- `frontend/analytics.html`
- `frontend/style.css`
- `frontend/main.js`

### Database files
- `database/schema.sql`
- `database/triggers.sql`
- `database/procedures.sql`
- `database/views.sql`
- `database/seed_data.sql`

## DB Features Status
- Schema: done
- Seed data: done
- Triggers: done
- Procedures: done
- Views: done
- Event: done
- Indexes: done
- Rating uniqueness constraint: done

## Known Issues
- Frontend pages should be served from `http://127.0.0.1:8000` or VS Code Live Server on port `5500`; opening the HTML files directly with `file://` will not use the configured Flask CORS origins.
- `GET /transactions/history` and `GET /analytics/recent` read from `vw_recent_transactions`, so they show only transactions from the last 30 days by design.
- `idx_listing_cat_status` is implemented on `Listings(product_id, status)` because the schema is normalized and `category` lives in `Products`. `Products(category)` is indexed separately as `idx_product_category`.
- Windows/OneDrive denied deletion of some generated `__pycache__` and `flask_session` cache files during cleanup. They are runtime artifacts, not app source files.
- The project folder is not currently a Git repository, so `git diff` and `git status` cannot be used for final review output.

## How to Test This Session
1. Open PowerShell in the project root: `C:\Users\Aryan Mehra\OneDrive\Desktop\iwes`.
2. Confirm `.env` has valid local MySQL credentials and `DB_NAME=iwes_db`.
3. Load the database files in this order if the local schema is not already installed:
  - `mysql -u root -p < database/schema.sql`
  - `mysql -u root -p < database/triggers.sql`
  - `mysql -u root -p < database/procedures.sql`
  - `mysql -u root -p < database/views.sql`
  - `mysql -u root -p < database/seed_data.sql`
4. Start the backend from `backend`:
  - `venv\Scripts\python.exe app.py`
  - Confirm `http://127.0.0.1:5000/ping` returns `{"status":"ok"}`.
5. Start the frontend from `frontend` in a second terminal:
  - `..\backend\venv\Scripts\python.exe -m http.server 8000 --bind 127.0.0.1`
  - Open `http://127.0.0.1:8000/index.html`.
6. Walk through the app flow and confirm the localhost wiring works end to end:
  - Register a user, log in, and confirm dashboard data loads.
  - Open `listings.html`, create a listing, and confirm the table refreshes.
  - Open `match.html`, run a match search, and confirm transactions can be created.
  - Open `analytics.html` and confirm summary cards and analytics tables load.
7. Re-run the static checks from the previous sessions if you want a quick smoke test:
  - `node --check frontend\main.js`
  - Parse the backend Python files with `ast`.
  - Check for debug strings such as `console.log`, `alert(`, `debugger`, `TODO`, and `FIXME`.

## Viva Notes
- Keep the explanation database-first: the Flask layer is intentionally thin.
- Show `schema.sql` for normalization and foreign keys.
- Show `triggers.sql` to explain automatic quantity updates and overbooking prevention.
- Show `procedures.sql` to explain transaction creation, matching, user summary, and daily expiry.
- Show `views.sql` to explain analytics and readable joined transaction/listing data.
- Show `VIVA_DEMO_SCRIPT.md` during practice; it is the final guided walkthrough.

## Session Log
- [Session 1] 2026-05-03 - Created the initial IWES folder structure, environment placeholders, Flask setup skeleton, dependency file, Python virtual environment, installed dependencies, MySQL connection helper, README, and project log. Verified `GET /ping` returns status code `200` with `{'status': 'ok'}`. DB connection was intentionally not tested yet.
- [Session 2] 2026-05-07 - Created the full MySQL schema with all 6 tables, foreign keys, checks, and indexes. Added deterministic seed data for 10 products, 3 bcrypt-hashed test users, 5 sample listings, and waste mappings, then loaded it into local MySQL. Added backend DB startup connection logging and fixed the Flask-Session default path so app imports and smoke tests do not stall under OneDrive.
- [Session 3] 2026-05-07 - Implemented all DBMS showcase features: transaction validation/update triggers, transaction/matching/summary stored procedures, analytics/listing/history views, and the daily `expire_old_listings` event. Loaded the new SQL into local MySQL and verified object creation, procedure output, rollback-safe trigger behavior, view row counts, event status `ENABLED`, and overbooking rejection with MySQL error `Requested quantity exceeds available quantity`.
- [Session 4] 2026-05-07 - Implemented Flask authentication, listing, and product routes using raw MySQL queries through `db.py`, bcrypt password hashing, Flask-Session login state, a shared `login_required` decorator, and local CORS headers. Verified route registration, public products/listings reads, protected-route rejection, and a full temporary-user flow covering register, login, me, create listing, my listings, delete listing, and logout.
- [Session 5] 2026-05-07 - Completed the Flask backend by adding transaction, matching, analytics, and rating routes, then registered all new blueprints in `app.py`. Stored procedure calls now use `fetch_procedure_rows()` so MySQL connector consumes procedure result sets correctly. Verified `/match`, `/transact`, `/transactions/history`, `/rate`, `/analytics/top-waste`, `/analytics/summary`, and `/analytics/recent` with temporary seller/buyer users; confirmed `create_transaction`, `match_listings`, and `get_user_summary` work through Flask, and confirmed the transaction trigger decremented listing quantity.
- [Session 6] 2026-05-07 - Built the first frontend slice: shared CSS, shared JavaScript utilities, login page, register page, and dashboard page. Login and register forms use Fetch with credentials and toast notifications, store the logged-in user in sessionStorage, and redirect through the intended flow. The dashboard protects access with `checkLogin()`, refreshes the session through `/auth/me`, loads summary stats from `/analytics/summary`, renders the user's listings from `/listings/my`, and shows the latest five rows from `/transactions/history`. Verified `frontend/main.js` with `node --check`, confirmed there are no raw `alert()` calls, started the static frontend server on port `8000`, and confirmed the Flask `/ping` endpoint responds on port `5000`.
- [Session 7] 2026-05-07 - Completed the remaining frontend pages and marked the IWES project complete for the planned DBMS scope. Added `listings.html` with filters, create-listing modal, active listing table, and transaction actions; added `match.html` to call the MySQL matching stored procedure and transact against ranked matches; added `analytics.html` with summary cards, top waste CSS bar chart, and recent transaction table backed by analytics views. Updated navigation across all six pages, expanded shared CSS and JS helpers, verified `frontend/main.js`, parsed all inline page scripts, confirmed no raw `alert()` calls, started Flask on port `5000`, started the frontend server on port `8000`, and smoke-tested `/ping`, `/products`, `/listings`, and the new page URLs.
- [Session 8] 2026-05-07 - Final polish and viva prep are complete. Added JSON error handlers, tightened backend validation, added frontend required-form disabling and button spinner loading states, implemented a reusable 1-5 star rating modal, wired Rate buttons after transactions and in transaction history tables, prevented duplicate ratings in Flask and with a MySQL unique constraint, created `VIVA_DEMO_SCRIPT.md`, manually tested the old-listing expiry UPDATE with a temporary 91-day-old listing, removed debug-code risks, and ran final frontend/backend static checks.
- [Session 9] 2026-05-07 - Improved the visual presentation without changing the required stack. Added richer CSS treatment for page headers, cards, auth pages, buttons, analytics bars, and product/material rows. Added shared frontend helpers for material avatars and category tones, then updated dashboard, listings, match, and analytics tables to use the improved visual cells. Expanded `seed_data.sql` with a fuller demo dataset of companies, listings, transactions, and ratings, applied it to the local MySQL database, verified counts through MySQL, reran JS/Python static checks, and confirmed backend/frontend servers are already running on ports `5000` and `8000`.
- [Session 10] 2026-05-08 - Updated `README.md` to document the current localhost run flow for IWES. The README now explains the MySQL import order, backend virtual environment setup, Flask startup on port `5000`, frontend static server startup on port `8000`, and the correct browser entry point at `http://127.0.0.1:8000/index.html`.
