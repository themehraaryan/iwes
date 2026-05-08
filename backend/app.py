from pathlib import Path
import logging

from flask import Flask, jsonify, request
from flask_session import Session

from config import Config
from db import test_db_connection
from routes.analytics import analytics_bp
from routes.auth import auth_bp
from routes.listings import listings_bp
from routes.match import match_bp
from routes.products import products_bp
from routes.ratings import ratings_bp
from routes.transactions import transactions_bp


app = Flask(__name__)
app.config.from_object(Config)
Path(app.config["SESSION_FILE_DIR"]).mkdir(parents=True, exist_ok=True)
Session(app)
app.register_blueprint(auth_bp)
app.register_blueprint(listings_bp)
app.register_blueprint(products_bp)
app.register_blueprint(transactions_bp)
app.register_blueprint(match_bp)
app.register_blueprint(analytics_bp)
app.register_blueprint(ratings_bp)


@app.after_request
def add_cors_headers(response):
    allowed_origins = {
        "http://127.0.0.1:5500",
        "http://localhost:5500",
        "http://127.0.0.1:8000",
        "http://localhost:8000",
    }
    origin = request.headers.get("Origin")
    if origin in allowed_origins:
        response.headers["Access-Control-Allow-Origin"] = origin
    response.headers["Access-Control-Allow-Credentials"] = "true"
    response.headers["Access-Control-Allow-Headers"] = "Content-Type"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, DELETE, OPTIONS"
    return response


@app.get("/ping")
def ping():
    return jsonify({"status": "ok"}), 200


@app.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Route not found"}), 404


@app.errorhandler(405)
def method_not_allowed(error):
    return jsonify({"error": "Method not allowed for this route"}), 405


@app.errorhandler(500)
def internal_server_error(error):
    return jsonify({"error": "Internal server error"}), 500


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    test_db_connection()
    app.run(debug=True)
