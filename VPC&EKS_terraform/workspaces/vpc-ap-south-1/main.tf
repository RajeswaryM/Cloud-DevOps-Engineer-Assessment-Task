
locals {

  tags = var.tags
}


################################################################################
# EKS Module
################################################################################

module "sdx_eks_cluster" {
  source = "../../modules/eks_cluster"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_enabled_log_types       = var.cluster_enabled_log_types
  create_cluster_security_group   = var.create_cluster_security_group
  create_node_security_group      = var.create_node_security_group
  node_security_group_id          = var.node_security_group_id

  vpc_id                    = var.vpc_id
  eks_control_plane_subnets = data.aws_subnets.infra_subnets.ids

  create_iam_role                        = var.create_iam_role
  iam_role_arn                           = var.iam_role_arn
  iam_role_name                          = var.iam_role_name
  iam_role_use_name_prefix               = false
  cluster_security_group_use_name_prefix = false
  iam_role_additional_policies           = var.iam_role_additional_policies

  eks_managed_node_group_defaults = var.eks_managed_node_group_defaults

  cluster_additional_security_group_ids = var.cluster_additional_security_group_ids
  node_security_group_additional_rules  = var.node_security_group_additional_rules

  eks_managed_node_groups = {
    for node_group in var.eks_managed_node_groups :
    node_group["name"] => {
      name                       = node_group["name"]
      use_name_prefix            = node_group["use_name_prefix"]
      subnet_ids                 = try(node_group["subnet_ids"], data.aws_subnets.private_subnets.ids)
      min_size                   = try(node_group["min_size"], 1)
      max_size                   = try(node_group["max_size"], 1)
      desired_size               = try(node_group["desired_size"], 1)
      ami_id                     = try(node_group["ami_id"], data.aws_ami.eks_default.image_id)
      enable_bootstrap_user_data = try(node_group["enable_bootstrap_user_data"], false)
      pre_bootstrap_user_data    = try(node_group["pre_bootstrap_user_data"], "")

      capacity_type         = try(node_group["capacity_type"], "SPOT")
      disk_size             = try(node_group["disk_size"], 50)
      block_device_mappings = try(node_group["block_device_mappings"], {})
      instance_types        = node_group["instance_types"]
      labels                = try(node_group["labels"], {})
      taints                = try(node_group["taints"], {})
      create_iam_role       = true
      tags                  = try(node_group["tags"], {})
    }

  }
  tags = var.tags

}