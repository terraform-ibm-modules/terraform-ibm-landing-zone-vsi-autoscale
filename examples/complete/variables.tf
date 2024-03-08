variable "ibmcloud_api_key" {
  description = "APIkey that's associated with the account to provision resources to"
  type        = string
  sensitive   = true
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

variable "region" {
  description = "The region to which to deploy the VPC"
  type        = string
  default     = "us-east"
}

variable "prefix" {
  description = "The prefix that you would like to append to your resources"
  type        = string
  default     = "slz-vsi"
}

variable "resource_tags" {
  description = "List of Tags for the resource created"
  type        = list(string)
  default     = null
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the VSI resources created by the module."
  default     = []
}

variable "image_id" {
  description = "Image ID used for VSI. Run 'ibmcloud is images' to find available images. Be aware that region is important for the image since the id's are different in each region."
  type        = string
  default     = "r014-63b824ce-ee4b-4494-b92f-f888630746c5"
}

variable "machine_type" {
  description = "VSI machine type"
  type        = string
  default     = "cx2-2x4"
}

variable "application_port" {
  type        = number
  description = "Application port"
  default     = 80
}

variable "create_security_group" {
  description = "Create security group for VSI"
  type        = string
  default     = true
}

variable "security_group" {
  description = "Security group created for VSI"
  type = object({
    name = string
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
  default = {
    name : "vsi-sg",
    rules : [
      {
        direction : "inbound",
        name : "allow-vpc-inbound",
        source : "10.0.0.0/8"
      }
    ]
  }
}

variable "user_data" {
  description = "User data to initialize VSI deployment"
  type        = string
  default     = null
}

variable "kms_encryption_enabled" {
  type        = bool
  description = "Set this to true to control the encryption keys used to encrypt the data that for the block storage volumes for VPC. If set to false, the data is encrypted by using randomly generated keys. For more info on encrypting block storage volumes, see https://cloud.ibm.com/docs/vpc?topic=vpc-creating-instances-byok"
  default     = false
}

variable "existing_kms_instance_guid" {
  description = "The GUID of the Hyper Protect Crypto Services instance in which the key specified in var.boot_volume_encryption_key is coming from."
  type        = string
  default     = null
}

variable "boot_volume_encryption_key" {
  description = "CRN of boot volume encryption key"
  type        = string
  default     = null
}

variable "skip_iam_authorization_policy" {
  type        = bool
  description = "Set to true to skip the creation of an IAM authorization policy that permits all Storage Blocks to read the encryption key from the KMS instance. If set to false, pass in a value for the KMS instance in the existing_kms_instance_guid variable. In addition, no policy is created if var.kms_encryption_enabled is set to false."
  default     = false
}

variable "ssh_key" {
  type        = string
  description = "An existing ssh key name to use for this example, if unset a new ssh key will be created"
  default     = null
}

variable "vpc_name" {
  type        = string
  description = "Name for VPC"
  default     = "web-test-workload"
}

variable "block_storage_volumes" {
  description = "List describing the block storage volumes that will be attached to each vsi"
  type = list(
    object({
      name           = string
      profile        = string
      capacity       = number
      iops           = optional(number)
      encryption_key = optional(string)
    })
  )
  default = []

  validation {
    error_message = "Each block storage volume must have a unique name."
    condition     = length(distinct(var.block_storage_volumes[*].name)) == length(var.block_storage_volumes)
  }
}

variable "instance_count" {
  type        = number
  description = "The number of instances to create in the instance group."
  default     = 2
}

variable "load_balancers" {
  description = "Load balancers to add to VSI"
  type = list(
    object({
      name                    = string
      type                    = string
      listener_port           = number
      listener_protocol       = string
      connection_limit        = number
      idle_connection_timeout = optional(number)
      algorithm               = string
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
          name = string
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
    })
  )

  default = [{
    name              = "srv-lb",
    type              = "public",
    listener_port     = 80,
    listener_protocol = "tcp",
    connection_limit  = 10,
    protocol          = "tcp",
    pool_member_port  = 80,
    algorithm         = "round_robin",
    health_delay      = 60,
    health_retries    = 5,
    health_timeout    = 30,
    health_type       = "tcp",
    security_group = {
      name = "lb-sg",
      rules = [
        {
          direction = "inbound",
          name      = "allow-vpc-inbound",
          source    = "10.0.0.0/8"
        }
      ]
    }
  }]
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

  default = [
    {
      name                 = "test"
      aggregation_window   = 120
      cooldown             = 300
      manager_type         = "autoscale"
      enable_manager       = true
      max_membership_count = 4
      min_membership_count = 1
      policies = [{
        name         = "policy1"
        manager_name = "test"
        metric_type  = "cpu"
        metric_value = 70
        policy_type  = "target"
      }]
    }
  ]

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
