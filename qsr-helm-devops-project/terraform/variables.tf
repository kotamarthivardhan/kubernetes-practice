variable "aws_region" {
  description = "AWS region for all regional resources."
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  type        = string
  default     = "qsr"
}

variable "environment" {
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}

variable "cluster_version" {
  description = "EKS Kubernetes version supported in your region when you apply."
  type        = string
  default     = "1.34"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.large"]
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "admin_cidr_blocks" {
  description = "Your public IP/CIDR allowed to reach the EKS public Kubernetes API, e.g. [\"203.0.113.10/32\"]. Do not use 0.0.0.0/0."
  type        = list(string)
  nullable    = false
}

variable "github_org" {
  description = "GitHub owner/org containing the app repository."
  type        = string
}

variable "github_app_repo" {
  description = "Application repository name, e.g. qsr-app."
  type        = string
  default     = "qsr-app"
}

variable "github_branch" {
  description = "Branch allowed to assume the GitHub Actions AWS role."
  type        = string
  default     = "main"
}

variable "ecr_repository_name" {
  type    = string
  default = "qsr-orders-api"
}

variable "create_github_oidc_provider" {
  description = "Set false only if the GitHub OIDC provider already exists in this AWS account."
  type        = bool
  default     = true
}

variable "install_argocd" {
  type    = bool
  default = true
}

variable "install_observability" {
  description = "Install kube-prometheus-stack; app metrics are scraped from the ServiceMonitor."
  type        = bool
  default     = true
}
