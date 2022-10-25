locals {
  enabled                      = module.this.enabled
  network_firewall_name        = coalesce(var.network_firewall_name, module.this.id)
  network_firewall_description = coalesce(var.network_firewall_description, local.network_firewall_name)
  network_firewall_policy_name = coalesce(var.network_firewall_policy_name, module.this.id)
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
    for_each = toset(var.subnet_mapping)

    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = module.this.tags
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/networkfirewall_rule_group
resource "aws_networkfirewall_rule_group" "default" {
  for_each = local.enabled ? var.rule_group_config : {}

  type        = each.value.type
  name        = each.value.name
  description = lookup(each.value, "description", each.value.name)
  capacity    = each.value.capacity

  rules = lookup(each.value, "suricata_rules_file_path", null) != null ? file(each.value.suricata_rules_file_path) : null

  dynamic "rule_group" {
    for_each = lookup(each.value, "rule_group", null) != null ? [true] : []
    content {
      rules_source {
      }

      dynamic "rule_variables" {
        for_each = ""
        content {}
      }

      dynamic "stateful_rule_options" {
        for_each = ""
        content {
          rule_order = ""
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
      }
    }

    dynamic "stateful_engine_options" {
      for_each = var.stateful_engine_options_rule_order != null && var.stateful_engine_options_rule_order != "" ? [true] : []
      content {
        rule_order = var.stateful_engine_options_rule_order
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
  for_each = local.enabled ? var.logging_config : {}

  firewall_arn = one(aws_networkfirewall_firewall.default.*.arn)

  logging_configuration {
    log_destination_config {
      log_destination = {
        # For log_destination_type = "CloudWatchLogs"
        logGroup = lookup(each.value, "logGroup", null)
        # For log_destination_type = "S3"
        bucketName = lookup(each.value, "bucketName", null)
        prefix     = lookup(each.value, "prefix", null)
        # For log_destination_type = "KinesisDataFirehose"
        deliveryStream = lookup(each.value, "deliveryStream", null)
      }
      # The location to send logs to. Valid values: S3, CloudWatchLogs, KinesisDataFirehose
      log_destination_type = each.value.log_destination_type
      # The type of log to send. Valid values: ALERT or FLOW
      # Alert logs report traffic that matches a StatefulRule with an action setting that sends a log message
      # Flow logs are standard network traffic flow logs
      log_type = each.value.log_type
    }
  }
}
