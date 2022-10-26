locals {
  enabled                      = module.this.enabled
  network_firewall_name        = var.network_firewall_name != null && var.network_firewall_name != "" ? var.network_firewall_name : module.this.id
  network_firewall_description = var.network_firewall_description != null && var.network_firewall_description != "" ? var.network_firewall_description : local.network_firewall_name
  network_firewall_policy_name = var.network_firewall_policy_name != null && var.network_firewall_policy_name != "" ? var.network_firewall_policy_name : module.this.id
  rule_group_config            = { for k, v in var.rule_group_config : k => v if local.enabled }
  logging_config               = { for k, v in var.logging_config : k => v if local.enabled }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall
resource "aws_networkfirewall_firewall" "default" {
  count = local.enabled ? 1 : 0

  name        = local.network_firewall_name
  description = local.network_firewall_description
  vpc_id      = var.vpc_id

  firewall_policy_arn               = one(aws_networkfirewall_firewall_policy.default.*.arn)
  firewall_policy_change_protection = var.firewall_policy_change_protection
  subnet_change_protection          = var.subnet_change_protection
  delete_protection                 = var.delete_protection

  dynamic "subnet_mapping" {
    for_each = toset(var.subnet_ids)

    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = module.this.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group
resource "aws_networkfirewall_rule_group" "default" {
  for_each = local.rule_group_config

  type        = each.value.type
  name        = each.value.name
  description = lookup(each.value, "description", each.value.name)
  capacity    = each.value.capacity

  # The stateful rule group rules specifications in Suricata file format, with one rule per line
  # Use this to import your existing Suricata compatible rule groups
  rules = lookup(each.value, "suricata_rules_file_path", null) != null ? file(each.value.suricata_rules_file_path) : null

  dynamic "rule_group" {
    for_each = lookup(each.value, "rule_group", null) != null ? [true] : []
    content {
      # `rule_variables` - a configuration block that defines additional settings available to use in the rules defined in the rule group
      # Can only be specified for stateful rule groups
      dynamic "rule_variables" {
        for_each = lookup(each.value.rule_group, "rule_variables", null) != null ? [true] : []
        content {
          # Set of configuration blocks that define IP address information
          dynamic "ip_sets" {
            for_each = lookup(each.value.rule_group.rule_variables, "ip_sets", [])
            content {
              key = ip_sets.value.key
              ip_set {
                definition = ip_sets.value.definition
              }
            }
          }
          # Set of configuration blocks that define port range information
          dynamic "port_sets" {
            for_each = lookup(each.value.rule_group.rule_variables, "port_sets", [])
            content {
              key = port_sets.value.key
              port_set {
                definition = port_sets.value.definition
              }
            }
          }
        }
      }

      # `stateful_rule_options` - a configuration block that defines stateful rule options for the rule group
      # If the STRICT_ORDER rule order is specified, this rule group can only be referenced in firewall policies that also utilize STRICT_ORDER for the stateful engine
      # STRICT_ORDER can only be specified when using a rules_source of rules_string or stateful_rule
      dynamic "stateful_rule_options" {
        for_each = lookup(each.value.rule_group, "stateful_rule_options", null) != null ? [true] : []
        content {
          # Indicates how to manage the order of the rule evaluation for the rule group
          # Default value: DEFAULT_ACTION_ORDER
          # Valid values: DEFAULT_ACTION_ORDER, STRICT_ORDER
          rule_order = each.value.rule_group.stateful_rule_options.rule_order
        }
      }

      # `rules_source` - a configuration block that defines the stateful or stateless rules for the rule group
      # Only one of `rules_source_list`, `rules_string`, `stateful_rule`, or `stateless_rules_and_custom_actions` must be specified
      rules_source {
        rules_string = lookup(each.value.rule_group.rules_source, "rules_string", null)

        dynamic "rules_source_list" {
          for_each = lookup(each.value.rule_group.rules_source, "rules_source_list", null) != null ? [true] : []
          content {
            # String value to specify whether domains in the target list are allowed or denied access. Valid values: ALLOWLIST, DENYLIST
            generated_rules_type = each.value.rule_group.rules_source.rules_source_list.generated_rules_type
            # Set of types of domain specifications that are provided in the targets argument. Valid values: HTTP_HOST, TLS_SNI
            target_types = each.value.rule_group.rules_source.rules_source_list.target_types
            # Set of domains that you want to inspect for in your traffic flows
            targets = each.value.rule_group.rules_source.rules_source_list.targets
          }
        }
        dynamic "stateful_rule" {
          for_each = lookup(each.value.rule_group.rules_source, "stateful_rule", [])
          content {
            # Action to take with packets in a traffic flow when the flow matches the stateful rule criteria
            # For all actions, AWS Network Firewall performs the specified action and discontinues stateful inspection of the traffic flow
            # Valid values: ALERT, DROP or PASS
            action = stateful_rule.value.action
            # A configuration block containing the stateful 5-tuple inspection criteria for the rule, used to inspect traffic flows
            header {
              destination      = stateful_rule.value.header.destination
              destination_port = stateful_rule.value.header.destination_port
              direction        = stateful_rule.value.header.direction
              protocol         = stateful_rule.value.header.protocol
              source           = stateful_rule.value.header.source
              source_port      = stateful_rule.value.header.source_port
            }
            rule_option {
              keyword  = stateful_rule.value.rule_option.keyword
              settings = lookup(stateful_rule.value.rule_option, "settings", null)
            }
          }
        }
        dynamic "stateless_rules_and_custom_actions" {
          for_each = lookup(each.value.rule_group.rules_source, "stateless_rules_and_custom_actions", null) != null ? [true] : []
          content {
            dynamic "custom_action" {
              for_each = lookup(each.value.rule_group.rules_source.stateless_rules_and_custom_actions, "custom_action", null) != null ? [true] : []
              content {
                action_name = each.value.rule_group.rules_source.stateless_rules_and_custom_actions.action_name
                action_definition {
                  publish_metric_action {
                    dynamic "dimension" {
                      for_each = each.value.rule_group.rules_source.stateless_rules_and_custom_actions.dimensions
                      content {
                        value = dimension.value
                      }
                    }
                  }
                }
              }
            }
            stateless_rule {
              priority = each.value.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule.priority
              rule_definition {
                actions = each.value.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule.rule_definition.actions
                match_attributes {
                  protocols = lookup(each.value.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule.rule_definition.match_attributes, "protocols", [])
                  dynamic "destination" {
                    for_each = lookup(each.value.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule.rule_definition.match_attributes, "destination", [])
                    content {
                      address_definition = destination.value
                    }
                  }
                  dynamic "destination_port" {
                    for_each = lookup(each.value.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule.rule_definition.match_attributes, "destination_port", [])
                    content {
                      from_port = destination_port.value.from_port
                      to_port   = lookup(destination_port.value, "to_port", null)
                    }
                  }
                  dynamic "source" {
                    for_each = lookup(each.value.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule.rule_definition.match_attributes, "source", [])
                    content {
                      address_definition = source.value
                    }
                  }
                  dynamic "source_port" {
                    for_each = lookup(each.value.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule.rule_definition.match_attributes, "source_port", [])
                    content {
                      from_port = source_port.value
                      to_port   = lookup(source_port.value, "to_port", null)
                    }
                  }
                  dynamic "tcp_flag" {
                    for_each = lookup(each.value.rule_group.rules_source.stateless_rules_and_custom_actions.stateless_rule.rule_definition.match_attributes, "tcp_flag", [])
                    content {
                      flags = tcp_flag.value.flags
                      masks = lookup(tcp_flag.value, "masks", null)
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  tags = module.this.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_firewall_policy
resource "aws_networkfirewall_firewall_policy" "default" {
  count = local.enabled ? 1 : 0

  name = local.network_firewall_policy_name

  firewall_policy {
    stateful_default_actions           = var.stateful_default_actions
    stateless_default_actions          = var.stateless_default_actions
    stateless_fragment_default_actions = var.stateless_fragment_default_actions

    dynamic "stateless_rule_group_reference" {
      for_each = toset([for k, v in aws_networkfirewall_rule_group.default : v.arn if v.type == "STATELESS"])
      content {
        resource_arn = stateless_rule_group_reference.value
        priority     = index([for k, v in aws_networkfirewall_rule_group.default : v.arn if v.type == "STATELESS"], stateless_rule_group_reference.value) + 1
      }
    }

    dynamic "stateful_rule_group_reference" {
      for_each = toset([for k, v in aws_networkfirewall_rule_group.default : v.arn if v.type == "STATEFUL"])
      content {
        resource_arn = stateful_rule_group_reference.value
        priority     = index([for k, v in aws_networkfirewall_rule_group.default : v.arn if v.type == "STATEFUL"], stateful_rule_group_reference.value) + 1
      }
    }

    dynamic "stateful_engine_options" {
      for_each = var.policy_stateful_engine_options_rule_order != null && var.policy_stateful_engine_options_rule_order != "" ? [true] : []
      content {
        rule_order = var.policy_stateful_engine_options_rule_order
      }
    }

    dynamic "stateless_custom_action" {
      for_each = var.stateless_custom_actions
      content {
        action_name = stateless_custom_action.value.action_name
        action_definition {
          publish_metric_action {
            dynamic "dimension" {
              for_each = stateless_custom_action.value.dimensions
              content {
                value = dimension.value
              }
            }
          }
        }
      }
    }
  }

  tags = module.this.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_logging_configuration
resource "aws_networkfirewall_logging_configuration" "default" {
  for_each = local.logging_config

  firewall_arn = one(aws_networkfirewall_firewall.default.*.arn)

  logging_configuration {
    log_destination_config {
      # The location to send logs to. Valid values: S3, CloudWatchLogs, KinesisDataFirehose
      log_destination_type = each.value.log_destination_type
      # The type of log to send. Valid values: ALERT or FLOW
      # Alert logs report traffic that matches a StatefulRule with an action setting that sends a log message
      # Flow logs are standard network traffic flow logs
      log_type = each.value.log_type
      log_destination = {
        # For log_destination_type = "CloudWatchLogs"
        logGroup = lookup(each.value.log_destination, "logGroup", null)
        # For log_destination_type = "S3"
        bucketName = lookup(each.value.log_destination, "bucketName", null)
        prefix     = lookup(each.value.log_destination, "prefix", null)
        # For log_destination_type = "KinesisDataFirehose"
        deliveryStream = lookup(each.value.log_destination, "deliveryStream", null)
      }
    }
  }
}
