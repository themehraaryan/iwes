import mysql.connector
from flask import Blueprint, jsonify, session

from db import get_db_connection
from utils import login_required, serialize_rows


notifications_bp = Blueprint("notifications", __name__)


@notifications_bp.get("/notifications")
@login_required
def get_unread_notifications():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT notif_id, user_id, type, message, related_id, is_read, created_at
            FROM Notifications
            WHERE user_id = %s AND is_read = 0
            ORDER BY created_at DESC
            """,
            (session["user_id"],),
        )
        notifications = cursor.fetchall()
        return jsonify({"notifications": serialize_rows(notifications)}), 200
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@notifications_bp.post("/notifications/read/<int:notif_id>")
@login_required
def mark_notification_as_read(notif_id):
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            UPDATE Notifications
            SET is_read = 1
            WHERE notif_id = %s AND user_id = %s
            """,
            (notif_id, session["user_id"]),
        )
        if cursor.rowcount == 0:
            return jsonify({"error": "Notification not found"}), 404

        connection.commit()
        return jsonify({"message": "Notification marked as read"}), 200
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
