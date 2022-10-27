variable "region" {
  type        = string
  description = "AWS region"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

variable "network_firewall_name" {
  type        = string
  description = "AWS Network Firewall name. If not provided, the name will be derived from the context"
  default     = null
}

variable "network_firewall_description" {
  type        = string
  description = "AWS Network Firewall description. If not provided, the Network Firewall name will be used"
  default     = null
}

variable "network_firewall_policy_name" {
  type        = string
  description = "AWS Network Firewall policy name. If not provided, the name will be derived from the context"
  default     = null
}

variable "policy_stateful_engine_options_rule_order" {
  type        = string
  description = "Indicates how to manage the order of stateful rule evaluation for the policy. Valid values: DEFAULT_ACTION_ORDER, STRICT_ORDER"
  default     = "STRICT_ORDER"
}

variable "stateful_default_actions" {
  type        = list(string)
  description = "Default stateful actions"
  default     = ["aws:alert_strict"]
}

variable "stateless_default_actions" {
  type        = list(string)
  description = "Default stateless actions"
  default     = ["aws:forward_to_sfe"]
}

variable "stateless_fragment_default_actions" {
  type        = list(string)
  description = "Default stateless actions for fragmented packets"
  default     = ["aws:forward_to_sfe"]
}

variable "stateless_custom_actions" {
  type = list(object({
    action_name = string
    dimensions  = list(string)
  }))
  description = "Set of configuration blocks describing the custom action definitions that are available for use in the firewall policy's `stateless_default_actions`"
  default     = []
}

variable "delete_protection" {
  type        = bool
  description = "A boolean flag indicating whether it is possible to delete the firewall"
  default     = false
}

variable "firewall_policy_change_protection" {
  type        = bool
  description = "A boolean flag indicating whether it is possible to change the associated firewall policy"
  default     = false
}

variable "subnet_change_protection" {
  type        = bool
  description = "A boolean flag indicating whether it is possible to change the associated subnet(s)"
  default     = false
}
