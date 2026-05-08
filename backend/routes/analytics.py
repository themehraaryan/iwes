import mysql.connector
from flask import Blueprint, jsonify, session

from db import fetch_procedure_rows, get_db_connection
from utils import login_required, serialize_row, serialize_rows


analytics_bp = Blueprint("analytics", __name__, url_prefix="/analytics")


@analytics_bp.get("/top-waste")
@login_required
def top_waste():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT *
            FROM vw_top_waste_types
            LIMIT 10
            """
        )
        rows = cursor.fetchall()
        return jsonify({"top_waste": serialize_rows(rows)}), 200
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@analytics_bp.get("/summary")
@login_required
def summary():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        rows = fetch_procedure_rows(
            cursor,
            "get_user_summary",
            (session["user_id"],),
        )
        user_summary = rows[0] if rows else None
        if not user_summary:
            return jsonify({"error": "User not found"}), 404
        return jsonify({"summary": serialize_row(user_summary)}), 200
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@analytics_bp.get("/recent")
@login_required
def recent_transactions():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT *
            FROM vw_recent_transactions
            LIMIT 20
            """
        )
        transactions = cursor.fetchall()
        return jsonify({"transactions": serialize_rows(transactions)}), 200
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
