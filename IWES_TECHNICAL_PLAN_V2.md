# IWES — Technical Plan V2.0
**Industrial Waste Exchange System · Upgraded Edition**
**B.Tech IV Semester · DBMS Project · JIIT Noida**

> This is the V2.0 upgrade plan. The project already has a working backend (Flask + MySQL) and basic frontend. V2.0 adds intelligent features, a polished modern UI, and deployment configuration — all within the original synopsis scope.

---

## What Is Different in V2.0

| Area | V1 (what exists) | V2 (what we're adding) |
|------|-----------------|----------------------|
| UI Navigation | Top navbar | Dark sidebar with icons |
| Listings View | Plain HTML table | Card grid with badges |
| Match Engine | Returns raw rows | Returns ranked results with a Smart Match Score (%) |
| Transactions | Status: DONE/PENDING | Full lifecycle: REQUESTED → ACCEPTED → IN TRANSIT → DELIVERED → COMPLETED |
| Analytics | Numbers in a list | CSS bar charts + Platform Insights from SQL |
| Dashboard | Basic stats | Activity Feed pulled from a database view |
| Waste Info | Hidden in DB | Shown as "Possible Uses" cards on listings |
| Notifications | None | DB-based notification panel (no websockets) |
| Location | Plain text field | city field used in match scoring |
| Deployment | Local only | Vercel (frontend) + Railway (backend + MySQL) |

**What is NOT changing:**
- Tech stack: Flask + MySQL + Vanilla JS + HTML/CSS. No React, no frameworks.
- Core DBMS concepts: all triggers, stored procedures, and views still exist.
- Synopsis scope: no blockchain, no AI, no microservices, no complex auth.
- Existing API route contracts: all existing `/auth`, `/listings`, `/match`, `/transact` routes work the same.

---

## 1. Who Is This For (Viva Explanation)

IWES is an **Industrial Waste Exchange System**.

Imagine a factory that produces 5,000 kg of fly ash (a byproduct of burning coal) every month. They cannot use it, and throwing it away costs money. At the same time, a cement factory 30 km away needs fly ash as a raw material.

IWES connects these two parties. The factory lists its fly ash as a SELL listing. The cement company lists a BUY listing for fly ash. The platform runs a matching engine (a MySQL stored procedure) to find compatible pairs, and when they agree, a transaction is recorded.

The database handles all the hard work — checking quantities, preventing overbooking, updating stock automatically — through **triggers** and **stored procedures**. Flask just receives a web request and passes it to MySQL. The frontend shows the results.

---

## 2. Project Folder Structure (V2.0)

```
iwes/
├── TECHNICAL_PLAN_V2.md        ← this file
├── codex.md                    ← living project log
├── README.md
├── explanation.md              ← plain-English codebase guide (generated last)
├── .env                        ← DB credentials + SECRET_KEY (never commit this)
├── .gitignore
├── vercel.json                 ← Vercel frontend deployment config
├── Procfile                    ← Railway backend deployment config
├── .github/
│   └── workflows/
│       └── deploy.yml          ← GitHub Actions CI/CD
│
├── backend/
│   ├── app.py                  ← Flask app entry point
│   ├── db.py                   ← MySQL connection helper
│   ├── config.py               ← loads .env
│   ├── utils.py                ← login_required decorator + helpers
│   ├── requirements.txt
│   └── routes/
│       ├── auth.py             ← register, login, logout, me
│       ├── listings.py         ← create, browse, my listings, delete
│       ├── transactions.py     ← transact, history, update stage
│       ├── match.py            ← smart match with score
│       ├── analytics.py        ← top waste, summary, recent, insights
│       ├── notifications.py    ← get notifications, mark read   [NEW]
│       └── ratings.py          ← rate a transaction
│
├── database/
│   ├── schema.sql              ← all table CREATE statements (updated)
│   ├── procedures.sql          ← stored procedures (updated)
│   ├── triggers.sql            ← triggers (unchanged)
│   ├── views.sql               ← views (new views added)
│   └── seed_data.sql           ← demo data
│
└── frontend/
    ├── style.css               ← full design system (replaced)
    ├── main.js                 ← shared JS helpers (updated)
    ├── index.html              ← landing page (updated)
    ├── login.html              ← split-screen auth (updated)
    ├── register.html           ← split-screen auth (updated)
    ├── listings.html           ← PRIMARY entry after login (updated)
    ├── match.html              ← split-pane smart match (updated)
    ├── analytics.html          ← charts + insights (updated)
    └── dashboard.html          ← activity feed + overview (updated)
```

---

## 3. Database Schema V2.0

### 3a. Table Changes

**Users table — add two columns:**
```sql
ALTER TABLE Users
  ADD COLUMN company_name VARCHAR(150) DEFAULT NULL,
  ADD COLUMN city VARCHAR(80) DEFAULT NULL;
```
`company_name` — the organization the user belongs to (e.g., "SteelCorp India").
`city` — used for location-aware matching (e.g., "Delhi").

**Listings table — add city column:**
```sql
ALTER TABLE Listings
  ADD COLUMN city VARCHAR(80) DEFAULT NULL;
```
Allows the match engine to prioritize listings in the same city as the buyer.

**Transactions table — replace status ENUM:**
```sql
-- Old: ENUM('PENDING','DONE','CANCELLED')
-- New: ENUM('REQUESTED','ACCEPTED','IN_TRANSIT','DELIVERED','COMPLETED','CANCELLED')
```

The lifecycle stages:
- `REQUESTED` — buyer has initiated
- `ACCEPTED` — seller has confirmed
- `IN_TRANSIT` — goods are being transported
- `DELIVERED` — goods received
- `COMPLETED` — transaction fully closed (ratings can now be given)
- `CANCELLED` — cancelled by either party

**Reason for this change:** Makes the platform feel like a real exchange system with a traceable lifecycle. Also makes the DBMS project more demonstrable — you can show that `ENUM` types enforce valid states at the database level.

### 3b. New Table: Notifications

```sql
CREATE TABLE IF NOT EXISTS Notifications (
  notif_id     INT AUTO_INCREMENT PRIMARY KEY,
  user_id      INT NOT NULL,
  type         ENUM('MATCH_FOUND','TXN_REQUESTED','TXN_UPDATED','LISTING_EXPIRED','RATING_RECEIVED') NOT NULL,
  message      VARCHAR(300) NOT NULL,
  related_id   INT DEFAULT NULL,          -- listing_id or txn_id depending on type
  is_read      TINYINT(1) DEFAULT 0,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notif_user
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
    ON DELETE CASCADE,
  INDEX idx_notif_user_unread (user_id, is_read)
) ENGINE=InnoDB;
```

**Why notifications?** They are inserted by triggers and procedures — not by Flask code. This is a strong DBMS talking point: "Our notification system is driven by MySQL triggers, not application code."

### 3c. Updated Trigger: After Transaction Insert

Add notification insertion to the existing `after_txn_insert` trigger:
```sql
-- After inserting a transaction, notify the other party
INSERT INTO Notifications (user_id, type, message, related_id)
VALUES (
  NEW.seller_id,
  'TXN_REQUESTED',
  CONCAT('New transaction requested for listing #', NEW.listing_id),
  NEW.txn_id
);
```

### 3d. Updated Stored Procedure: match_listings

The existing procedure returns raw listing rows. V2 adds a computed `match_score` column.

**Match Score Formula (computed in SQL):**
```
score = qty_score + city_bonus + freshness_bonus

qty_score     = IF(available_qty >= requested_qty, 50, (available_qty / requested_qty) * 50)
city_bonus    = IF(sell_city = buy_city, 30, 0)
freshness_bonus = CASE
                    WHEN days_old <= 7  THEN 20
                    WHEN days_old <= 30 THEN 10
                    ELSE 5
                  END
```

Score is always between 0 and 100. Returned as an integer. Results are ordered by score DESC.

**Viva explanation:** "The match score is not a machine learning model. It is a weighted formula implemented entirely in a MySQL stored procedure. Quantity match gets the most weight because it is the most important factor. Location and freshness are bonus points. This runs inside MySQL, which means the computation happens at the database layer, not in Python."

### 3e. New Views

**`vw_activity_feed`** — returns recent platform activity for the dashboard feed:
```sql
CREATE OR REPLACE VIEW vw_activity_feed AS
SELECT
  'TRANSACTION' AS event_type,
  t.txn_id AS event_id,
  CONCAT(u_buyer.name, ' purchased ', t.qty_exchanged, ' ', p.unit, ' of ', p.name) AS message,
  t.txn_date AS event_time,
  t.buyer_id AS actor_user_id
FROM Transactions t
JOIN Listings l ON t.listing_id = l.listing_id
JOIN Products p ON l.product_id = p.product_id
JOIN Users u_buyer ON t.buyer_id = u_buyer.user_id

UNION ALL

SELECT
  'LISTING' AS event_type,
  l.listing_id AS event_id,
  CONCAT(u.name, ' listed ', l.available_qty, ' ', p.unit, ' of ', p.name, ' (', l.listing_type, ')') AS message,
  l.created_at AS event_time,
  l.user_id AS actor_user_id
FROM Listings l
JOIN Products p ON l.product_id = p.product_id
JOIN Users u ON l.user_id = u.user_id
WHERE l.status = 'ACTIVE'

ORDER BY event_time DESC
LIMIT 20;
```

**`vw_platform_insights`** — SQL-derived text insights shown on the analytics page:
```sql
CREATE OR REPLACE VIEW vw_platform_insights AS
SELECT
  (SELECT COUNT(*) FROM Transactions WHERE status = 'COMPLETED') AS completed_transactions,
  (SELECT SUM(qty_exchanged) FROM Transactions WHERE status = 'COMPLETED') AS total_qty_exchanged,
  (SELECT p.name
   FROM Transactions t
   JOIN Listings l ON t.listing_id = l.listing_id
   JOIN Products p ON l.product_id = p.product_id
   GROUP BY p.name
   ORDER BY COUNT(*) DESC
   LIMIT 1) AS most_traded_waste,
  (SELECT COUNT(DISTINCT user_id) FROM Listings WHERE status = 'ACTIVE') AS active_sellers,
  (SELECT ROUND(AVG(score), 1) FROM Ratings) AS avg_platform_rating;
```

**`vw_waste_intelligence`** — for each active listing, shows possible uses from WasteMapping:
```sql
CREATE OR REPLACE VIEW vw_waste_intelligence AS
SELECT
  l.listing_id,
  p.name AS waste_name,
  p.category,
  GROUP_CONCAT(wm.alternative_use SEPARATOR ' | ') AS possible_uses,
  GROUP_CONCAT(DISTINCT wm.industry SEPARATOR ', ') AS target_industries
FROM Listings l
JOIN Products p ON l.product_id = p.product_id
LEFT JOIN WasteMapping wm ON p.product_id = wm.product_id
WHERE l.status = 'ACTIVE' AND l.listing_type = 'SELL'
GROUP BY l.listing_id, p.name, p.category;
```

---

## 4. Backend V2.0 — New and Updated Routes

### No existing routes change their input/output contracts.

All new routes are **additive only**.

### 4a. Updated: `GET /match` → now returns `match_score`

The match procedure now returns a `match_score` column. Flask passes this through unchanged. Frontend displays it as a score badge.

### 4b. Updated: `PUT /transactions/stage` (NEW endpoint)

```
PUT /transactions/stage
Body: { txn_id, new_stage }
Auth: login required
Logic: Only seller or buyer of that transaction can update.
       Stage must follow the lifecycle order (no jumping from REQUESTED to COMPLETED).
Returns: { success, new_stage }
```

**MySQL-side:** A trigger on `Transactions` `BEFORE UPDATE` validates the stage transition and rejects invalid jumps with a `SIGNAL SQLSTATE '45000'`.

### 4c. New: Notifications Routes (`routes/notifications.py`)

```
GET  /notifications        → returns all notifications for logged-in user
PUT  /notifications/read   → marks all as read (or specific IDs)
Body for PUT: { ids: [1, 2, 3] } or { all: true }
```

### 4d. New: `GET /analytics/insights`

Queries `vw_platform_insights` and `vw_activity_feed`, returns JSON:
```json
{
  "completed_transactions": 42,
  "total_qty_exchanged": 18500,
  "most_traded_waste": "Fly Ash",
  "active_sellers": 8,
  "avg_platform_rating": 4.2,
  "activity_feed": [...]
}
```

### 4e. New: `GET /listings/:id/intelligence`

Queries `vw_waste_intelligence` for a specific listing ID. Returns possible uses and industries.

---

## 5. Frontend V2.0 — Design System

### 5a. Typography + Color

| Token | Value | Used For |
|-------|-------|---------|
| `--font-sans` | Inter, Sora, system | Body text, labels, buttons |
| `--font-display` | Newsreader, Georgia | Page titles, stat numbers |
| `--primary` | `#0a5c58` | Brand, buttons, links |
| `--primary-hover` | `#084a47` | Button hover |
| `--primary-light` | `#e6f4f3` | Backgrounds, badges |
| `--accent` | `#d08a33` | Warnings, secondary highlights |
| `--sidebar-bg` | `#0d1117` | Dark sidebar |
| `--ink` | `#111827` | Main text |
| `--muted` | `#6b7280` | Labels, subtitles |
| `--bg` | `#f8fafb` | Page background |
| `--surface` | `#ffffff` | Cards, modals |
| `--border` | `#e2e8eb` | Card borders, dividers |

### 5b. Layout Architecture

**Authenticated pages (listings, match, analytics, dashboard):**
- Fixed dark sidebar (220px wide) on the left
- `page-body` fills the remaining width
- Sidebar collapses to icon-only at < 900px

**Public pages (index, login, register):**
- Standard top navbar for landing page
- Split-screen layout for login/register (brand panel left, form right)

**Navigation order in sidebar (important — listing is FIRST):**
1. Listings (active = first thing user sees after login)
2. Match
3. Analytics
4. Overview (previously Dashboard)

### 5c. Key UI Components

**Smart Match Score Badge:**
```html
<div class="match-score-ring">
  <svg viewBox="0 0 36 36">
    <circle class="ring-bg" cx="18" cy="18" r="15.9"/>
    <circle class="ring-fill" cx="18" cy="18" r="15.9"
      stroke-dasharray="92 100" />  <!-- 92% match -->
  </svg>
  <span class="score-text">92%</span>
</div>
```
This is a circular SVG progress ring. Score 0–100 maps to `stroke-dasharray` of 0–100.

**Transaction Stage Tracker:**
```html
<div class="stage-tracker">
  <div class="stage-step completed">
    <span class="stage-dot">✓</span>
    <span>Requested</span>
  </div>
  <div class="stage-connector filled"></div>
  <div class="stage-step active">
    <span class="stage-dot"></span>
    <span>Accepted</span>
  </div>
  <div class="stage-connector"></div>
  <div class="stage-step">
    <span class="stage-dot"></span>
    <span>In Transit</span>
  </div>
  <!-- ... -->
</div>
```

**Activity Feed Card:**
```html
<div class="feed-item">
  <div class="feed-icon">🔄</div>
  <div class="feed-body">
    <p>SteelCorp India purchased 400 kg of Fly Ash</p>
    <span class="feed-time">2 hours ago</span>
  </div>
</div>
```

**Platform Insight Card:**
```html
<div class="insight-card">
  <span class="insight-icon">🏆</span>
  <div>
    <strong>Most Traded Material</strong>
    <p>Fly Ash — 12 completed transactions</p>
  </div>
</div>
```

**Notification Bell (in sidebar):**
```html
<div class="notif-trigger" id="notifTrigger">
  🔔
  <span class="notif-badge" id="notifBadge">3</span>
</div>
<div class="notif-dropdown" id="notifDropdown">
  <!-- notification items -->
</div>
```

**Waste Intelligence Card (shown on listing detail):**
```html
<div class="waste-intel-card">
  <h4>💡 Possible Uses for Fly Ash</h4>
  <ul class="use-list">
    <li>Cement manufacturing</li>
    <li>Brick production</li>
    <li>Road base material</li>
  </ul>
  <span class="intel-industries">Industries: Construction, Infrastructure</span>
</div>
```

---

## 6. Page-by-Page Plan

### 6a. `index.html` — Landing Page

**What's there:** Navbar, hero section, features grid, workflow steps, DBMS section, footer.

**V2 upgrades:**
- Hero gets animated gradient background (CSS only, no JS)
- Hero kicker becomes a green pill badge
- Feature cards get left border accent + hover lift
- Workflow steps get numbered circle badges with a connector line
- Navbar gets glassmorphism blur when scrolled (JS scroll listener)
- Add a live "platform stats" strip below hero: `42 transactions · 18 active listings · 6 waste types`

**After login redirect:** Index detects existing session and redirects to `listings.html`.

### 6b. `login.html` + `register.html` — Auth Pages

**V2 upgrade:** Split-screen layout.

Left panel (dark teal brand panel):
- IWES logo
- Headline: "Industrial Waste Exchange System"
- 3 bullet points from synopsis: triggers, procedures, views
- Badge: "DBMS-first · MySQL · Flask"

Right panel (white form panel):
- Form fields with polished inputs
- Primary CTA button
- Link to the other auth page

**No functional change.** Only visual restructuring.

### 6c. `listings.html` — PRIMARY ENTRY PAGE after login

**This is the most important page.** Users land here first.

**V2 structure:**
- Sidebar navigation (active = Listings)
- Page header: "Market Listings" + "+ New Listing" button (top right)
- Tab bar: "Browse All" | "My Listings"
- Filter command bar: Type (BUY/SELL) + Category + Min Qty + [Filter] [Clear]
- Results as **card grid** (default view)
  - Each card: type badge, category, title (product name + seller), qty available, price, "Find Matches" button
- "My Listings" tab shows a table with a Delete button per row (existing behavior)
- New Listing modal: triggered by button, same form fields as before

**Waste Intelligence:** When a user clicks a SELL listing card, a small panel expands below showing `vw_waste_intelligence` data — what the waste can be used for.

**Login redirect flow:** `main.js` after successful login → `window.location.href = 'listings.html'`

### 6d. `match.html` — Smart Match Page

**V2 structure:**
- Sidebar navigation (active = Match)
- Split-pane layout: left panel (form) + right panel (results)

Left panel:
- "Find Matches" heading
- Select your BUY listing dropdown
- [Run Match Engine] button
- Info box: "Calls the `match_listings` stored procedure in MySQL. Results are ranked by Smart Match Score."

Right panel — each match result shows:
- Rank badge (#1, #2, #3...)
- **Smart Match Score ring** (SVG circle, 0–100%)
- Score breakdown tooltip: Qty Match: 50pt | Same City: 30pt | Freshness: 20pt
- Listing details: seller name, available qty, price/unit, city
- Waste intelligence snippet (1 possible use)
- Quantity input + "Transact" button

**Viva talking point:** "The match score is computed entirely inside MySQL using a weighted formula in the `match_listings` procedure. Flask only passes the result to the frontend. The database does all the intelligence."

### 6e. `analytics.html` — Platform Intelligence

**V2 structure:**
- Sidebar (active = Analytics)
- Hero stats strip: 3 large numbers from `vw_platform_insights`
  - Total Transactions Completed
  - Total Qty Exchanged (in kg/tons)
  - Avg Platform Rating (⭐ stars)
- Platform Insights section: 4 insight cards derived from SQL
  - Most Traded Material
  - Most Active Seller
  - Top City for Exchange
  - Completion Rate %
- Top Waste Categories bar chart (CSS bars, from `vw_top_waste_types`)
- Recent Transactions table (from `vw_recent_transactions`)

### 6f. `dashboard.html` — Overview (now secondary)

**Renamed nav label:** "Overview"

**V2 structure:**
- Sidebar (active = Overview, 4th position)
- User profile card: name, company, city, member since
- 4 stat cards: Active Listings, Completed Transactions, Total Qty Sold, Avg Rating
- Activity Feed: last 10 items from `vw_activity_feed`
- My recent transactions table

---

## 7. DBMS Concepts Summary (For Viva)

| Concept | Where Used | What It Does |
|---------|------------|-------------|
| **Triggers** | `triggers.sql` | `before_txn_insert` blocks overbooking. `after_txn_insert` updates available_qty and inserts notification. |
| **Stored Procedures** | `procedures.sql` | `create_transaction` handles buyer/seller logic. `match_listings` returns ranked results with computed score. `get_user_summary` aggregates user stats. |
| **Views** | `views.sql` | `vw_active_listings`, `vw_top_waste_types`, `vw_activity_feed`, `vw_platform_insights`, `vw_waste_intelligence`, `vw_recent_transactions` |
| **Scheduled Event** | `procedures.sql` | `expire_old_listings` runs nightly, sets stale listings to EXPIRED |
| **Indexes** | `schema.sql` | On category, status, available_qty, user_id for fast filtering |
| **Foreign Keys** | `schema.sql` | All tables linked: Transactions → Listings → Products, Users |
| **ENUM types** | Listings.status, Transactions.stage | Database-level constraint on valid values |
| **CHECK constraints** | Listings, Transactions | qty > 0, score BETWEEN 1 AND 5 |
| **Transactions (SQL)** | `create_transaction` proc | Uses `FOR UPDATE` lock to prevent race conditions |

---

## 8. Deployment Architecture

### 8a. Where Each Part Lives

```
GitHub Repository (source of truth)
        │
        ├── Frontend (HTML/CSS/JS)
        │         └──► Vercel
        │               ├── main branch → production URL
        │               └── develop branch → preview URL
        │
        └── Backend (Flask) + Database (MySQL)
                  └──► Railway.app
                        ├── Flask service (Python app)
                        └── MySQL service (cloud database)
```

**Why this split?**
- Vercel is the best free platform for static files (HTML/CSS/JS). It gives you auto-deploy from GitHub, a CDN, and HTTPS automatically.
- Railway is the simplest platform for Flask + MySQL. One project can host both the Python backend and the MySQL database. It also auto-deploys from GitHub.
- Your local development connects to Railway MySQL using the connection string in `.env`, so what you test locally matches production exactly.

### 8b. Environment Variables

**Local `.env` (never commit this file):**
```
DB_HOST=your-railway-mysql-host
DB_PORT=your-railway-mysql-port
DB_USER=root
DB_PASS=your-railway-mysql-password
DB_NAME=iwes_db
SECRET_KEY=your-secret-key-here
FRONTEND_URL=http://localhost:5500
```

**Railway environment variables (set in Railway dashboard):**
```
DB_HOST=localhost         (Railway auto-injects this)
DB_PORT=3306
DB_USER=root
DB_PASS=auto-generated
DB_NAME=iwes_db
SECRET_KEY=same-as-local
FRONTEND_URL=https://your-vercel-app.vercel.app
```

**Vercel environment variables (set in Vercel dashboard):**
```
BACKEND_URL=https://your-railway-app.up.railway.app
```
Used in `main.js` as the API base URL so the frontend knows where to send fetch requests.

### 8c. How Local Development Works With Cloud MySQL

1. Sign up for Railway (free tier)
2. Create a new project → Add MySQL database
3. Copy the MySQL connection details from Railway dashboard
4. Paste into your local `.env` file
5. Run your Flask app locally — it now connects to the Railway MySQL
6. Any data you insert/test locally is visible in the production Railway MySQL
7. This means your demo data and testing happen against the real database

**Alternatively:** Use local MySQL for development and Railway MySQL for production by having two `.env` files — `.env.local` and `.env.production`. The `config.py` reads whichever is active.

### 8d. Vercel Configuration (`vercel.json`)

```json
{
  "version": 2,
  "builds": [
    {
      "src": "frontend/**",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/",
      "dest": "/frontend/index.html"
    },
    {
      "src": "/login",
      "dest": "/frontend/login.html"
    },
    {
      "src": "/register",
      "dest": "/frontend/register.html"
    },
    {
      "src": "/listings",
      "dest": "/frontend/listings.html"
    },
    {
      "src": "/match",
      "dest": "/frontend/match.html"
    },
    {
      "src": "/analytics",
      "dest": "/frontend/analytics.html"
    },
    {
      "src": "/dashboard",
      "dest": "/frontend/dashboard.html"
    },
    {
      "src": "/(.*)",
      "dest": "/frontend/$1"
    }
  ]
}
```

### 8e. Railway Configuration (`Procfile`)

```
web: cd backend && python app.py
```

### 8f. GitHub Actions CI/CD (`.github/workflows/deploy.yml`)

```yaml
name: Deploy IWES

on:
  push:
    branches: [main, develop]

jobs:
  deploy-vercel:
    name: Deploy Frontend to Vercel
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          # main branch = production, develop = preview
          vercel-args: ${{ github.ref == 'refs/heads/main' && '--prod' || '' }}

  # Railway auto-deploys from GitHub — no action needed.
  # Just connect your Railway project to your GitHub repo in Railway settings.
```

**Setup steps for this CI/CD:**
1. Get your Vercel token from vercel.com/account/tokens
2. Get org ID and project ID from your Vercel project settings
3. Add these as GitHub repository secrets (Settings → Secrets → Actions)
4. Connect Railway to your GitHub repo in Railway project settings → auto-deploy on push

---

## 9. What ChatGPT Suggested — Analysis

Items **kept and improved:**
- Smart Match Score ✅ — made DBMS-oriented (computed in stored procedure, not Python)
- Activity Feed ✅ — implemented as a SQL VIEW, not a fake array
- Waste Intelligence ✅ — uses existing WasteMapping table
- Transaction Lifecycle ✅ — implemented as ENUM upgrade in Transactions table
- Visual analytics ✅ — CSS bar charts from actual SQL views
- Platform Insights ✅ — derived from SQL in a view, shown as cards
- Location support ✅ — added city field, used in match scoring formula
- Notification system ✅ — inserted by triggers, not application code
- Modern sidebar UI ✅ — dark sidebar, card grids, CSS progress rings

Items **removed or simplified:**
- Role-based dashboards — SKIP. The synopsis has dual-role users (same account = buyer + seller). Separate UIs add complexity without DBMS value.
- Saved searches/watchlists — SKIP. Scope creep, no DBMS angle.
- Admin panel — SKIP. Not in synopsis, adds auth complexity.
- Sustainability metrics — SKIP. Would be fake numbers with no DB backing. Looks weak.
- Onboarding flow — SKIP. A welcome wizard is UX polish but adds no academic value and confuses the demo flow.
- Live search/autocomplete — SKIP. Requires debounced API calls, complicates existing filter logic.
- "Blockchain, AI, microservices" — obviously SKIP.

Items **added that ChatGPT missed:**
- `vw_waste_intelligence` view — surfaces WasteMapping data already in the DB
- `vw_platform_insights` view — SQL-derived text insights (stronger than hardcoded strings)
- Transaction stage transition trigger — validates stage order at DB level
- Notification trigger — shows triggers doing real work, not just qty updates
- SVG match score ring — visual but implemented in plain SVG + CSS, no library needed
- Vercel + Railway deployment — makes the project demonstrable online

---

## 10. Key Decisions and Why

**Why no framework (React/Vue)?**
The project already works in Vanilla JS. Adding a framework for a DBMS project shifts attention away from the database onto the framework. A professor evaluating DBMS concepts should focus on triggers, not useState hooks.

**Why vanilla CSS instead of Tailwind?**
The project uses a single `style.css`. Tailwind requires a build step. For a student running this locally or deploying to Vercel as static files, a build step adds friction. Custom CSS is also easier to explain in a viva.

**Why is the Match Score in the stored procedure, not Python?**
Because the project philosophy is "Flask stays thin, MySQL does the work." Computing scores in Python would mean pulling raw data from MySQL into Python memory and processing it there — that defeats the purpose of a DBMS project. The procedure does weighted math inside MySQL and returns a final score. Flask passes it through.

**Why Railway for Flask + MySQL?**
Railway is the simplest platform that supports both Python web apps and MySQL databases. It has a generous free tier for student projects. The alternative (Heroku) charges for MySQL. PlanetScale (free MySQL) works but requires schema migration commands that a student might find confusing.

---

*End of IWES Technical Plan V2.0*
