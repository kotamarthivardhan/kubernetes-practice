# Step-by-step execution guide — Helm version

## 0. Prerequisites
Install Terraform >= 1.6, AWS CLI v2, Docker, Git, kubectl, Helm, and have access to AWS and GitHub. AWS charges may include EKS, EC2 nodes, NAT Gateway, ECR, and CloudWatch; review costs before applying.

## 1. Provision infrastructure
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```
Edit `terraform.tfvars`: set `github_org`, confirm EKS version availability, and set `admin_cidr_blocks` to your public IP `/32` (never `0.0.0.0/0`). Then run:
```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out qsr.tfplan
terraform apply qsr.tfplan
terraform output
```
Configure kubectl using actual outputs:
```bash
aws eks update-kubeconfig --name "$(terraform output -raw eks_cluster_name)" --region "$(terraform output -raw aws_region)"
kubectl get nodes
kubectl get pods -A
```

## 2. Create two GitHub repositories
Create empty `qsr-app` and `qsr-gitops` repositories. Copy the contents of the matching directories from this archive into each repository separately. For each:
```bash
git init
git add .
git commit -m "Initial QSR project"
git branch -M main
git remote add origin https://github.com/OWNER/REPO.git
git push -u origin main
```

## 3. Configure GitHub Actions in qsr-app
Settings → Secrets and variables → Actions.

Secrets:
- `AWS_ROLE_TO_ASSUME`: Terraform output `github_actions_role_arn`.
- `GITOPS_TOKEN`: fine-grained token with Contents read/write only for `qsr-gitops` (a GitHub App token is preferable for mature setups).

Variables:
- `AWS_REGION`: Terraform output `aws_region`.
- `AWS_ACCOUNT_ID`: Terraform output `account_id`.
- `ECR_REPOSITORY`: `qsr-orders-api`.
- `GITOPS_REPOSITORY`: `OWNER/qsr-gitops`, without URL.

Terraform's OIDC trust restricts role assumption to the configured app repository and branch. If they change, update Terraform and apply again.

## 4. Bootstrap image and GitOps values
The first Argo CD sync needs an image tag that exists in ECR. Push the app repository to `main` and wait for a successful pipeline. Copy the ECR URI and commit SHA into `qsr-gitops/helm/qsr-orders/values-prod.yaml`:
```yaml
image:
  repository: ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/qsr-orders-api
  tag: "FULL_COMMIT_SHA"
  pullPolicy: IfNotPresent
```
Commit and push. Subsequent successful main builds update these fields automatically.

## 5. Configure Argo CD
Edit `qsr-gitops/argocd/qsr-prod.yaml` and replace `ORG` in the Git URL. For a private GitOps repo, configure its credentials in Argo CD first. Apply from the GitOps repository:
```bash
kubectl apply -f argocd/qsr-prod.yaml
```
Argo CD watches `helm/qsr-orders`, reads `values.yaml` and `values-prod.yaml`, renders the Helm chart, and syncs it into namespace `qsr`. Automated prune and self-heal are enabled; review these settings for your environment.

## 6. Verify the pipeline and deployment
Push a change to `qsr-app/main`. The workflow runs tests, lint/security/dependency checks, Trivy filesystem and image scans, pushes a SHA-tagged image to ECR, and updates the GitOps Helm values. Verify:
```bash
kubectl -n qsr get deploy,pods,svc
kubectl -n qsr rollout status deployment/qsr-orders-qsr-orders
kubectl -n qsr logs deployment/qsr-orders-qsr-orders --tail=100
kubectl -n qsr port-forward svc/qsr-orders-qsr-orders 8080:80
```
Helm-generated resource names may differ if the release name changes; check `kubectl -n qsr get deploy,svc`.

In another terminal:
```bash
curl -s http://localhost:8080/health
curl -s http://localhost:8080/ready
curl -s http://localhost:8080/
curl -s http://localhost:8080/metrics | head
curl -s -X POST http://localhost:8080/orders -H 'Content-Type: application/json' -d '{"item":"Veg Burger","quantity":2,"store_id":"store-101"}'
```

## 7. Metrics and Grafana
Terraform installs `kube-prometheus-stack` in `monitoring`. Port-forward:
```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
```
Open `http://localhost:3000`; retrieve credentials from the chart's current documentation/cluster secret process, never commit them. Useful PromQL:
```promql
rate(qsr_http_requests_total[5m])
```
```promql
histogram_quantile(0.95, sum by (le) (rate(qsr_http_request_duration_seconds_bucket[5m])))
```
```promql
sum(rate(qsr_orders_created_total[5m]))
```
Check Prometheus Targets if metrics are absent. The ServiceMonitor label defaults to `release: kube-prometheus-stack`.

## 8. Logs
The app emits JSON logs to stdout/stderr. The Terraform bundle enables the EKS CloudWatch Observability add-on; verify actual log collection and log groups in CloudWatch and set retention/cost controls. Loki requires a log collector such as Grafana Alloy plus a configured Loki backend. Never log secrets, payment-card data, or customer PII.

## 9. Cleanup
```bash
cd terraform
terraform destroy
```
Review the destroy plan. Export logs/data first. Terraform does not delete GitHub repositories or GitHub tokens.
