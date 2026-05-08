import mysql.connector
from flask import Blueprint, jsonify, request, session

from db import fetch_procedure_rows, get_db_connection
from utils import login_required, serialize_row, serialize_rows


transactions_bp = Blueprint("transactions", __name__)


def _view_exists(cursor, view_name):
    cursor.execute(
        """
        SELECT 1
        FROM information_schema.VIEWS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = %s
        LIMIT 1
        """,
        (view_name,),
    )
    return cursor.fetchone() is not None


def _bad_db_request(err):
    if getattr(err, "errno", None) == 1644 or getattr(err, "sqlstate", None) == "45000":
        return jsonify({"error": err.msg}), 400
    return jsonify({"error": str(err)}), 500


@transactions_bp.post("/transact")
@login_required
def create_transaction():
    data = request.get_json(silent=True) or {}
    listing_id = data.get("listing_id")
    qty = data.get("qty", data.get("qty_exchanged"))

    if not listing_id or qty is None:
        return jsonify({"error": "listing_id and qty are required"}), 400

    try:
        listing_id = int(listing_id)
        qty = float(qty)
    except (TypeError, ValueError):
        return jsonify({"error": "listing_id and qty must be valid numbers"}), 400

    if qty <= 0:
        return jsonify({"error": "qty must be greater than zero"}), 400
    if listing_id <= 0:
        return jsonify({"error": "listing_id must be greater than zero"}), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        rows = fetch_procedure_rows(
            cursor,
            "create_transaction",
            (listing_id, session["user_id"], qty),
        )
        transaction = rows[0] if rows else None
        connection.commit()

        return jsonify(
            {
                "message": "Transaction created",
                "transaction": serialize_row(transaction),
            }
        ), 201
    except mysql.connector.Error as err:
        if connection:
            connection.rollback()
        return _bad_db_request(err)
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@transactions_bp.get("/transactions/history")
@login_required
def transaction_history():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        if _view_exists(cursor, "vw_recent_transactions"):
            cursor.execute(
                """
                SELECT *
                FROM vw_recent_transactions
                WHERE buyer_id = %s OR seller_id = %s
                ORDER BY txn_date DESC
                """,
                (session["user_id"], session["user_id"]),
            )
        else:
            cursor.execute(
                """
                SELECT
                    t.txn_id,
                    t.listing_id,
                    t.buyer_id,
                    buyer.name AS buyer_name,
                    t.seller_id,
                    seller.name AS seller_name,
                    p.product_id,
                    p.name AS product_name,
                    p.category,
                    p.unit,
                    l.listing_type,
                    t.qty_exchanged,
                    t.status,
                    t.txn_date
                FROM Transactions t
                INNER JOIN Listings l ON l.listing_id = t.listing_id
                INNER JOIN Products p ON p.product_id = l.product_id
                INNER JOIN Users buyer ON buyer.user_id = t.buyer_id
                INNER JOIN Users seller ON seller.user_id = t.seller_id
                WHERE t.buyer_id = %s OR t.seller_id = %s
                ORDER BY t.txn_date DESC
                """,
                (session["user_id"], session["user_id"]),
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
