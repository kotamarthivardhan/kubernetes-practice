# QSR Orders API — Application Repository

Flask API sample with tests, JSON logs, Prometheus metrics, a hardened container, and GitHub Actions CI/CD.

## Run locally
```bash
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt -r requirements-dev.txt
pytest -q
python app.py
```
Then visit `http://127.0.0.1:8080/health`, `/ready`, and `/metrics`.

## Endpoints
- `GET /` — service metadata
- `GET /health` — liveness
- `GET /ready` — readiness
- `GET /metrics` — Prometheus metrics
- `POST /orders` — validates and accepts a demo order

Example:
```bash
curl -X POST http://127.0.0.1:8080/orders \
  -H 'Content-Type: application/json' \
  -d '{"item":"Veg Burger","quantity":2,"store_id":"store-101"}'
```

## CI/CD
`.github/workflows/ci-cd.yml` runs tests, lint/security/dependency checks, builds and scans the image, pushes to ECR on `main`, then updates the image tag in the separate GitOps repository.

Required GitHub secrets/variables and IAM OIDC notes are in `../docs/STEP_BY_STEP.md`.
