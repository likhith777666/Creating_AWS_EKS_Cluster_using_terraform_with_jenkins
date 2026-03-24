resource "aws_eks_cluster" "eks" {
  count = var.is_eks_cluster_enabled ? 1 : 0
  name = "eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role[0].arn
  vpc_config {
    subnet_ids = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id, aws_subnet.private_subnet[2].id]
    endpoint_private_access = true
    endpoint_public_access = false
    security_group_ids = [aws_security_group.aws_sg.id]
  }

  
access_config {
  authentication_mode      = "CONFIG_MAP"
  bootstrap_cluster_creator_admin_permissions = true
  
}
 tags = {
   Name = "eks-cluster"
   Env = "dev"
 }
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list = [ "sts.amazonaws.com" ]
  thumbprint_list = [data.tls_certificate.eks_certificate.certificates[0].sha1_fingerprint]
  url = data.tls_certificate.eks_certificate.url
}

resource "aws_eks_addon" "eks-addon" {

  for_each = { for idx, addon in var.addons : idx => addon }

  cluster_name = aws_eks_cluster.eks[0].name
  addon_name   = each.value.name

  
  # addon_version = each.value.version

  depends_on = [
    aws_eks_node_group.ondemandnode,
    aws_eks_node_group.spot_node
  ]
}

resource "aws_eks_node_group" "ondemandnode" {
  cluster_name = aws_eks_cluster.eks[0].name
  node_group_name = "eks-cluster-ondemand-node-group"
  node_role_arn = aws_iam_role.eks_workernode_role[0].arn

  subnet_ids = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id, aws_subnet.private_subnet[2].id]
  scaling_config {
    desired_size = 2
    min_size = 1
    max_size = 3
  }
  instance_types = ["t3.medium"]
  capacity_type = "ON_DEMAND"
  update_config {
    max_unavailable = 1
  }

  tags = {
    Name = "eks-cluster-ondemand-nodes"
  }

  tags_all = {
    "kubernetes.io/cluster/eks-cluster" = "owned"
    Name = "eks-cluster-ondemand-nodes"
  }
  depends_on = [ aws_eks_cluster.eks ]
}

resource "aws_eks_node_group" "spot_node" {

  cluster_name = aws_eks_cluster.eks[0].name
  node_group_name = "eks-cluster-spot-node-group"
  node_role_arn = aws_iam_role.eks_workernode_role[0].arn

  subnet_ids = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id, aws_subnet.private_subnet[2].id]
  scaling_config {
    desired_size = 2
    min_size = 1
    max_size = 3
  }
  instance_types = ["c5a.large", "c5a.xlarge", "m5a.large", "m5a.xlarge", "c5.large", "m5.large", "t3a.large", "t3a.xlarge", "t3a.medium"]
  capacity_type = "SPOT"
  update_config {
    max_unavailable = 1
  }
  
  tags = {
    Name = "eks-cluster-spot-node"
  }

  tags_all = {
    "kubernetes.io/cluster/eks-cluster" = "owned"
    Name = "eks-cluster-spot-node"
  }

  labels = {
    type  = "spot"
    lifecycle = "spot"
  }
disk_size = 50
depends_on = [ aws_eks_cluster.eks ]

}

