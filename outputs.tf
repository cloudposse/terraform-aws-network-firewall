output "network_firewall_name" {
  description = "Network Firewall ID"
  value       = one(aws_networkfirewall_firewall.default[*].name)
}

output "network_firewall_arn" {
  description = "Network Firewall ARN"
  value       = one(aws_networkfirewall_firewall.default[*].arn)
}

output "network_firewall_update_token" {
  description = "A string token used when updating the Network Firewall"
  value       = one(aws_networkfirewall_firewall.default[*].update_token)
}

output "network_firewall_status" {
  description = "Nested list of information about the current status of the Network Firewall"
  value       = one(aws_networkfirewall_firewall.default[*].firewall_status)
}

output "network_firewall_policy_name" {
  description = "Network Firewall policy ID"
  value       = one(aws_networkfirewall_firewall_policy.default[*].name)
}

output "network_firewall_policy_arn" {
  description = "Network Firewall policy ARN"
  value       = one(aws_networkfirewall_firewall_policy.default[*].arn)
}

output "az_subnet_endpoint_stats" {
  description = "List of objects with each object having three items: AZ, subnet ID, firewall VPC endpoint ID. Only applicable in VPC mode"
  value       = local.az_subnet_endpoint_stats
}

output "transit_gateway_attachment_id" {
  description = "The unique identifier of the transit gateway attachment. Only applicable in Transit Gateway mode"
  value       = local.enabled && local.is_tgw_mode ? try(one(aws_networkfirewall_firewall.default[*].firewall_status[0].transit_gateway_attachment_sync_states[0].attachment_id), null) : null
}

output "transit_gateway_owner_account_id" {
  description = "The AWS account ID that owns the transit gateway. Only applicable in Transit Gateway mode"
  value       = local.enabled && local.is_tgw_mode ? try(one(aws_networkfirewall_firewall.default[*].transit_gateway_owner_account_id), null) : null
}
