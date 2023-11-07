locals {
  name = "eks-dev"
  common_tags = {
    env = "dev"
  }
}

data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
  /* depends_on = [
    module.eks.eks_managed_node_groups,
  ] */
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
  /* depends_on = [
    module.eks.eks_managed_node_groups,
  ] */
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  token                  = data.aws_eks_cluster_auth.this.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority.0.data)
}