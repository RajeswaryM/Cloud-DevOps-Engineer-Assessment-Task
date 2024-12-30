locals {

}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name                  = var.name
  cidr                  = var.cidr
  secondary_cidr_blocks = var.secondary_cidr_blocks
  azs                   = length(var.azs) == 0 ? data.aws_availability_zones.availability_zones.names : var.azs

  # Feature flags
  manage_default_route_table = var.manage_default_route_table
  manage_default_network_acl = var.manage_default_network_acl
  enable_dns_hostnames       = var.enable_dns_hostnames
  enable_dns_support         = var.enable_dns_support

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway

  # Subnets
  private_subnets = var.private_subnets
  intra_subnets   = var.intra_subnets
  public_subnets  = var.public_subnets

  # Tags
  default_route_table_tags = merge(var.default_route_table_tags, var.tags)
  private_route_table_tags = merge(var.private_route_table_tags, var.tags, { "Tier" = "private" })
  intra_route_table_tags   = merge(var.intra_route_table_tags, var.tags, { "Tier" = "intra" })
  public_route_table_tags  = merge(var.public_route_table_tags, var.tags, { "Tier" = "public" })
  private_subnet_tags      = merge(var.private_subnet_tags, var.tags, { "Tier" = "private" })
  intra_subnet_tags        = merge(var.intra_subnet_tags, var.tags, { "Tier" = "intra" })
  public_subnet_tags       = merge(var.public_subnet_tags, var.tags, { "Tier" = "public" })

  # Network ACLs, default ACL denies all traffic
  private_dedicated_network_acl = var.private_dedicated_network_acl
  intra_dedicated_network_acl   = var.intra_dedicated_network_acl
  public_dedicated_network_acl  = var.public_dedicated_network_acl
  default_network_acl_name      = var.default_network_acl_name
  default_network_acl_ingress   = var.default_network_acl_ingress
  default_network_acl_egress    = var.default_network_acl_egress

  # Default security group - ingress/egress rules cleared to deny all
  manage_default_security_group  = var.manage_default_security_group
  default_security_group_ingress = var.default_security_group_ingress
  default_security_group_egress  = var.default_security_group_egress
  # DHCP options
  enable_dhcp_options              = var.enable_dhcp_options
  dhcp_options_domain_name         = var.dhcp_options_domain_name
  dhcp_options_domain_name_servers = var.dhcp_options_domain_name_servers

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                      = var.enable_flow_log
  create_flow_log_cloudwatch_log_group = var.create_flow_log_cloudwatch_log_group
  create_flow_log_cloudwatch_iam_role  = var.create_flow_log_cloudwatch_iam_role
  flow_log_max_aggregation_interval    = var.flow_log_max_aggregation_interval

  tags = var.tags


}

#########################################################
# VPC Endpoint Security Block
#########################################################
resource "aws_security_group" "vpc_endpoints" {
  count = var.create_vpc_endpoints ? 1 : 0

  name_prefix = var.environment
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = tolist([module.vpc.vpc_cidr_block])
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      "Name" = "${var.environment}-vpc-endpoints-sg"
    },
  )
}



#########################################################
# VPC Endpoints Module Block
#########################################################
module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "3.14.2"

  count = var.create_vpc_endpoints ? 1 : 0

  vpc_id             = module.vpc.vpc_id
  security_group_ids = aws_security_group.vpc_endpoints[*].id

  endpoints = {
    dynamodb = {
      service      = "dynamodb"
      service_type = "Gateway"
      route_table_ids = flatten([
        module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids
      ])
      tags = merge({ Name = join("-", [var.name, "dynamodb", var.environment]) },
      var.tags)
    },
    s3 = {
      service      = "s3"
      service_type = "Gateway"
      route_table_ids = flatten([
        module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids
      ])
      tags = merge({ Name = join("-", [var.name, "s3", var.environment]) },
      var.tags)
    },
#    ec2 = {
#      service             = "ec2"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.intra_subnets
#      tags = merge({ Name = join("-", [var.name, "ec2", var.environment]) },
#      var.tags)
#    },
#    ec2messages = {
#      service             = "ec2messages"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.intra_subnets
#      tags = merge({ Name = join("-", [var.name, "ec2messages", var.environment]) },
#      var.tags)
#    },
#    kms = {
#      service             = "kms"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.intra_subnets
#      tags = merge({ Name = join("-", [var.name, "kms", var.environment]) },
#      var.tags)
#    },
#    s3 = {
#      service = "s3"
#      tags = merge({ Name = join("-", [var.name, "s3", var.environment]) },
#      var.tags)
#    },
#    ssm = {
#      service             = "ssm"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.intra_subnets
#      tags = merge({ Name = join("-", [var.name, "ssm", var.environment]) },
#      var.tags)
#    },
#    ssmmessages = {
#      service             = "ssmmessages"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.intra_subnets
#      tags = merge({ Name = join("-", [var.name, "ssmmessages", var.environment]) },
#      var.tags)
#    },
#    ecr_api = {
#      service             = "ecr.api"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.intra_subnets
#      policy              = data.aws_iam_policy_document.generic_ecr_endpoint_policy.json
#      tags = merge({ Name = join("-", [var.name, "ecr_api", var.environment]) },
#      var.tags)
#    },
#    ecr_dkr = {
#      service             = "ecr.dkr"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.intra_subnets
#      policy              = data.aws_iam_policy_document.generic_ecr_endpoint_policy.json
#      tags = merge({ Name = join("-", [var.name, "ecr_dkr", var.environment]) },
#      var.tags)
#    },

#    sts = {
#      service             = "sts"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.intra_subnets
#      policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
#      tags = merge({ Name = join("-", [var.name, "sts", var.environment]) },
#      var.tags)
#    },
#
#    sagemaker_api = {
#      service             = "sagemaker.api"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.intra_subnets
#      policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
#      tags = merge({ Name = join("-", [var.name, "sagemaker", var.environment]) },
#      var.tags)
#    }
#
#    sagemaker_runtime = {
#      service             = "sagemaker.runtime"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.intra_subnets
#      policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
#      tags = merge({ Name = join("-", [var.name, "sagemaker-runtime", var.environment]) },
#      var.tags)
#    }

  }

  tags = merge({
    Endpoint = "true"
  }, var.tags)
}