```
You are helping me build IWES (Industrial Waste Exchange System) — a college DBMS project
for B.Tech at JIIT Noida. This is NOT a production SaaS app. It runs locally for
demonstration and viva purposes.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
REFERENCE FILES — READ THESE FIRST BEFORE ANY CODE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Read codex.md — understand current project state, what is built, what is not
2. Read TECHNICAL_PLAN.md — full schema, DBMS features, routes, design decisions

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TECH STACK — DO NOT DEVIATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Frontend : HTML5 + CSS3 + Vanilla JavaScript (Fetch API). NO frameworks.
Backend  : Python + Flask + mysql-connector-python + bcrypt + Flask-Session.
           Secrets loaded from .env using python-dotenv.
           Python venv for isolation.
Database : MySQL 8. This is a DBMS project — MySQL is the star.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PROJECT PHILOSOPHY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Flask must stay THIN. All business logic lives in MySQL:
  - Triggers handle qty updates and listing completion
  - Stored procedures handle transactions and matching
  - Views handle all analytics queries
Flask only does: parse HTTP → check session → call DB → return JSON.

Frontend must look VERY GOOD — clean card layout, professional colour scheme
(deep blue #1F4E79 primary, white bg), responsive, smooth UX with loading
states and toast notifications. No raw alert() calls.

DBMS concepts must be visible and explainable — this project has a viva.
Every trigger, procedure, and view must have a comment block at the top of
the SQL file explaining WHAT it does and WHY in plain English (3-5 lines).

Complexity: KEEP IT MANAGEABLE. No microservices, no Docker, no message queues.
A second-year CS student must be able to understand and explain every line.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FOLDER STRUCTURE — NEVER CHANGE THIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
iwes/
├── TECHNICAL_PLAN.md       ← design reference for Codex and the developer
├── codex.md                ← living project log — read first, update last
├── README.md
├── .env                    ← DB_HOST DB_USER DB_PASS DB_NAME SECRET_KEY
├── .gitignore
├── backend/
│   ├── app.py              ← Flask entry + blueprint registration
│   ├── db.py               ← MySQL connection helper
│   ├── config.py           ← loads .env
│   ├── utils.py            ← login_required decorator
│   ├── requirements.txt
│   └── routes/
│       ├── auth.py         ← /auth/register /auth/login /auth/logout /auth/me
│       ├── listings.py     ← /listings CRUD + /listings/my
│       ├── transactions.py ← /transact /transactions/history
│       ├── match.py        ← /match
│       ├── analytics.py    ← /analytics/top-waste /analytics/summary /analytics/recent
│       └── ratings.py      ← /rate
├── frontend/
│   ├── login.html · register.html · dashboard.html
│   ├── listings.html · match.html · analytics.html
│   ├── style.css           ← shared styles
│   └── main.js             ← checkLogin() apiCall() showToast()
└── database/
    ├── schema.sql          ← CREATE DATABASE + 6 tables + FK + indexes
    ├── triggers.sql        ← before_txn_insert + after_txn_insert
    ├── procedures.sql      ← create_transaction + match_listings + get_user_summary
    ├── views.sql           ← 4 views
    └── seed_data.sql       ← waste categories + test users + sample listings

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DATABASE — 6 TABLES SUMMARY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Users        — user_id, name, email, password_hash, phone, created_at
Products     — product_id, name, category, unit, possible_uses
Listings     — listing_id, user_id, product_id, listing_type(BUY/SELL),
               total_qty, available_qty, price_per_unit, location,
               status(ACTIVE/COMPLETED/EXPIRED), created_at
Transactions — txn_id, listing_id, buyer_id, seller_id, qty_exchanged,
               txn_date, status(PENDING/DONE/CANCELLED)
WasteMapping — mapping_id, product_id, alternative_use, industry
Ratings      — rating_id, txn_id, rater_id, ratee_id, score(1-5), comment

KEY RULE: total_qty never changes. available_qty is decremented by trigger.
When available_qty = 0, trigger sets status = COMPLETED.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
DBMS FEATURES — WHAT IS IMPLEMENTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Triggers:
  before_txn_insert  — BEFORE INSERT on Transactions, blocks overbooking
  after_txn_insert   — AFTER INSERT on Transactions, decrements qty, auto-completes

Stored Procedures:
  create_transaction(listing_id, buyer_id, qty)
  match_listings(product_id, qty_needed)
  get_user_summary(user_id)

Views:
  vw_active_listings       — JOIN Listings+Users+Products WHERE ACTIVE
  vw_top_waste_types       — GROUP BY category ORDER BY txn count DESC
  vw_user_activity         — per-user listing and transaction counts
  vw_recent_transactions   — last 30 days with full buyer/seller/product names

Event: expire_old_listings — runs daily, expires listings older than 90 days

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CODEX.MD — MANDATORY WORKFLOW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BEFORE writing any code:
  1. Read codex.md — understand current project state
  2. Read TECHNICAL_PLAN.md — confirm what needs to be built

AFTER completing the session, update codex.md:
  1. Move completed items to "What is built"
  2. Remove them from "What is NOT built yet"
  3. Update "DB Features Status" if anything changed
  4. Append to "Session Log" with a one-paragraph summary
  5. Rewrite "How to Test This Session" with exact test steps
  6. Note any bugs in "Known Issues"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CODING STANDARDS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Python:
  - Load .env with python-dotenv. Never hardcode credentials.
  - All routes return JSON with jsonify().
  - Use login_required decorator from utils.py to protect routes.
  - Return proper HTTP codes: 200 201 400 401 404 500.
  - Wrap all DB calls in try/except, return {error: message} on failure.
  - Use parameterised queries always — never string concatenation in SQL.

MySQL SQL:
  - Every trigger/procedure/view has a comment block explaining WHAT and WHY.
  - Use DELIMITER $$ for procedures and triggers.

JavaScript / HTML:
  - No alert() — use showToast() from main.js.
  - Disable buttons during fetch loading, re-enable after.
  - Check sessionStorage for user_id at top of every page.
  - Use async/await for all fetch calls.
  - CSS palette: primary #1F4E79, accent #0E6655, bg #F8F9FA, card #FFFFFF.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HARD RULES — NEVER DO THESE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
- Do NOT use SQLAlchemy or any ORM. Raw SQL only.
- Do NOT use React, Vue, Angular, or any JS framework.
- Do NOT add Docker, Redis, Celery, or extra infrastructure.
- Do NOT put logic in Flask that belongs in MySQL.
- Do NOT skip the codex.md update at end of session.
- Do NOT add features outside the current session scope.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[PASTE SESSION-SPECIFIC INSTRUCTIONS BELOW THIS LINE]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## How to use this file

1. Copy everything inside the code block above
2. Open your Codex session
3. Paste the preamble
4. Append the specific session prompt from `PROMPT_SESSIONS.md`
5. Send

At the end of every session, copy the updated `codex.md` content back into your local `codex.md` file.
