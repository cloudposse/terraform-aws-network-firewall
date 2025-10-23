terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      # The `transit_gateway_id` parameter has been released in AWS provider version 6.5.0 (released July 24, 2025).
      # https://github.com/hashicorp/terraform-provider-aws/blob/v6.5.0/CHANGELOG.md
      version = ">= 6.5.0"
    }
  }
}
