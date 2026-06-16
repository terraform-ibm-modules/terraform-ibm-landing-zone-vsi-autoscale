##############################################################################
# Create Instance Group
##############################################################################
locals {
  # Determine the instance group ID based on which resource was created
  instance_group_id = var.auto_scale ? ibm_is_instance_group.autoscale[0].id : ibm_is_instance_group.static[0].id

  ins_group_mgr_map = {
    for mgr in var.group_managers :
    (mgr.name) => mgr
  }

  inst_group_mgr_action_list = flatten([
    for mgr in var.group_managers :
    [
      for action in flatten([mgr.actions != null ? mgr.actions : []]) : #Check if actions are null
      merge({
        mgr_name = mgr.name
      }, action)
    ]
  ])

  inst_group_mgr_action_map = {
    for action in local.inst_group_mgr_action_list :
    action.name => action
  }

  inst_group_mgr_policy_list = flatten([
    for mgr in var.group_managers :
    [
      for policy in flatten([mgr.policies != null ? mgr.policies : []]) : #Check if actions are null
      merge({
        mgr_name = mgr.name
      }, policy)
    ]
  ])

  inst_group_mgr_policy_map = {
    for policy in local.inst_group_mgr_policy_list :
    policy.name => policy
  }

}

# State migration for existing deployments
# This ensures smooth upgrade from previous versions where the resource was named "instance_group"
moved {
  from = ibm_is_instance_group.instance_group
  to   = ibm_is_instance_group.autoscale[0]
}

resource "time_sleep" "wait_180_seconds" {
  depends_on = [
    ibm_is_instance_group.autoscale,
    ibm_is_instance_group.static
  ]

  destroy_duration = "180s"
}

# Instance group for autoscale scenarios - ignores instance_count changes
resource "ibm_is_instance_group" "autoscale" {
  count              = var.auto_scale ? 1 : 0
  name               = var.instance_group_name != null ? var.instance_group_name : (var.prefix != null ? "${var.prefix}-ins-group" : "ins-group")
  resource_group     = var.resource_group_id
  access_tags        = var.access_tags
  tags               = var.tags
  instance_template  = ibm_is_instance_template.instance_template.id
  instance_count     = var.instance_count
  subnets            = var.subnets[*].id
  application_port   = var.application_port
  load_balancer      = length(var.load_balancers) > 0 ? ibm_is_lb.lb[var.load_balancers[0].name].id : null
  load_balancer_pool = length(var.load_balancers) > 0 ? ibm_is_lb_pool.pool[var.load_balancers[0].name].pool_id : null

  lifecycle {
    ignore_changes = [instance_count]
  }
}

# Instance group for static/manual scaling - tracks instance_count changes
resource "ibm_is_instance_group" "static" {
  count              = var.auto_scale ? 0 : 1
  name               = var.instance_group_name != null ? var.instance_group_name : (var.prefix != null ? "${var.prefix}-ins-group" : "ins-group")
  resource_group     = var.resource_group_id
  access_tags        = var.access_tags
  tags               = var.tags
  instance_template  = ibm_is_instance_template.instance_template.id
  instance_count     = var.instance_count
  subnets            = var.subnets[*].id
  application_port   = var.application_port
  load_balancer      = length(var.load_balancers) > 0 ? ibm_is_lb.lb[var.load_balancers[0].name].id : null
  load_balancer_pool = length(var.load_balancers) > 0 ? ibm_is_lb_pool.pool[var.load_balancers[0].name].pool_id : null

  # No ignore_changes - allows manual control of instance_count
}

##############################################################################
# Create Instance Group Manager
##############################################################################
resource "ibm_is_instance_group_manager" "instance_group_manager" {
  for_each = local.ins_group_mgr_map

  name                 = var.prefix != null ? "${var.prefix}-${each.value.name}" : each.value.name
  aggregation_window   = each.value.aggregation_window
  instance_group       = local.instance_group_id
  cooldown             = each.value.cooldown
  manager_type         = each.value.manager_type
  enable_manager       = each.value.enable_manager
  max_membership_count = each.value.max_membership_count
  min_membership_count = each.value.min_membership_count

  depends_on = [time_sleep.wait_180_seconds]
}

##############################################################################
# Create Instance Group Manager Action
#
# In order to use actions, the manager_type has to set to scheduled
##############################################################################
resource "ibm_is_instance_group_manager_action" "instance_group_manager_actions" {
  for_each = local.inst_group_mgr_action_map

  name                   = var.prefix != null ? "${var.prefix}-${each.value.name}" : each.value.name
  instance_group         = local.instance_group_id
  instance_group_manager = ibm_is_instance_group_manager.instance_group_manager[each.value.mgr_name].manager_id
  cron_spec              = each.value.cron_spec
  membership_count       = each.value.membership_count
  min_membership_count   = each.value.min_membership_count
  max_membership_count   = each.value.max_membership_count
  run_at                 = each.value.run_at
  target_manager         = each.value.min_membership_count != null && each.value.max_membership_count != null ? ibm_is_instance_group_manager.instance_group_manager[each.value.manager_name].manager_id : null
}

##############################################################################
# Create Instance Group Manager Action
#
# In order to use actions, the manager_type has to set to autoscale
##############################################################################
resource "ibm_is_instance_group_manager_policy" "instance_group_manager_policies" {
  for_each = local.inst_group_mgr_policy_map

  instance_group         = local.instance_group_id
  instance_group_manager = ibm_is_instance_group_manager.instance_group_manager[each.value.mgr_name].manager_id
  name                   = var.prefix != null ? "${var.prefix}-${each.value.name}" : each.value.name
  metric_type            = each.value.metric_type
  metric_value           = each.value.metric_value
  policy_type            = each.value.policy_type
}
