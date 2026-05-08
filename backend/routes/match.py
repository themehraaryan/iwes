import mysql.connector
from flask import Blueprint, jsonify, request, session

from db import fetch_procedure_rows, get_db_connection
from utils import login_required, serialize_rows


match_bp = Blueprint("match", __name__)


def _table_has_column(cursor, table_name, column_name):
    cursor.execute(f"SHOW COLUMNS FROM {table_name} LIKE %s", (column_name,))
    return cursor.fetchone() is not None


@match_bp.post("/match")
@login_required
def find_matches():
    data = request.get_json(silent=True) or {}
    product_id = data.get("product_id")
    qty_needed = data.get("qty_needed", data.get("qty"))

    if not product_id or qty_needed is None:
        return jsonify({"error": "product_id and qty_needed are required"}), 400

    try:
        product_id = int(product_id)
        qty_needed = float(qty_needed)
    except (TypeError, ValueError):
        return jsonify({"error": "product_id and qty_needed must be valid numbers"}), 400

    if qty_needed <= 0:
        return jsonify({"error": "qty_needed must be greater than zero"}), 400
    if product_id <= 0:
        return jsonify({"error": "product_id must be greater than zero"}), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        buyer_city = None
        if _table_has_column(cursor, "Users", "city"):
            cursor.execute(
                """
                SELECT city
                FROM Users
                WHERE user_id = %s
                """,
                (session["user_id"],),
            )
            user = cursor.fetchone()
            buyer_city = user["city"] if user else None

        try:
            matches = fetch_procedure_rows(
                cursor,
                "match_listings",
                (product_id, qty_needed, buyer_city),
            )
        except mysql.connector.Error as err:
            # V1 procedure signature: match_listings(product_id, qty_needed)
            if getattr(err, "errno", None) == 1318:
                matches = fetch_procedure_rows(
                    cursor,
                    "match_listings",
                    (product_id, qty_needed),
                )
            # If procedure does not exist in old DB, use direct SQL fallback.
            elif getattr(err, "errno", None) in (1305,):
                cursor.execute(
                    """
                    SELECT
                        l.listing_id,
                        l.user_id AS seller_id,
                        u.name AS seller_name,
                        p.product_id,
                        p.name AS product_name,
                        p.category,
                        p.unit,
                        l.total_qty,
                        l.available_qty,
                        l.price_per_unit,
                        l.location,
                        l.created_at
                    FROM Listings l
                    INNER JOIN Users u ON u.user_id = l.user_id
                    INNER JOIN Products p ON p.product_id = l.product_id
                    WHERE l.product_id = %s
                      AND l.listing_type = 'SELL'
                      AND l.status = 'ACTIVE'
                      AND l.available_qty > 0
                    ORDER BY l.available_qty DESC, l.created_at DESC
                    """,
                    (product_id,),
                )
                matches = cursor.fetchall()
            else:
                raise
        return jsonify({"matches": serialize_rows(matches)}), 200
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
