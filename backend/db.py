import logging

import mysql.connector
from mysql.connector import Error
from mysql.connector.pooling import MySQLConnectionPool

from config import Config


logger = logging.getLogger(__name__)
logging.getLogger("mysql.connector").setLevel(logging.WARNING)
_connection_pool = None


def _get_connection_pool():
    global _connection_pool
    if _connection_pool is None:
        _connection_pool = MySQLConnectionPool(
            pool_name="iwes_pool",
            pool_size=10,
            host=Config.DB_HOST,
            user=Config.DB_USER,
            password=Config.DB_PASS,
            database=Config.DB_NAME,
            connection_timeout=5,
        )
    return _connection_pool


def get_db_connection():
    try:
        return _get_connection_pool().get_connection()
    except Error as err:
        raise RuntimeError(f"Database connection failed: {err}") from err


def test_db_connection():
    try:
        connection = get_db_connection()
        connection.close()
        logger.info("Database connection successful: %s", Config.DB_NAME)
        return True
    except RuntimeError as err:
        logger.error("%s", err)
        return False


def fetch_procedure_rows(cursor, procedure_name, args):
    cursor.callproc(procedure_name, args)
    for result in cursor.stored_results():
        return result.fetchall()
    return []
