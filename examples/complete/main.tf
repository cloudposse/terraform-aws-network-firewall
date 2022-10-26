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
  attributes    = ["logs"]

  context = module.this.context
}

module "network_firewall" {
  source = "../../"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.subnets.private_subnet_ids

  logging_config = {
    log_destination_type = "S3"
    log_type             = "FLOW"
    log_destination = {
      bucketName = module.s3_log_storage.bucket_id
      prefix     = "/network-firewall-logs"
    }
  }

  rule_group_config = {}

  context = module.this.context
}
