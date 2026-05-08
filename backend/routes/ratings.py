import mysql.connector
from flask import Blueprint, jsonify, request, session

from db import get_db_connection
from utils import login_required, serialize_row


ratings_bp = Blueprint("ratings", __name__)


@ratings_bp.post("/rate")
@login_required
def rate_user():
    data = request.get_json(silent=True) or {}
    txn_id = data.get("txn_id")
    score = data.get("score")
    comment = (data.get("comment") or "").strip() or None

    if not txn_id or score is None:
        return jsonify({"error": "txn_id and score are required"}), 400

    try:
        txn_id = int(txn_id)
        score = int(score)
    except (TypeError, ValueError):
        return jsonify({"error": "txn_id and score must be valid numbers"}), 400

    if score < 1 or score > 5:
        return jsonify({"error": "score must be between 1 and 5"}), 400
    if txn_id <= 0:
        return jsonify({"error": "txn_id must be greater than zero"}), 400
    if comment and len(comment) > 500:
        return jsonify({"error": "comment cannot exceed 500 characters"}), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT txn_id, buyer_id, seller_id, status
            FROM Transactions
            WHERE txn_id = %s
              AND (buyer_id = %s OR seller_id = %s)
            """,
            (txn_id, session["user_id"], session["user_id"]),
        )
        transaction = cursor.fetchone()

        if not transaction:
            return jsonify({"error": "Transaction not found for current user"}), 404
        if transaction["status"] != "DONE":
            return jsonify({"error": "Only completed transactions can be rated"}), 400

        cursor.execute(
            """
            SELECT rating_id
            FROM Ratings
            WHERE txn_id = %s AND rater_id = %s
            """,
            (txn_id, session["user_id"]),
        )
        if cursor.fetchone():
            return jsonify({"error": "You have already rated this transaction"}), 400

        if transaction["buyer_id"] == session["user_id"]:
            ratee_id = transaction["seller_id"]
        else:
            ratee_id = transaction["buyer_id"]

        cursor.execute(
            """
            INSERT INTO Ratings (txn_id, rater_id, ratee_id, score, comment)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (txn_id, session["user_id"], ratee_id, score, comment),
        )
        connection.commit()
        rating_id = cursor.lastrowid

        cursor.execute(
            """
            SELECT rating_id, txn_id, rater_id, ratee_id, score, comment, rated_at
            FROM Ratings
            WHERE rating_id = %s
            """,
            (rating_id,),
        )
        rating = cursor.fetchone()
        return jsonify(
            {
                "message": "Rating submitted",
                "rating": serialize_row(rating),
            }
        ), 201
    except mysql.connector.Error as err:
        if connection:
            connection.rollback()
        if err.errno == 1062:
            return jsonify({"error": "You have already rated this transaction"}), 400
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
