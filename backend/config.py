import os
from pathlib import Path

from dotenv import load_dotenv


BASE_DIR = Path(__file__).resolve().parent.parent
load_dotenv(BASE_DIR / ".env")
DEFAULT_SESSION_DIR = Path(os.getenv("TEMP", r"C:\tmp")) / "iwes_flask_session"


class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "dev_secret_key")
    SESSION_TYPE = "filesystem"
    SESSION_FILE_DIR = os.getenv(
        "SESSION_FILE_DIR",
        str(DEFAULT_SESSION_DIR),
    )
    SESSION_PERMANENT = False

    DB_HOST = os.getenv("DB_HOST", "localhost")
    DB_USER = os.getenv("DB_USER", "root")
    DB_PASS = os.getenv("DB_PASS", "")
    DB_NAME = os.getenv("DB_NAME", "iwes_db")
    DB_PORT = int(os.getenv("DB_PORT", 3306))
