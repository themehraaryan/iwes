# IWES Viva Demo Script

## Demo Setup

1. Start MySQL and confirm `iwes_db` is loaded.
2. Start Flask from `backend/`:
   ```powershell
   venv\Scripts\python.exe app.py
   ```
3. Start the frontend from `frontend/`:
   ```powershell
   ..\backend\venv\Scripts\python.exe -m http.server 8000 --bind 127.0.0.1
   ```
4. Open `http://127.0.0.1:8000/index.html`.

## Walkthrough

1. Register a new user.
   - Open `register.html`.
   - Enter name, email, password, and optional phone.
   - Explain that Flask hashes the password with bcrypt before inserting into `Users`.

2. Log in.
   - Open `index.html` and use the Log In button.
   - Log in with the new account.
   - Explain that Flask-Session stores the logged-in user id server-side.

3. Create a listing.
   - Open `listings.html`.
   - Click `Create Listing`.
   - Select a product, choose `SELL`, enter quantity, price, and location.
   - Explain `total_qty` stays fixed while `available_qty` starts equal to it.

4. Browse and filter listings.
   - Use category, listing type, and minimum quantity filters.
   - Explain that the page reads `vw_active_listings`, a MySQL view joining Listings, Users, and Products.

5. Match a buyer to a seller.
   - Open `match.html`.
   - Select the same product and enter a quantity that an active SELL listing can satisfy.
   - Click `Find Matches`.
   - Explain that Flask calls `CALL match_listings(product_id, qty_needed)` and MySQL ranks the matches.

6. Create a transaction.
   - Click `Transact` from the matching page or listings page.
   - Explain that Flask calls `CALL create_transaction(...)`.
   - Explain the DBMS flow:
     - `before_txn_insert` blocks overbooking.
     - `after_txn_insert` decrements `available_qty`.
     - If quantity reaches zero, the trigger marks the listing `COMPLETED`.

7. Rate the transaction.
   - After the transaction, use the rating modal.
   - Select 1-5 stars and submit.
   - Explain that ratings are stored in the `Ratings` table and included in user summary analytics.

8. Show dashboard and analytics.
   - Open `dashboard.html` for personal summary, listings, and recent transactions.
   - Open `analytics.html` for top waste categories and recent transaction data.
   - Explain that analytics use `get_user_summary()` and MySQL views, not Python joins.

9. Demonstrate expiry event logic manually.
   - In MySQL, create or update one active listing to be older than 90 days.
   - Run:
     ```sql
     UPDATE Listings
     SET status = 'EXPIRED'
     WHERE status = 'ACTIVE'
       AND available_qty > 0
       AND created_at < NOW() - INTERVAL 90 DAY;
     ```
   - Explain this is the same logic used by the daily `expire_old_listings` event.

## Viva Talking Points

- The database is the main layer: triggers, stored procedures, views, indexes, and event scheduler are all visible.
- Flask is intentionally thin: it checks session, validates inputs, calls SQL, and returns JSON.
- The schema is normalized: product details live in `Products`, not repeated in every listing.
- Overbooking is prevented in MySQL, so even two clients cannot bypass quantity validation.
- Analytics are explainable because each dashboard query maps to a view or stored procedure.

## Common Questions

**Why use triggers?**  
To keep `available_qty` correct automatically whenever a transaction is inserted.

**Why use stored procedures?**  
To keep transaction creation and matching logic inside MySQL, which is the focus of the DBMS project.

**Why no ORM?**  
Raw SQL makes the database concepts visible for the viva.

**What happens when a listing is fully used?**  
The `after_txn_insert` trigger sets `status = 'COMPLETED'`.

**How are stale listings handled?**  
The MySQL event `expire_old_listings` runs daily and marks active listings older than 90 days as `EXPIRED`.
