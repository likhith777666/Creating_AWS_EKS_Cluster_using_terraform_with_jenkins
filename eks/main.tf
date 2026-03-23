locals {
  org = "ap-medium"
  env = "dev"
}

module "eks" {
  source = "../module"

  cluster_name = var.cluster_name
  is_eks_cluster_enabled         = true
  is_eks_role_enabled            = true
  is_eks_nodegroup_role_enabled  = true

  addons = var.addons
}

