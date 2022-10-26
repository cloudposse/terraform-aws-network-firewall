output "network_firewall_id" {
  description = "Network Firewall ID"
  value       = one(aws_networkfirewall_firewall.default.*.id)
}

output "network_firewall_arn" {
  description = "Network Firewall ARN"
  value       = one(aws_networkfirewall_firewall.default.*.arn)
}

output "network_firewall_update_token" {
  description = "A string token used when updating the Network Firewall"
  value       = one(aws_networkfirewall_firewall.default.*.update_token)
}

output "network_firewall_status" {
  description = "Nested list of information about the current status of the Network Firewall"
  value       = one(aws_networkfirewall_firewall.default.*.firewall_status)
}

output "network_firewall_policy_id" {
  description = "Network Firewall policy ID"
  value       = one(aws_networkfirewall_firewall_policy.default.*.id)
}

output "network_firewall_policy_arn" {
  description = "Network Firewall policy ARN"
  value       = one(aws_networkfirewall_firewall_policy.default.*.arn)
}

output "network_firewall_rule_group_ids" {
  description = "Network Firewall rule group IDs"
  value       = aws_networkfirewall_rule_group.default.*.id
}

output "network_firewall_rule_group_arns" {
  description = "Network Firewall rule group ARNa"
  value       = aws_networkfirewall_rule_group.default.*.arn
}
