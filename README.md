# IWES - Industrial Waste Exchange System

IWES is a local DBMS project for demonstrating an Industrial Waste Exchange System using Flask, vanilla frontend files, and MySQL 8.

## Tech Stack

- Frontend: HTML5, CSS3, Vanilla JavaScript
- Backend: Python, Flask, mysql-connector-python, bcrypt, Flask-Session
- Database: MySQL 8

## How to Run on Localhost

### 1. Configure MySQL

Create a local MySQL database and update the root `.env` file with your credentials:

```env
DB_HOST=localhost
DB_USER=root
DB_PASS=yourpassword
DB_NAME=iwes_db
SECRET_KEY=replace_with_a_random_secret_key
```

### 2. Load the database files

Run the SQL files in this order:

```powershell
mysql -u root -p < database\schema.sql
mysql -u root -p < database\triggers.sql
mysql -u root -p < database\procedures.sql
mysql -u root -p < database\views.sql
mysql -u root -p < database\seed_data.sql
```

### 3. Set up the backend virtual environment

```powershell
cd backend
python -m venv venv
.\venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

If PowerShell blocks activation, run this once in the same terminal:

```powershell
Set-ExecutionPolicy -Scope Process RemoteSigned
```

### 4. Start the Flask backend

From the `backend` folder, run:

```powershell
.\venv\Scripts\python.exe app.py
```

The backend will run at:

```text
http://127.0.0.1:5000
```

You can verify it with:

```text
http://127.0.0.1:5000/ping
```

Expected response:

```json
{"status":"ok"}
```

### 5. Start the frontend on localhost

Open a second terminal and run:

```powershell
cd frontend
..\backend\venv\Scripts\python.exe -m http.server 8000 --bind 127.0.0.1
```

Open the app in your browser at:

```text
http://127.0.0.1:8000/index.html
```

### 6. Login and use the app

- Start from the landing page and use the Log In or Create Account buttons
- After login, use the dashboard, listings, match, and analytics pages

## Notes

- Do not open the HTML files directly with `file://`; serve them from `http://127.0.0.1:8000` so the frontend can call the Flask backend correctly.
- The backend and frontend are designed for local demo use only.
