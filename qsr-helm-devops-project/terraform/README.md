# QSR Terraform — AWS infrastructure foundation

Creates VPC, EKS managed nodes, ECR with immutable tags and scan-on-push, GitHub OIDC/IAM for ECR publishing, Argo CD, and Prometheus/Grafana. The app deployment itself is managed by Argo CD from the Helm chart in `qsr-gitops`.

```bash
cp terraform.tfvars.example terraform.tfvars
# Set github_org and admin_cidr_blocks in terraform.tfvars
terraform init
terraform fmt -recursive
terraform validate
terraform plan -out qsr.tfplan
terraform apply qsr.tfplan
```

Confirm that the configured EKS Kubernetes version is supported in your region. Restrict `admin_cidr_blocks` to your public IP `/32`; never expose the EKS API to `0.0.0.0/0`. AWS costs can include EKS, EC2, NAT Gateway, ECR storage, and CloudWatch logs.

After apply, use Terraform outputs to configure GitHub Actions, then update `qsr-gitops/helm/qsr-orders/values-prod.yaml` with the ECR URI and an existing image tag. Replace `ORG` in `qsr-gitops/argocd/qsr-prod.yaml`, configure Argo CD repository credentials if private, and apply the Application.

This is a reference foundation, not a complete enterprise landing zone. Destroy resources when finished with `terraform destroy` after reviewing the plan.
