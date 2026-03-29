
resource "random_integer" "random_suffix" {
  min = 1000
  max = 9999
}

resource "aws_iam_role" "eks_cluster_role" {

   count = var.is_eks_cluster_enabled ? 1 : 0
   name = "${local.cluster_name}-eks-cluster-role-${random_integer.random_suffix.result}"
   assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Principal = {
                Service = "eks.amazonaws.com"
            }
            Action = "sts:AssumeRole"
        }
    ]
   })
}

resource "aws_iam_role_policy_attachment" "AmazonEksClusterPolicy" {
     #count = var. is_eks_cluster_role_enabled ? 1 : 0
     count = var.is_eks_cluster_enabled ? 1 : 0
     policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
     role = aws_iam_role.eks_cluster_role[0].name
}

resource "aws_iam_role" "eks_workernode_role" {
   count = var.is_eks_nodegroup_role_enabled ? 1 : 0
   name = "${local.cluster_name}-eks-workernode-role-${random_integer.random_suffix.result}"

  assume_role_policy =jsonencode({

    Version = "2012-10-17"
    Statement = [

     {

       Effect = "Allow"
       Principal = {
      Service = "ec2.amazonaws.com"
     }
      Action = "sts:AssumeRole"
     }] 
  })
}

resource "aws_iam_role_policy_attachment" "AmazonWorkerNodePolicy" {

    count = var.is_eks_nodegroup_role_enabled ? 1 : 0
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role = aws_iam_role.eks_workernode_role[0].name
}

resource "aws_iam_role_policy_attachment" "amazonEKS_CNI_Policy" {

  count = var.is_eks_nodegroup_role_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.eks_workernode_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks_AmazonEC2ContainerRegistryReadOnly" {
    
    count = var.is_eks_nodegroup_role_enabled ? 1 : 0
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role = aws_iam_role.eks_workernode_role[0].name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEBSCSDriverPolicy" {
  
  count = var.is_eks_nodegroup_role_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role = aws_iam_role.eks_workernode_role[0].name
}

resource "aws_iam_role" "eks_oids" {
    assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role_policy.json
    name = "eks_oidc_role"
}

resource "aws_iam_policy" "eks_oidc_policy" {
    name = "eks_oidc_policy"
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Effect = "Allow"
                Action = [
                    "s3:ListALLMyBuckets",
                    "s3:GetBucketLocation",
                    "*"
                ]
                Effect = "Allow"
                Resource = "*"
            }
        ]
    })
}

resource "aws_iam_role_policy_attachment" "eks_oidc_policy_attachment" {
    policy_arn = aws_iam_policy.eks_oidc_policy.arn
    role = aws_iam_role.eks_oids.name
}


resource "aws_iam_role" "alb_controller" {
  name = "eks-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = aws_iam_openid_connect_provider.eks_oidc.arn
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks_oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = "arn:aws:iam::982534381361:policy/AWSLoadBalancerControllerIAMPolicy"
}
