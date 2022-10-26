output "vpc_cidr" {
  value       = module.vpc.vpc_cidr_block
  description = "VPC ID"
}

output "public_subnet_cidrs" {
  value       = module.subnets.public_subnet_cidrs
  description = "Public subnet CIDRs"
}

output "private_subnet_cidrs" {
  value       = module.subnets.private_subnet_cidrs
  description = "Private subnet CIDRs"
}

output "network_firewall_id" {
  description = "Network Firewall ID"
  value       = module.network_firewall.network_firewall_id
}

output "network_firewall_arn" {
  description = "Network Firewall ARN"
  value       = module.network_firewall.network_firewall_arn
}

output "network_firewall_update_token" {
  description = "A string token used when updating the Network Firewall"
  value       = module.network_firewall.network_firewall_update_token
}

output "network_firewall_status" {
  description = "Nested list of information about the current status of the Network Firewall"
  value       = module.network_firewall.network_firewall_status
}

output "network_firewall_policy_id" {
  description = "Network Firewall policy ID"
  value       = module.network_firewall.network_firewall_policy_id
}

output "network_firewall_policy_arn" {
  description = "Network Firewall policy ARN"
  value       = module.network_firewall.network_firewall_policy_arn
}

output "network_firewall_rule_group_ids" {
  description = "Network Firewall rule group IDs"
  value       = module.network_firewall.network_firewall_rule_group_ids
}

output "network_firewall_rule_group_arns" {
  description = "Network Firewall rule group ARNa"
  value       = module.network_firewall.network_firewall_rule_group_arns
}
