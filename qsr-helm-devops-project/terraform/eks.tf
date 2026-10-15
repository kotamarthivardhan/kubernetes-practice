module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name    = "${local.name}-eks"
  cluster_version = var.cluster_version

  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.admin_cidr_blocks
  cluster_endpoint_private_access      = true

  enable_cluster_creator_admin_permissions = true

  authentication_mode = "API"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    qsr_workers = {
      name           = "${local.name}-workers"
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      subnet_ids = module.vpc.private_subnets

      labels = {
        workload = "qsr"
      }

      update_config = {
        max_unavailable_percentage = 33
      }
    }
  }

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    amazon-cloudwatch-observability = {
      most_recent = true
    }
  }

  node_security_group_tags = {
    "kubernetes.io/cluster/${local.name}-eks" = "owned"
  }

  tags = local.common_tags
}
