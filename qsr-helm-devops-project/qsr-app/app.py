import json
import logging
import os
import time
import uuid
from datetime import datetime, timezone

from flask import Flask, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from werkzeug.exceptions import HTTPException

APP_NAME = "qsr-orders-api"
app = Flask(__name__)

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"), format="%(message)s")
logger = logging.getLogger(APP_NAME)

REQUEST_COUNT = Counter(
    "qsr_http_requests_total",
    "Total HTTP requests",
    ["method", "route", "status"],
)
REQUEST_LATENCY = Histogram(
    "qsr_http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["method", "route"],
)
ORDERS_CREATED = Counter("qsr_orders_created_total", "Total accepted demo orders")

# Demo-only storage. Replace with a database and durable transaction handling in production.
ORDERS = []


def log_event(event, **fields):
    payload = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "level": "INFO",
        "service": APP_NAME,
        "event": event,
        **fields,
    }
    logger.info(json.dumps(payload, separators=(",", ":"), default=str))


@app.before_request
def start_timer():
    request.start_time = time.perf_counter()
    request.request_id = request.headers.get("X-Request-ID", str(uuid.uuid4()))


@app.after_request
def record_request(response):
    elapsed = time.perf_counter() - getattr(request, "start_time", time.perf_counter())
    route = request.url_rule.rule if request.url_rule else "unmatched"
    REQUEST_COUNT.labels(request.method, route, str(response.status_code)).inc()
    REQUEST_LATENCY.labels(request.method, route).observe(elapsed)
    response.headers["X-Request-ID"] = getattr(request, "request_id", "unknown")
    log_event(
        "http_request",
        request_id=getattr(request, "request_id", "unknown"),
        method=request.method,
        route=route,
        status=response.status_code,
        duration_ms=round(elapsed * 1000, 2),
    )
    return response


@app.errorhandler(Exception)
def handle_unexpected_error(error):
    if isinstance(error, HTTPException):
        return jsonify(error=error.name, message=error.description), error.code
    log_event("unhandled_exception", error_type=type(error).__name__)
    return jsonify(error="Internal Server Error"), 500


@app.get("/")
def index():
    return jsonify(service=APP_NAME, status="ok", version=os.getenv("APP_VERSION", "local"))


@app.get("/health")
def health():
    return jsonify(status="healthy"), 200


@app.get("/ready")
def ready():
    # Add real dependency checks here when a database or other dependency is introduced.
    return jsonify(status="ready"), 200


@app.get("/metrics")
def metrics():
    from flask import Response
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


@app.post("/orders")
def create_order():
    body = request.get_json(silent=True)
    if not isinstance(body, dict):
        return jsonify(error="Request body must be a JSON object"), 400

    item = body.get("item")
    quantity = body.get("quantity")
    store_id = body.get("store_id")

    if not isinstance(item, str) or not item.strip() or len(item) > 120:
        return jsonify(error="item must be a non-empty string up to 120 characters"), 400
    if isinstance(quantity, bool) or not isinstance(quantity, int) or not 1 <= quantity <= 50:
        return jsonify(error="quantity must be an integer between 1 and 50"), 400
    if not isinstance(store_id, str) or not store_id.strip() or len(store_id) > 64:
        return jsonify(error="store_id must be a non-empty string up to 64 characters"), 400

    order = {
        "order_id": str(uuid.uuid4()),
        "item": item.strip(),
        "quantity": quantity,
        "store_id": store_id.strip(),
        "status": "ACCEPTED",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    ORDERS.append(order)
    ORDERS_CREATED.inc()
    log_event(
        "order_accepted",
        request_id=getattr(request, "request_id", "unknown"),
        order_id=order["order_id"],
        store_id=order["store_id"],
        item=order["item"],
        quantity=quantity,
    )
    return jsonify(order), 201


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
