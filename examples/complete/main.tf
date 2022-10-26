provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "1.2.0"

  ipv4_primary_cidr_block = "172.19.0.0/16"

  context = module.this.context
}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "2.0.4"

  availability_zones   = var.availability_zones
  vpc_id               = module.vpc.vpc_id
  igw_id               = [module.vpc.igw_id]
  ipv4_cidr_block      = [module.vpc.vpc_cidr_block]
  nat_gateway_enabled  = false
  nat_instance_enabled = false

  context = module.this.context
}

module "s3_log_storage" {
  source  = "cloudposse/s3-log-storage/aws"
  version = "1.0.0"

  force_destroy = true
  attributes    = ["logs"]

  context = module.this.context
}

module "network_firewall" {
  source = "../../"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.subnets.private_subnet_ids

  network_firewall_name                     = var.network_firewall_name
  network_firewall_description              = var.network_firewall_description
  network_firewall_policy_name              = var.network_firewall_policy_name
  policy_stateful_engine_options_rule_order = var.policy_stateful_engine_options_rule_order
  stateful_default_actions                  = var.stateful_default_actions
  stateless_default_actions                 = var.stateless_default_actions
  stateless_fragment_default_actions        = var.stateless_fragment_default_actions
  stateless_custom_actions                  = var.stateless_custom_actions
  delete_protection                         = var.delete_protection
  firewall_policy_change_protection         = var.firewall_policy_change_protection
  subnet_change_protection                  = var.subnet_change_protection

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_logging_configuration
  logging_config = [
    {
      log_destination_type = "S3"
      log_type             = "FLOW"
      log_destination = {
        bucketName = module.s3_log_storage.bucket_id
        prefix     = "/network-firewall-logs"
      }
    }
  ]

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group
  rule_group_config = {
    stateful-inspection-for-blocking-packets-from-going-to-destination = {
      capacity    = 50
      name        = "block-packets-from-going-to-destination"
      description = "Stateful Inspection for blocking packets from going to an intended destination"
      type        = "STATEFUL"
      rule_group = {
        stateful_rule_options = {
          rule_order = "STRICT_ORDER"
        }
        rules_source = {
          stateful_rule = [
            {
              action = "DROP"
              header = {
                destination      = "124.1.1.24/32"
                destination_port = 53
                direction        = "ANY"
                protocol         = "TCP"
                source           = "1.2.3.4/32"
                source_port      = 53
              }
              rule_option = {
                keyword = "sid:1"
              }
            }
          ]
        }
      }
    }
  }

  context = module.this.context
}
