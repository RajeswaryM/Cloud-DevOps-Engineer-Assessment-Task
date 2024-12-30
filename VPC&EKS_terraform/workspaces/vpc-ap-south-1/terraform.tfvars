aws_region = "ap-south-1"

# VPC

vpc_id = "vpc-0d4bf988e246752be"

# EKS Cluster Values

cluster_name                    = "AWS-eks"
cluster_version                 = "1.30"
cluster_endpoint_private_access = true
cluster_endpoint_public_access  = true

eks_control_plane_subnets = ["subnet-0a8bd8d584a83fe65", "subnet-03133ae5e261b8636", "subnet-0b6d46c0b659717dd"]

create_iam_role = true

create_cluster_security_group = true

iam_role_additional_policies = {
  EKSNodeIAMPolicy                  = "arn:aws:iam::071142024154:policy/EKSNodeIAMPolicy"
  AmazonEC2ContainerRegistryFullAccess = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}


eks_managed_node_group_defaults = {
  ami_type                              = "AL2_x86_64"
  instance_types                        = ["t3a.medium", "t4g.medium"]
  iam_role_attach_cni_policy            = true
  attach_cluster_primary_security_group = true
  iam_role_additional_policies = {
    EKSNodeIAMPolicy                  = "arn:aws:iam::071142024154:policy/EKSNodeIAMPolicy"
    AmazonEC2ContainerRegistryFullAccess = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
  }
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }
  tags = {}

}

eks_managed_node_groups = [
  {
    name                       = "sdx-observability"
    use_name_prefix            = false
    min_size                   = 2
    max_size                   = 2
    desired_size               = 2
    capacity_type              = "SPOT"
    disk_size                  = 20
    instance_types             = ["m6a.xlarge", "t3a.xlarge", "t3a.2xlarge", "r6a.xlarge", "r6a.2xlarge", "m6a.2xlarge"]
    enable_bootstrap_user_data = true
    bootstrap_extra_args       = "--container-runtime containerd"
    pre_bootstrap_user_data    = <<-EOT
      export CONTAINER_RUNTIME="containerd"
      EOT
    post_bootstrap_user_data   = <<-EOT
      echo "you are free little kubelet!"
      EOT
    ebs_optimized              = true
    disable_api_termination    = false
    enable_monitoring          = false
    metadata_options = {
      http_endpoint = "enabled"
      http_tokens   = "optional"

      instance_metadata_tags = "enabled"
    }
    labels = {
      platform = "monitor"
      env      = "prod"
    }
    taints = [
      {
        key    = "platform"
        value  = "monitor"
        effect = "NO_SCHEDULE"
        }, {
        key    = "env"
        value  = "prod"
        effect = "NO_SCHEDULE"
      }
    ]
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 20
          volume_type           = "gp3"
          iops                  = 3000
          throughput            = 150
          encrypted             = true
          delete_on_termination = true
        }
      }
    }
    tags = {
      platform = "monitor"
      env      = "prod"
    }
  },
   

]

aws_auth_roles = [
  {
    rolearn  = "arn:aws:iam::071142024154:user/RajeswaryB"
    username = "RajeswaryB"
    groups   = ["system:masters"]
  },
  {
    rolearn  = "arn:aws:iam::995608168315:role/AWSReservedSSO_SDXEKSAdmins_d5b1e4bb4c7362a2"
    username = "sdx-cluster-admin"
    groups   = ["system:masters"]
  }
]

create_node_security_group = true

tags = {
  customer                                        = "aws"
  owner                                           = "RajeswaryB"
  businessunit                                    = "infra"
  costcenter                                      = "RajeswaryB"
  "kubernetes.io/cluster/recordaize-non-prod-eks" = "shared"
}