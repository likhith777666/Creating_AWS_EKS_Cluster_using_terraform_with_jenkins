EKS Cluster is created using terraform
# To create an Production level EKS cluster we need vpc , iam role's , policy permissions, eks cluster, node groupds, internet gatways, security groups and nat gatway this are the main things we need to create an EKS Cluster

1. **VPC set up**
   - Created VPC with cidr block
   - Public and Private subnets across multiple AZs
2. **Networking**
   - Internet Gateway for public subnets
   - NAT Gateway for private subnets
   - Route tables configured for internet access

3. **IAM Roles**
   - EKS Cluster Role
   - Node Group Role
   - OIDC-based IAM roles for Kubernetes service accounts

4. **EKS Cluster**
   - Private endpoint enabled
   - Secure communication within VPC

5. **Node Groups**
   - On-Demand nodes for stability
   - Spot nodes for cost optimization

6. **Addons**
   - CoreDNS
   - kube-proxy
   - VPC CNI plugin




## 🔹 Key Features

- High availability using multiple AZs
- Secure private networking
- Cost optimization using Spot instances
- Scalable Kubernetes cluster

  sh ```
  cd eks
  ```

