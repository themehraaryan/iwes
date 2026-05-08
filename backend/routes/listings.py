import mysql.connector
from flask import Blueprint, jsonify, request, session

from db import get_db_connection
from utils import login_required, serialize_row, serialize_rows


listings_bp = Blueprint("listings", __name__)


def _table_has_column(cursor, table_name, column_name):
    cursor.execute(f"SHOW COLUMNS FROM {table_name} LIKE %s", (column_name,))
    return cursor.fetchone() is not None


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


@listings_bp.get("/listings")
def get_listings():
    category = (request.args.get("category") or "").strip()
    listing_type = (request.args.get("type") or "").strip().upper()
    min_qty = (request.args.get("min_qty") or "").strip()

    if listing_type:
        if listing_type not in ("BUY", "SELL"):
            return jsonify({"error": "type must be BUY or SELL"}), 400
    else:
        listing_type = None

    min_qty_value = None
    if min_qty:
        try:
            min_qty_value = float(min_qty)
        except ValueError:
            return jsonify({"error": "min_qty must be a number"}), 400
        if min_qty_value < 0:
            return jsonify({"error": "min_qty cannot be negative"}), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        if _view_exists(cursor, "vw_active_listings"):
            cursor.execute(
                """
                SELECT *
                FROM vw_active_listings
                WHERE (%s = '' OR category = %s)
                  AND (%s IS NULL OR listing_type = %s)
                  AND (%s IS NULL OR available_qty >= %s)
                ORDER BY created_at DESC
                """,
                (
                    category,
                    category,
                    listing_type,
                    listing_type,
                    min_qty_value,
                    min_qty_value,
                ),
            )
        else:
            cursor.execute(
                """
                SELECT
                    l.listing_id,
                    l.user_id,
                    u.name AS user_name,
                    u.email AS user_email,
                    u.phone AS user_phone,
                    l.product_id,
                    p.name AS product_name,
                    p.category,
                    p.unit,
                    p.possible_uses,
                    l.listing_type,
                    l.total_qty,
                    l.available_qty,
                    l.price_per_unit,
                    l.location,
                    l.status,
                    l.created_at
                FROM Listings l
                INNER JOIN Users u ON u.user_id = l.user_id
                INNER JOIN Products p ON p.product_id = l.product_id
                WHERE l.status = 'ACTIVE'
                  AND (%s = '' OR p.category = %s)
                  AND (%s IS NULL OR l.listing_type = %s)
                  AND (%s IS NULL OR l.available_qty >= %s)
                ORDER BY l.created_at DESC
                """,
                (
                    category,
                    category,
                    listing_type,
                    listing_type,
                    min_qty_value,
                    min_qty_value,
                ),
            )
        listings = cursor.fetchall()
        return jsonify({"listings": serialize_rows(listings)}), 200
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@listings_bp.post("/listings/create")
@login_required
def create_listing():
    data = request.get_json(silent=True) or {}
    product_id = data.get("product_id")
    listing_type = (data.get("listing_type") or "").strip().upper()
    total_qty = data.get("total_qty")
    price_per_unit = data.get("price_per_unit")
    location = (data.get("location") or "").strip() or None
    city = (data.get("city") or "").strip() or None

    if not product_id or not listing_type or total_qty is None:
        return jsonify({"error": "product_id, listing_type, and total_qty are required"}), 400
    if listing_type not in ("BUY", "SELL"):
        return jsonify({"error": "listing_type must be BUY or SELL"}), 400

    try:
        product_id = int(product_id)
        total_qty = float(total_qty)
        price_per_unit = None if price_per_unit in (None, "") else float(price_per_unit)
    except (TypeError, ValueError):
        return jsonify({"error": "product_id, total_qty, and price_per_unit must be valid numbers"}), 400

    if total_qty <= 0:
        return jsonify({"error": "total_qty must be greater than zero"}), 400
    if product_id <= 0:
        return jsonify({"error": "product_id must be greater than zero"}), 400
    if price_per_unit is not None and price_per_unit < 0:
        return jsonify({"error": "price_per_unit cannot be negative"}), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        has_city = _table_has_column(cursor, "Listings", "city")
        if has_city:
            cursor.execute(
                """
                INSERT INTO Listings (
                    user_id,
                    product_id,
                    listing_type,
                    total_qty,
                    available_qty,
                    price_per_unit,
                    location,
                    city
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    session["user_id"],
                    product_id,
                    listing_type,
                    total_qty,
                    total_qty,
                    price_per_unit,
                    location,
                    city,
                ),
            )
        else:
            cursor.execute(
                """
                INSERT INTO Listings (
                    user_id,
                    product_id,
                    listing_type,
                    total_qty,
                    available_qty,
                    price_per_unit,
                    location
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                """,
                (
                    session["user_id"],
                    product_id,
                    listing_type,
                    total_qty,
                    total_qty,
                    price_per_unit,
                    location,
                ),
            )
        connection.commit()
        listing_id = cursor.lastrowid

        cursor.execute(
            "SELECT * FROM Listings WHERE listing_id = %s",
            (listing_id,),
        )
        listing = cursor.fetchone()
        return jsonify(
            {
                "message": "Listing created",
                "listing": serialize_row(listing),
            }
        ), 201
    except mysql.connector.Error as err:
        if connection:
            connection.rollback()
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@listings_bp.get("/listings/my")
@login_required
def my_listings():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT
                l.listing_id,
                l.user_id,
                l.product_id,
                p.name AS product_name,
                p.category,
                p.unit,
                p.possible_uses,
                l.listing_type,
                l.total_qty,
                l.available_qty,
                l.price_per_unit,
                l.location,
                l.status,
                l.created_at
            FROM Listings l
            INNER JOIN Products p ON p.product_id = l.product_id
            WHERE l.user_id = %s
            ORDER BY l.created_at DESC
            """,
            (session["user_id"],),
        )
        listings = cursor.fetchall()
        return jsonify({"listings": serialize_rows(listings)}), 200
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@listings_bp.delete("/listings/<int:listing_id>")
@login_required
def delete_listing(listing_id):
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT listing_id
            FROM Listings
            WHERE listing_id = %s AND user_id = %s
            """,
            (listing_id, session["user_id"]),
        )
        listing = cursor.fetchone()

        if not listing:
            return jsonify({"error": "Listing not found"}), 404

        cursor.execute(
            """
            DELETE FROM Listings
            WHERE listing_id = %s AND user_id = %s
            """,
            (listing_id, session["user_id"]),
        )
        connection.commit()
        return jsonify({"message": "Listing deleted"}), 200
    except mysql.connector.Error as err:
        if connection:
            connection.rollback()
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
