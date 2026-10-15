# QSR GitOps Repository — Helm

Argo CD watches this repository and deploys the Helm chart to EKS. **This repo uses Helm, not Kustomize.**

- `argocd/qsr-prod.yaml`: Argo CD Application.
- `helm/qsr-orders/Chart.yaml`: chart metadata.
- `helm/qsr-orders/values.yaml`: base chart values.
- `helm/qsr-orders/values-prod.yaml`: production overrides and ECR image URI/tag.
- `helm/qsr-orders/templates/`: Deployment, Service, ServiceMonitor, and PDB.

CI updates only `image.repository` and `image.tag` in `values-prod.yaml`. Before the first sync, use an image URI and tag that already exist in ECR. Configure Argo CD credentials if this repository is private.
