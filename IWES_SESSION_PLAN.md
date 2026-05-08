# IWES — AI-Driven Coding Session Plan (V2.0)

This document breaks down the [IWES_TECHNICAL_PLAN_V2.md](file:///c:/Users/Aryan Mehra/OneDrive/Desktop/iwes/IWES_TECHNICAL_PLAN_V2.md) into 5 focused coding sessions. Each session is designed to be given to an AI assistant (like ChatGPT, Claude, or Trae) to implement specific parts of the upgrade.

---

## 🛠️ Prompt Preamble (Common for All Sessions)
*Copy and paste this before every session prompt to ensure the AI understands the context and constraints.*

```markdown
You are helping me upgrade IWES (Industrial Waste Exchange System) to V2.0. 
This is a B.Tech DBMS project using Flask, MySQL, and Vanilla JS/CSS.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CORE CONSTRAINTS — DO NOT DEVIATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. TECH STACK: Flask (Backend), MySQL 8 (Database), Vanilla JS + CSS (Frontend). NO REACT/TAILWIND.
2. DBMS PHILOSOPHY: All logic must stay in MySQL. Flask is just a bridge.
3. DESIGN: Professional, dark sidebar, card-based layout, deep blue (#1F4E79) primary color.
4. FOLDER STRUCTURE: Follow the structure defined in TECHNICAL_PLAN_V2.md.
5. NO OVER-ENGINEERING: Keep it simple enough for a 2nd-year student to explain in a viva.

Reference the following files for context:
- TECHNICAL_PLAN_V2.md (The roadmap)
- PROMPT_PREAMBLE.md (Detailed tech constraints)
- database/schema.sql (Current DB structure)
```

---

## 📅 Session 1: The Database Upgrade
**Goal:** Update the MySQL schema to support V2.0 features (Location, Lifecycle, Notifications).

**Prompt:**
```markdown
[INSERT PREAMBLE HERE]

TASK: Upgrade the Database Schema to V2.0.
1. Modify `Users` and `Listings` tables to add a `city` column (VARCHAR 80).
2. Update the `Transactions` status ENUM to: 'REQUESTED','ACCEPTED','IN_TRANSIT','DELIVERED','COMPLETED','CANCELLED'.
3. Create the `Notifications` table as specified in the technical plan.
4. Update the `after_txn_insert` trigger to automatically insert a notification when a transaction is requested.
5. Implement the `match_listings` stored procedure with the new Smart Match Score formula (Qty + City + Freshness).
6. Create the `vw_activity_feed` view for the dashboard.

Deliverable: Updated SQL files in `database/` folder and a migration script if needed.
```

---

## 📅 Session 2: Backend APIs & Notification System
**Goal:** Implement the Flask routes for notifications and update existing routes for V2.0 data.

**Prompt:**
```markdown
[INSERT PREAMBLE HERE]

TASK: Update Backend Routes for V2.0.
1. Update `backend/routes/auth.py`: registration should now accept `company_name` and `city`.
2. Update `backend/routes/listings.py`: listing creation should include `city`.
3. Create `backend/routes/notifications.py`:
   - GET `/notifications`: Fetch unread notifications for the logged-in user.
   - POST `/notifications/read/<id>`: Mark a notification as read.
4. Update `backend/routes/match.py`: Use the updated `match_listings` procedure and return the `match_score`.
5. Ensure `backend/db.py` handles the connection efficiently.

Deliverable: Updated Python files in `backend/routes/` and `backend/app.py`.
```

---

## 📅 Session 3: Modern Design System (CSS/JS)
**Goal:** Overhaul the look and feel of the application.

**Prompt:**
```markdown
[INSERT PREAMBLE HERE]

TASK: Implement the V2.0 Design System.
1. Completely rewrite `frontend/style.css`:
   - Implement a dark sidebar navigation layout.
   - Define a professional color palette (Primary: #1F4E79, Background: #F4F7F6).
   - Create reusable card styles for listings and activity items.
   - Add responsive styles for mobile.
2. Update `frontend/main.js`:
   - Add a global `showToast(message, type)` function for notifications.
   - Update `apiCall()` to handle errors globally.
   - Implement a recurring fetch for the notification count in the sidebar.

Deliverable: Updated `frontend/style.css` and `frontend/main.js`.
```

---

## 📅 Session 4: Feature Implementation (Listings & Matching)
**Goal:** Update the core user-facing pages.

**Prompt:**
```markdown
[INSERT PREAMBLE HERE]

TASK: Update Core Frontend Pages.
1. `index.html`: Modernize the landing page with a hero section and "How it works".
2. `login.html` & `register.html`: Implement a split-screen design (Image on left, Form on right).
3. `listings.html`: Replace the table with a responsive grid of cards. Show "Smart Match" badges.
4. `match.html`: Implement a split-pane view. Left: Buyer requirements, Right: Ranked matches with a visual progress bar for the Match Score %.

Deliverable: Updated HTML files in `frontend/`.
```

---

## 📅 Session 5: Analytics, Dashboard & Final Polish
**Goal:** Complete the remaining pages and ensure everything is connected.

**Prompt:**
```markdown
[INSERT PREAMBLE HERE]

TASK: Implement Analytics and Dashboard.
1. `dashboard.html`:
   - Display key stats cards (Total Listings, Active Txns).
   - Implement the "Activity Feed" pulling from `vw_activity_feed`.
2. `analytics.html`:
   - Create CSS-based bar charts for "Top Waste Categories".
   - Show "Platform Insights" (e.g., Total Waste Diverted).
3. Final Polish: Ensure all links work, the sidebar highlights the active page, and the user session is handled correctly across all pages.

Deliverable: Updated `dashboard.html`, `analytics.html`, and final bug fixes.
```

---

## 🚀 Final Session: Documentation, Cleanup & CI/CD
**Goal:** Prepare the project for handoff and deployment.

**Prompt:**
```markdown
[INSERT PREAMBLE HERE]

TASK: Finalization, Documentation, and Deployment.
1. **Clean Code**: Refactor any redundant logic and add clear comments to all complex functions and SQL blocks.
2. **explanation.md**: Create a comprehensive file that explains the codebase from Basic to Advanced. Include:
   - System Overview & Flow.
   - Database Schema (ER Diagram description).
   - Deep dive into DBMS features (Triggers, Procedures, Views).
   - Backend API documentation.
   - How to run and test.
3. **CI/CD Pipeline & Vercel Deployment**:
   - Create `vercel.json` for frontend routing and API rewrites.
   - Set up `.github/workflows/deploy.yml` to trigger Vercel deployments on push to `main` (Production) and `develop` (Preview) branches.
4. **Database Connectivity (Local to Vercel)**:
   - Configure `backend/db.py` to use environment variables for DB connection.
   - Since Vercel is in the cloud and your DB is local, you MUST use a tunnel like **Ngrok** or **Localtunnel** to expose your local MySQL port (3306) to the internet, OR host the DB on a service like Railway.
   - Add a "Deployment & DB Connection" section in `explanation.md` explaining how to set up the `.env` variables on Vercel to point to this tunneled/hosted DB.

Deliverable: `explanation.md`, `vercel.json`, `.github/workflows/deploy.yml`, and updated `backend/db.py`.
```
