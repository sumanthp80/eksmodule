module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.16"

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      preserve    = true
      most_recent = true

      timeouts = {
        create = "25m"
        delete = "10m"
      }
    }
    kube-proxy = {
      most_recent = true
    }
    /* aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = var.aws_ebs_csi_iam_role_arn
    } */
    vpc-cni = {
      before_compute = true
      most_recent    = true
      configuration_values = jsonencode({
        env = {
          ENABLE_POD_ENI                    = "true"
          ENABLE_PREFIX_DELEGATION          = "true"
          POD_SECURITY_GROUP_ENFORCING_MODE = "standard"
        }
      })
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  create_cluster_security_group = false
  create_node_security_group    = false

  eks_managed_node_group_defaults = {
    iam_role_additional_policies = {
      one = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
      two = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
    }
  }
  eks_managed_node_groups = {
    default = {
      instance_types       = ["m5.large"]
      force_update_version = true
      release_version      = var.ami_release_version
      cluster_version      = "1.26"
      min_size     = 2
      max_size     = 3
      desired_size = 2

      labels = {
        workshop-default = "yes"
      }
      update_config = {
        max_unavailable_percentage = 50 # or set `max_unavailable`
      }
    }
  }
  #create_aws_auth_configmap = true
  # aws-auth configmap
  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = "arn:aws:iam::58806945359:role/eks-role"
      username = "role1"
      groups   = ["system:masters"]
    },
  ]
  aws_auth_accounts = [
    "58806945359",
  ]
   # aws-auth configmap
  # manage_aws_auth_configmap = true

  /* aws_auth_roles = [
    {
      rolearn  = module.eks_managed_node_group.iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    },

     {
      rolearn  = module.self_managed_node_group.iam_role_arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
      ]
    }, 
    {
      rolearn  = module.fargate_profile.fargate_profile_pod_execution_role_arn
      username = "system:node:{{SessionName}}"
      groups = [
        "system:bootstrappers",
        "system:nodes",
        "system:node-proxier",
      ]
    }  
  ] */
 /*  aws_auth_users = [
    {
      userarn  = "arn:aws:iam::058806945359:user/sumanth"
      username = "user1"
      groups   = ["system:masters"]
    },
    
  ] */
  /* aws_auth_accounts = [
    "777777777777",
    "888888888888",
  ] */

  tags = merge(local.tags, {
    "karpenter.sh/discovery" = var.cluster_name
  })
}