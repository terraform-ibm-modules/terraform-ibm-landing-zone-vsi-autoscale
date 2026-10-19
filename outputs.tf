########################################################################################################################
# Outputs
########################################################################################################################

output "instance_template" {
  description = "Instance template information"
  value       = ibm_is_instance_template.instance_template
}

output "ibm_is_instance_group" {
  description = "Instance group information"
  value       = var.ignore_instance_count_changes ? ibm_is_instance_group.instance_group_with_unmanaged_instance_count[0] : ibm_is_instance_group.instance_group_with_managed_instance_count[0]
}

output "lbs_list" {
  description = "Load balancer information"
  value       = values(ibm_is_lb.lb)
}

output "security_groups" {
  description = "Security group information"
  value       = module.security_groups
}

# Keyed by manager name → manager_id is the key computed attribute.
output "instance_group_managers" {
  description = "Map of instance group manager IDs keyed by manager name."
  value = {
    for k, v in ibm_is_instance_group_manager.instance_group_manager : k => {
      manager_id           = v.manager_id
      manager_type         = v.manager_type
      aggregation_window   = v.aggregation_window
      cooldown             = v.cooldown
      min_membership_count = v.min_membership_count
      max_membership_count = v.max_membership_count
      enable_manager       = v.enable_manager
    }
  }
}

# Keyed by policy name → policy_id is the key computed attribute.
output "instance_group_manager_policies" {
  description = "Map of instance group manager policy IDs keyed by policy name."
  value = {
    for k, v in ibm_is_instance_group_manager_policy.instance_group_manager_policies : k => {
      policy_id              = v.policy_id
      instance_group_manager = v.instance_group_manager
      metric_type            = v.metric_type
      metric_value           = v.metric_value
      policy_type            = v.policy_type
    }
  }
}

# Keyed by action name → action_id is the key computed attribute.
# Only populated when scheduled managers with actions are configured.
output "instance_group_manager_actions" {
  description = "Map of instance group manager action IDs keyed by action name."
  value = {
    for k, v in ibm_is_instance_group_manager_action.instance_group_manager_actions : k => {
      action_id   = v.action_id
      action_type = v.action_type
      cron_spec   = v.cron_spec
      status      = v.status
      next_run_at = v.next_run_at
    }
  }
}
