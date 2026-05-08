import bcrypt
import mysql.connector
from flask import Blueprint, jsonify, request, session

from db import get_db_connection
from utils import login_required, serialize_row


auth_bp = Blueprint("auth", __name__, url_prefix="/auth")


@auth_bp.post("/register")
def register():
    data = request.get_json(silent=True) or {}
    name = (data.get("name") or "").strip()
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""
    phone = (data.get("phone") or "").strip() or None

    if not name or not email or not password:
        return jsonify({"error": "Name, email, and password are required"}), 400

    password_hash = bcrypt.hashpw(
        password.encode("utf-8"),
        bcrypt.gensalt(),
    ).decode("utf-8")

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            INSERT INTO Users (name, email, password_hash, phone)
            VALUES (%s, %s, %s, %s)
            """,
            (name, email, password_hash, phone),
        )
        connection.commit()
        user_id = cursor.lastrowid

        return jsonify(
            {
                "message": "Registration successful",
                "user": {
                    "user_id": user_id,
                    "name": name,
                    "email": email,
                    "phone": phone,
                },
            }
        ), 201
    except mysql.connector.Error as err:
        if connection:
            connection.rollback()
        if err.errno == 1062:
            return jsonify({"error": "Email already registered"}), 400
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@auth_bp.post("/login")
def login():
    data = request.get_json(silent=True) or {}
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    if not email or not password:
        return jsonify({"error": "Email and password are required"}), 400

    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT user_id, name, email, password_hash, phone, created_at
            FROM Users
            WHERE email = %s
            """,
            (email,),
        )
        user = cursor.fetchone()

        if not user or not bcrypt.checkpw(
            password.encode("utf-8"),
            user["password_hash"].encode("utf-8"),
        ):
            return jsonify({"error": "Invalid email or password"}), 401

        session["user_id"] = user["user_id"]
        session["name"] = user["name"]
        session["email"] = user["email"]

        user.pop("password_hash", None)
        return jsonify({"message": "Login successful", "user": serialize_row(user)}), 200
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()


@auth_bp.post("/logout")
@login_required
def logout():
    session.clear()
    return jsonify({"message": "Logout successful"}), 200


@auth_bp.get("/me")
@login_required
def me():
    connection = None
    cursor = None
    try:
        connection = get_db_connection()
        cursor = connection.cursor(dictionary=True)
        cursor.execute(
            """
            SELECT user_id, name, email, phone, created_at
            FROM Users
            WHERE user_id = %s
            """,
            (session["user_id"],),
        )
        user = cursor.fetchone()

        if not user:
            session.clear()
            return jsonify({"error": "User not found"}), 404

        return jsonify({"user": serialize_row(user)}), 200
    except mysql.connector.Error as err:
        return jsonify({"error": str(err)}), 500
    except RuntimeError as err:
        return jsonify({"error": str(err)}), 500
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()
