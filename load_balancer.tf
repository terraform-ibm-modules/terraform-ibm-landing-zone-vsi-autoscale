locals {
  load_balancer_map = {
    for load_balancer in var.load_balancers :
    (load_balancer.name) => load_balancer
  }

  lb_listener_policy_list = flatten([
    for lb in var.load_balancers : [
      for policy in(lb.policies != null ? lb.policies : []) : [
        merge(policy, { lb_name = lb.name })
      ]
    ]
  ])

  lb_listener_policy_map = {
    for policy in local.lb_listener_policy_list :
    (policy.name) => policy
  }

  lb_listener_policy_rule_list = flatten([
    for policy in local.lb_listener_policy_list : [
      for rule in(policy.rules != null ? policy.rules : []) : [
        merge(rule, { name = "${rule.type}-${rule.field}-${rule.value}", lb_listener_policy = policy.name, lb_name : policy.lb_name })
      ]
    ]
  ])

  lb_listener_policy_rule_map = {
    for rule in local.lb_listener_policy_rule_list :
    (rule.name) => rule
  }
}


resource "ibm_is_lb" "lb" {
  for_each        = local.load_balancer_map
  name            = "${var.prefix}-${each.value.name}-lb"
  subnets         = var.subnets[*].id
  type            = each.value.type #checkov:skip=CKV2_IBM_1:See https://github.com/bridgecrewio/checkov/issues/5824#
  profile         = each.value.profile
  security_groups = each.value.security_group == null ? null : [module.security_groups[each.value.security_group.name].security_group_id]
  resource_group  = var.resource_group_id
  tags            = var.tags
  access_tags     = var.access_tags
  logging         = each.value.logging
  dynamic "dns" {
    for_each = each.value.dns == null ? [] : [each.value.dns]

    content {
      instance_crn = dns.value.instance_crn
      zone_id      = dns.value.zone_id
    }
  }
}

##############################################################################


##############################################################################
# Load Balancer Pool
##############################################################################

resource "ibm_is_lb_pool" "pool" {
  for_each       = local.load_balancer_map
  lb             = ibm_is_lb.lb[each.value.name].id
  name           = "${var.prefix}-${each.value.name}-lb-pool"
  algorithm      = each.value.algorithm
  protocol       = each.value.protocol
  health_delay   = each.value.health_delay
  health_retries = each.value.health_retries
  health_timeout = each.value.health_timeout
  health_type    = each.value.health_type
}

##############################################################################

##############################################################################
# Load Balancer Listener
##############################################################################

resource "ibm_is_lb_listener" "listener" {
  for_each                = local.load_balancer_map
  lb                      = ibm_is_lb.lb[each.value.name].id
  default_pool            = ibm_is_lb_pool.pool[each.value.name].id
  port                    = each.value.listener_port
  protocol                = each.value.listener_protocol
  certificate_instance    = each.value.certificate_instance
  connection_limit        = each.value.connection_limit > 0 ? each.value.connection_limit : null
  idle_connection_timeout = each.value.idle_connection_timeout
}

##############################################################################

##############################################################################
# Load Balancer Listener Policies
##############################################################################

resource "ibm_is_lb_listener_policy" "listener_policies" {
  for_each = local.lb_listener_policy_map
  lb       = ibm_is_lb.lb[each.value.lb_name].id
  name     = each.value.name
  listener = ibm_is_lb_listener.listener[each.value.lb_name].id
  priority = each.value.priority
  action   = each.value.action

  dynamic "target" {
    for_each = each.value.target == null ? [] : each.value.target

    content {
      url              = target.value.url
      http_status_code = target.value.http_status_code
      id               = target.value.pool_id

      dynamic "listener" {
        for_each = target.value.listener_id == null ? [] : [target.value.listener_id]

        content {
          id = listener.value
        }
      }
    }
  }
}

##############################################################################

##############################################################################
# Load Balancer Listener Policy Rules
##############################################################################

resource "ibm_is_lb_listener_policy_rule" "listener_policy_rule" {
  for_each  = local.lb_listener_policy_rule_map
  lb        = ibm_is_lb.lb[each.value.lb_name].id
  listener  = ibm_is_lb_listener.listener[each.value.lb_name].id
  policy    = ibm_is_lb_listener_policy.listener_policies[each.value.lb_listener_policy].id
  condition = each.value.condition
  value     = each.value.value
  field     = each.value.field
  type      = each.value.type
}

##############################################################################
