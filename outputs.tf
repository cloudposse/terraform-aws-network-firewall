output "id" {
  description = "Network Firewall ID"
  value       = one(aws_networkfirewall_firewall.default.*.id)
}

output "arn" {
  description = "Network Firewall ARN"
  value       = one(aws_networkfirewall_firewall.default.*.arn)
}

output "update_token" {
  description = "A string token used when updating the firewall"
  value       = one(aws_networkfirewall_firewall.default.*.update_token)
}

output "firewall_status" {
  description = "Nested list of information about the current status of the firewall"
  value       = one(aws_networkfirewall_firewall.default.*.firewall_status)
}
