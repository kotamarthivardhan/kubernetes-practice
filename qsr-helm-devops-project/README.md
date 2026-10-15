# QSR DevOps Project — Helm + GitOps

This archive contains two Git repositories plus Terraform infrastructure code:
- `qsr-app/`: Flask API, tests, Dockerfile, GitHub Actions CI/CD.
- `qsr-gitops/`: Helm chart, environment values, and Argo CD Application. **Kustomize is not used.**
- `terraform/`: VPC, EKS, ECR, GitHub OIDC/IAM, Argo CD, Prometheus/Grafana infrastructure.
- `docs/ARCHITECTURE.md`: architecture and delivery flow.
- `docs/STEP_BY_STEP.md`: execution guide.

## Delivery flow

1. Push code to `qsr-app/main`.
2. GitHub Actions runs unit tests, Ruff, Bandit, pip-audit, and Trivy filesystem scans.
3. It builds the Docker image and scans the image with Trivy.
4. A successful `main` build pushes an immutable commit-SHA-tagged image to ECR.
5. CI updates `image.repository` and `image.tag` in `qsr-gitops/helm/qsr-orders/values-prod.yaml` and commits the change.
6. Argo CD watches the GitOps repository, renders the Helm chart, and deploys to EKS.
7. Prometheus scrapes `/metrics`; JSON application logs go to stdout/stderr for collection by CloudWatch or another logging stack.

This is a runnable reference project, not a live provisioned environment. Configure AWS, GitHub, and Argo CD first. The demo order API stores data in memory; use a durable database before handling real orders.
