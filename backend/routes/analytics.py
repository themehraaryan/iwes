import mysql.connector
from flask import Blueprint, jsonify, session

from db import fetch_procedure_rows, get_db_connection
from utils import login_required, serialize_row, serialize_rows


analytics_bp = Blueprint("analytics", __name__, url_prefix="/analytics")


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


@analytics_bp.get("/top-waste")
@login_required
def top_waste():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        if _view_exists(cursor, "vw_top_waste_types"):
            cursor.execute(
                """
                SELECT *
                FROM vw_top_waste_types
                LIMIT 10
                """
            )
        else:
            cursor.execute(
                """
                SELECT
                    p.category,
                    COUNT(t.txn_id) AS transaction_count,
                    COALESCE(SUM(t.qty_exchanged), 0) AS total_qty_exchanged
                FROM Products p
                LEFT JOIN Listings l ON l.product_id = p.product_id
                LEFT JOIN Transactions t ON t.listing_id = l.listing_id
                GROUP BY p.category
                ORDER BY transaction_count DESC, total_qty_exchanged DESC, p.category ASC
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
        if _view_exists(cursor, "vw_recent_transactions"):
            cursor.execute(
                """
                SELECT *
                FROM vw_recent_transactions
                LIMIT 20
                """
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
                ORDER BY t.txn_date DESC
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


@analytics_bp.get("/activity-feed")
@login_required
def activity_feed():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        if _view_exists(cursor, "vw_activity_feed"):
            cursor.execute(
                """
                SELECT *
                FROM vw_activity_feed
                ORDER BY event_time DESC
                LIMIT 10
                """
            )
        else:
            cursor.execute(
                """
                SELECT *
                FROM (
                    SELECT
                        'TRANSACTION' AS event_type,
                        t.txn_id AS event_id,
                        CONCAT(
                            buyer.name,
                            ' transacted ',
                            t.qty_exchanged,
                            ' ',
                            p.unit,
                            ' of ',
                            p.name
                        ) AS message,
                        t.txn_date AS event_time,
                        t.buyer_id AS actor_user_id
                    FROM Transactions t
                    INNER JOIN Users buyer ON buyer.user_id = t.buyer_id
                    INNER JOIN Listings l ON l.listing_id = t.listing_id
                    INNER JOIN Products p ON p.product_id = l.product_id

                    UNION ALL

                    SELECT
                        'LISTING' AS event_type,
                        l.listing_id AS event_id,
                        CONCAT(
                            u.name,
                            ' listed ',
                            l.available_qty,
                            ' ',
                            p.unit,
                            ' of ',
                            p.name,
                            ' (',
                            l.listing_type,
                            ')'
                        ) AS message,
                        l.created_at AS event_time,
                        l.user_id AS actor_user_id
                    FROM Listings l
                    INNER JOIN Users u ON u.user_id = l.user_id
                    INNER JOIN Products p ON p.product_id = l.product_id
                    WHERE l.status = 'ACTIVE'
                ) AS feed_union
                ORDER BY event_time DESC
                LIMIT 10
                """
            )
        rows = cursor.fetchall()
        return jsonify({"activity_feed": serialize_rows(rows)}), 200
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@analytics_bp.get("/insights")
@login_required
def platform_insights():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT
                (SELECT COUNT(*) FROM Listings) AS total_listings,
                (
                    SELECT COUNT(*)
                    FROM Transactions
                    WHERE status IN ('PENDING', 'REQUESTED', 'ACCEPTED', 'IN_TRANSIT', 'DELIVERED')
                ) AS active_transactions,
                (
                    SELECT COALESCE(SUM(qty_exchanged), 0)
                    FROM Transactions
                    WHERE status IN ('DONE', 'COMPLETED')
                ) AS total_waste_diverted,
                (
                    SELECT COALESCE(COUNT(*), 0)
                    FROM Transactions
                    WHERE status IN ('DONE', 'COMPLETED')
                ) AS completed_transactions,
                (
                    SELECT p.name
                    FROM Transactions t
                    INNER JOIN Listings l ON l.listing_id = t.listing_id
                    INNER JOIN Products p ON p.product_id = l.product_id
                    GROUP BY p.name
                    ORDER BY COUNT(*) DESC
                    LIMIT 1
                ) AS most_traded_waste,
                (
                    SELECT COALESCE(ROUND(AVG(score), 2), 0)
                    FROM Ratings
                ) AS avg_platform_rating
            """
        )
        insight = cursor.fetchone() or {}
        return jsonify({"insights": serialize_row(insight)}), 200
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
