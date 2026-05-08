from datetime import date, datetime
from decimal import Decimal
from functools import wraps

from flask import jsonify, session


def login_required(view_func):
    @wraps(view_func)
    def wrapped_view(*args, **kwargs):
        if not session.get("user_id"):
            return jsonify({"error": "Login required"}), 401
        return view_func(*args, **kwargs)

    return wrapped_view


def to_json_value(value):
    if isinstance(value, Decimal):
        return float(value)
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    return value


def serialize_row(row):
    return {key: to_json_value(value) for key, value in row.items()}


def serialize_rows(rows):
    return [serialize_row(row) for row in rows]
