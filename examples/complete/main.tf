provider "aws" {
  region = var.region
}

module "vpc" {
  source  = "cloudposse/vpc/aws"
  version = "1.1.0"

  ipv4_primary_cidr_block = "172.19.0.0/16"

  context = module.this.context
}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "2.0.2"

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
  attributes    = ["network", "firewall", "logs"]

  context = module.this.context
}

module "network_firewall" {
  source = "../../"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.subnets.private_subnet_ids

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_logging_configuration
  logging_config = {
    log_destination_type = "S3"
    log_type             = "FLOW"
    log_destination = {
      bucketName = module.s3_log_storage.bucket_id
      prefix     = "/network-firewall-logs"
    }
  }

  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group
  rule_group_config = {
    stateful-inspection-for-denying-access-to-domain = {
      capacity    = 100
      name        = "Deny access to a domain"
      description = "This rule group denies access to test.example.com"
      type        = "STATEFUL"
      rule_group = {
        rules_source = {
          rules_source_list = {
            generated_rules_type = "DENYLIST"
            target_types         = ["HTTP_HOST"]
            targets              = ["test.example.com"]
          }
        }
      }
    }
    stateful-inspection-for-blocking-packets-from-going-to-destination = {
      capacity    = 50
      name        = "Block packets from going to an intended destination"
      description = "Stateful Inspection for blocking packets from going to an intended destination"
      type        = "STATEFUL"
      rule_group = {
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
