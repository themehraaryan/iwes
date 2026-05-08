import mysql.connector
from flask import Blueprint, jsonify, request

from db import fetch_procedure_rows, get_db_connection
from utils import login_required, serialize_rows


match_bp = Blueprint("match", __name__)


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
        matches = fetch_procedure_rows(
            cursor,
            "match_listings",
            (product_id, qty_needed),
        )
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
