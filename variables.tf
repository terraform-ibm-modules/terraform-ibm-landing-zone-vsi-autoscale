##############################################################################
# Account Variables
##############################################################################

variable "resource_group_id" {
  description = "ID of resource group to create VSI and block storage volumes. If you wish to create the block storage volumes in a different resource group, you can optionally set that directly in the 'block_storage_volumes' variable."
  type        = string
}

variable "prefix" {
  description = "A unique identifier for resources. Must begin with a letter and end with a letter or number. This prefix will be prepended to any resources provisioned by this template. Prefixes must be 16 or fewer characters."
  type        = string

  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix))
  }
}

variable "zone" {
  description = "The zone to create the resource in"
  type        = string
}

variable "tags" {
  description = "List of tags to apply to resources created by this module."
  type        = list(string)
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the VSI resources created by the module. For more information, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial."
  default     = []

  validation {
    condition = alltrue([
      for tag in var.access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\". For more information, see https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits."
  }
}

##############################################################################


##############################################################################
# VPC Variables
##############################################################################

variable "vpc_id" {
  description = "ID of VPC"
  type        = string
}

variable "subnets" {
  description = "A list of subnet IDs where VSI will be deployed"
  type = list(
    object({
      name = string
      id   = string
      zone = string
      cidr = optional(string)
      crn  = optional(string)
    })
  )
}

##############################################################################


##############################################################################
# Autoscale (Instance template) Variables
##############################################################################
variable "availability_policy_host_failure" {
  description = "The availability policy to use for this virtual server instance. The action to perform if the compute host experiences a failure"
  type        = string
  default     = "restart"
}

variable "dedicated_host" {
  description = "The placement restrictions to use for the virtual server instance. Unique Identifier of the dedicated host where the instance is placed."
  type        = string
  default     = null
}

variable "dedicated_host_group" {
  description = "The placement restrictions to use for the virtual server instance. Unique Identifier of the dedicated host group where the instance is placed."
  type        = string
  default     = null
}

variable "image_id" {
  description = "Image ID used for VSI. Run 'ibmcloud is images' to find available images in a region"
  type        = string
}

variable "ssh_key_ids" {
  description = "ssh key ids to use in creating vsi"
  type        = list(string)
}

variable "machine_type" {
  description = "VSI machine type. Run 'ibmcloud is instance-profiles' to get a list of regional profiles"
  type        = string
}

variable "user_data" {
  description = "User data to initialize VSI deployment"
  type        = string
  default     = null
}

variable "boot_volume_encryption_key" {
  description = "CRN of boot volume encryption key"
  default     = null
  type        = string
}

variable "auto_delete_volumes" {
  type        = bool
  description = "Auto delete volumes when the instance is deleted"
  default     = true
}

variable "existing_kms_instance_guid" {
  description = "The GUID of the Hyper Protect Crypto Services instance in which the key specified in var.boot_volume_encryption_key is coming from."
  type        = string
  default     = null
}

variable "allow_ip_spoofing" {
  description = "Allow IP spoofing on the primary network interface"
  type        = bool
  default     = false
}

variable "create_security_group" {
  description = "Create security group for VSI. If this is passed as false, the default will be used"
  type        = bool
}

variable "placement_group_id" {
  description = "Unique Identifier of the Placement Group for restricting the placement of the instance, default behaviour is placement on any host"
  type        = string
  default     = null
}

variable "security_group" {
  description = "Security group created for VSI"
  type = object({
    name                         = string
    add_ibm_cloud_internal_rules = optional(bool, false)
    rules = list(
      object({
        name      = string
        direction = string
        source    = string
        tcp = optional(
          object({
            port_max = number
            port_min = number
          })
        )
        udp = optional(
          object({
            port_max = number
            port_min = number
          })
        )
        icmp = optional(
          object({
            type = number
            code = number
          })
        )
      })
    )
  })

  validation {
    error_message = "Each security group rule must have a unique name."
    condition = (
      var.security_group == null
      ? true
      : length(distinct(var.security_group.rules[*].name)) == length(var.security_group.rules[*].name)
    )
  }

  validation {
    error_message = "Security group rule direction can only be `inbound` or `outbound`."
    condition = var.security_group == null ? true : length(
      distinct(
        flatten([
          for rule in var.security_group.rules :
          false if !contains(["inbound", "outbound"], rule.direction)
        ])
      )
    ) == 0
  }
  default = null
}

variable "security_group_ids" {
  description = "IDs of additional security groups to be added to VSI deployment primary interface. A VSI interface can have a maximum of 5 security groups."
  type        = list(string)
  default     = []

  validation {
    error_message = "Security group IDs must be unique."
    condition     = length(var.security_group_ids) == length(distinct(var.security_group_ids))
  }

  validation {
    error_message = "No more than 5 security groups can be added to a VSI deployment."
    condition     = length(var.security_group_ids) <= 5
  }
}

variable "kms_encryption_enabled" {
  type        = bool
  description = "Set this to true to control the encryption keys used to encrypt the data that for the block storage volumes for VPC. If set to false, the data is encrypted by using randomly generated keys. For more info on encrypting block storage volumes, see https://cloud.ibm.com/docs/vpc?topic=vpc-creating-instances-byok"
  default     = false
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits all Storage Blocks to read the encryption key from the KMS instance. If set to false, pass in a value for the KMS instance in the existing_kms_instance_guid variable. In addition, no policy is created if var.kms_encryption_enabled is set to false."
  default     = false
}

variable "block_storage_volumes" {
  description = "List describing the block storage volumes that will be attached to each vsi"
  type = list(
    object({
      name              = string
      profile           = string
      capacity          = optional(number)
      iops              = optional(number)
      encryption_key    = optional(string)
      resource_group_id = optional(string)
    })
  )
  default = []

  validation {
    error_message = "Each block storage volume must have a unique name."
    condition     = length(distinct(var.block_storage_volumes[*].name)) == length(var.block_storage_volumes)
  }
}

variable "load_balancers" {
  description = "Load balancers to add to VSI"
  type = list(
    object({
      name                    = string
      type                    = string
      logging                 = optional(bool)
      listener_port           = number
      listener_protocol       = string
      connection_limit        = number
      idle_connection_timeout = optional(number)
      algorithm               = string
      certificate_instance    = optional(string)
      protocol                = string
      health_delay            = number
      health_retries          = number
      health_timeout          = number
      health_type             = string
      pool_member_port        = string
      profile                 = optional(string)
      dns = optional(
        object({
          instance_crn = string
          zone_id      = string
        })
      )
      security_group = optional(
        object({
          name                         = string
          add_ibm_cloud_internal_rules = optional(bool, false)
          rules = list(
            object({
              name      = string
              direction = string
              source    = string
              tcp = optional(
                object({
                  port_max = number
                  port_min = number
                })
              )
              udp = optional(
                object({
                  port_max = number
                  port_min = number
                })
              )
              icmp = optional(
                object({
                  type = number
                  code = number
                })
              )
            })
          )
        })
      )
      policies = optional(
        list(object({
          name     = string
          action   = string
          priority = number
          rules = optional(list(
            object({
              condition = string
              type      = string
              value     = string
              field     = string
            })
          ))
          target = optional(list(
            object({
              url              = optional(string)
              http_status_code = optional(string)
              pool_id          = optional(string)
              listener_id      = optional(string)
            })
          ))
          })
      ))
    })
  )

  default = []

  validation {
    error_message = "Only one load balancer can be defined for autoscaling."
    condition     = length(var.load_balancers) < 2
  }

  validation {
    error_message = "Load balancer names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition = length(distinct(
      flatten([
        # Check through rules
        for load_balancer in var.load_balancers :
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", load_balancer.name))
      ])
    )) == 0
  }

  validation {
    error_message = "Load balancer idle_connection_timeout must be between 50 and 7200."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        load_balancer.idle_connection_timeout != null ?
        (load_balancer.idle_connection_timeout < 50 || load_balancer.idle_connection_timeout > 7200) ? [true] : []
        : []
      ])
    ) == 0
  }

  validation {
    error_message = "Load Balancer Pool algorithm can only be `round_robin`, `weighted_round_robin`, or `least_connections`."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        true if !contains(["round_robin", "weighted_round_robin", "least_connections"], load_balancer.algorithm)
      ])
    ) == 0
  }

  validation {
    error_message = "Load Balancer Pool Protocol can only be `http`, `https`, or `tcp`."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        true if !contains(["http", "https", "tcp"], load_balancer.protocol)
      ])
    ) == 0
  }

  validation {
    error_message = "If Load Balancer listener protocol is `https`, certificate_instance variable must be defined"
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        true if("https" == load_balancer.listener_protocol && load_balancer.certificate_instance == null)
      ])
    ) == 0
  }

  validation {
    error_message = "Pool health delay must be greater than the timeout."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        true if load_balancer.health_delay < load_balancer.health_timeout
      ])
    ) == 0
  }

  validation {
    error_message = "Load Balancer Pool Health Check Type can only be `http`, `https`, or `tcp`."
    condition = length(
      flatten([
        for load_balancer in var.load_balancers :
        true if !contains(["http", "https", "tcp"], load_balancer.health_type)
      ])
    ) == 0
  }

  validation {
    error_message = "Each load balancer must have a unique name."
    condition     = length(distinct(var.load_balancers[*].name)) == length(var.load_balancers[*].name)
  }
}

##############################################################################

##############################################################################
# Autoscale (Instance Group) Variables
##############################################################################

variable "instance_count" {
  type        = number
  description = "The number of instances to create in the instance group."
  default     = null
}

variable "application_port" {
  type        = number
  description = "The instance group uses when scaling up instances to supply the port for the Load Balancer pool member."
  default     = null
}

variable "group_managers" {
  description = "Instance group manager to add to the instance group"
  type = list(
    object({
      name                 = string
      aggregation_window   = optional(number)
      cooldown             = optional(number)
      enable_manager       = optional(bool)
      manager_type         = string
      max_membership_count = optional(number)
      min_membership_count = optional(number)
      actions = optional(
        list(
          object({
            name                 = string
            cron_spec            = optional(string)
            membership_count     = optional(number)
            max_membership_count = optional(number)
            min_membership_count = optional(number)
            run_at               = optional(string)
          })
        )
      )
      policies = optional(
        list(
          object({
            name         = string
            metric_type  = string
            metric_value = number
            policy_type  = string
          })
        )
      )
    })
  )

  default = []

  validation {
    error_message = "Each Instance group manager must have a unique name."
    condition     = length(distinct(var.group_managers[*].name)) == length(var.group_managers[*].name)
  }

  validation {
    error_message = "Manager type can only be `autoscale`, or `scheduled`."
    condition = length(
      flatten([
        for group_manager in var.group_managers :
        true if !contains(["autoscale", "scheduled"], group_manager.manager_type)
      ])
    ) == 0
  }
}
