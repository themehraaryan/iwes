import mysql.connector
from flask import Blueprint, jsonify

from db import get_db_connection
from utils import serialize_rows


products_bp = Blueprint("products", __name__)


@products_bp.get("/products")
def get_products():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT product_id, name, category, unit, possible_uses
            FROM Products
            ORDER BY category ASC, name ASC
            """
        )
        products = cursor.fetchall()
        return jsonify({"products": serialize_rows(products)}), 200
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
