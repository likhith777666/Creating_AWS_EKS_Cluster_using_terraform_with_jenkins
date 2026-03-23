variable "cluster_name" {}

variable "is_eks_cluster_enabled" {
  type = bool
}

variable "is_eks_role_enabled" {
  type = bool
}

variable "is_eks_nodegroup_role_enabled" {
  type = bool
}

variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))
}
