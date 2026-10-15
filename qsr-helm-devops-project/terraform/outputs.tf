output "aws_region" {
  value = var.aws_region
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_ecr.arn
}

output "argocd_namespace" {
  value       = var.install_argocd ? "argocd" : null
  description = "Argo CD is installed by Helm when install_argocd=true."
}

output "monitoring_namespace" {
  value       = var.install_observability ? "monitoring" : null
  description = "Prometheus/Grafana are installed by Helm when install_observability=true."
}
