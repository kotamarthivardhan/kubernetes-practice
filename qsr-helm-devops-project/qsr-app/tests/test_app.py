import app as qsr


def setup_function():
    qsr.ORDERS.clear()


def test_health_and_readiness():
    client = qsr.app.test_client()
    assert client.get("/health").status_code == 200
    assert client.get("/ready").json == {"status": "ready"}


def test_create_order_success():
    response = qsr.app.test_client().post(
        "/orders",
        json={"item": "Veg Burger", "quantity": 2, "store_id": "store-101"},
    )
    assert response.status_code == 201
    assert response.json["item"] == "Veg Burger"
    assert response.json["quantity"] == 2
    assert response.json["status"] == "ACCEPTED"
    assert "order_id" in response.json


def test_reject_invalid_quantity():
    response = qsr.app.test_client().post(
        "/orders",
        json={"item": "Burger", "quantity": 0, "store_id": "store-101"},
    )
    assert response.status_code == 400


def test_reject_non_json_body():
    response = qsr.app.test_client().post(
        "/orders",
        data="not-json",
        content_type="text/plain",
    )
    assert response.status_code == 400


def test_metrics_endpoint():
    client = qsr.app.test_client()
    client.get("/health")
    response = client.get("/metrics")
    assert response.status_code == 200
    assert b"qsr_http_requests_total" in response.data
