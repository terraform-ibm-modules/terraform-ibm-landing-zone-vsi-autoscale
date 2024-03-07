<!-- Update the title -->
# Terraform Modules Template Project

<!--
Update status and "latest release" badges:
  1. For the status options, see https://terraform-ibm-modules.github.io/documentation/#/badge-status
  2. Update the "latest release" badge to point to the correct module's repo. Replace "terraform-ibm-module-template" in two places.
-->
[![Incubating (Not yet consumable)](https://img.shields.io/badge/status-Incubating%20(Not%20yet%20consumable)-red)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-module-template?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-module-template/releases/latest)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

<!-- Add a description of module(s) in this repo -->
TODO: Replace me with description of the module(s) in this repo


<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGIN OVERVIEW HOOK -->
## Overview
* [terraform-ibm-landing-zone-vsi-autoscale](#terraform-ibm-landing-zone-vsi-autoscale)
* [Examples](./examples)
    * [Complete example](./examples/complete)
    * [End to end basic example](./examples/basic)
* [Contributing](#contributing)
<!-- END OVERVIEW HOOK -->


<!--
If this repo contains any reference architectures, uncomment the heading below and links to them.
(Usually in the `/reference-architectures` directory.)
See "Reference architecture" in Authoring Guidelines in the public documentation at
https://terraform-ibm-modules.github.io/documentation/#/implementation-guidelines?id=reference-architecture
-->
<!-- ## Reference architectures -->


<!-- This heading should always match the name of the root level module (aka the repo name) -->
## terraform-ibm-module-template

### Usage

<!--
Add an example of the use of the module in the following code block.

Use real values instead of "var.<var_name>" or other placeholder values
unless real values don't help users know what to change.
-->

```hcl

```

### Required IAM access policies

<!-- PERMISSIONS REQUIRED TO RUN MODULE
If this module requires permissions, uncomment the following block and update
the sample permissions, following the format.
Replace the sample Account and IBM Cloud service names and roles with the
information in the console at
Manage > Access (IAM) > Access groups > Access policies.
-->

<!--
You need the following permissions to run this module.

- Account Management
    - **Sample Account Service** service
        - `Editor` platform access
        - `Manager` service access
    - IAM Services
        - **Sample Cloud Service** service
            - `Administrator` platform access
-->

<!-- NO PERMISSIONS FOR MODULE
If no permissions are required for the module, uncomment the following
statement instead the previous block.
-->

<!-- No permissions are needed to run this module.-->


<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, <1.6.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.59.0, < 2.0.0 |
| <a name="requirement_time"></a> [time](#requirement\_time) | >= 0.9.1, < 1.0.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [ibm_iam_authorization_policy.block_storage_policy](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/iam_authorization_policy) | resource |
| [ibm_is_instance_group.instance_group](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_instance_group) | resource |
| [ibm_is_instance_group_manager.instance_group_manager](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_instance_group_manager) | resource |
| [ibm_is_instance_group_manager_action.instance_group_manager_actions](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_instance_group_manager_action) | resource |
| [ibm_is_instance_group_manager_policy.instance_group_manager_policies](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_instance_group_manager_policy) | resource |
| [ibm_is_instance_template.instance_template](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_instance_template) | resource |
| [ibm_is_lb.lb](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_lb) | resource |
| [ibm_is_lb_listener.listener](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_lb_listener) | resource |
| [ibm_is_lb_pool.pool](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_lb_pool) | resource |
| [ibm_is_security_group.security_group](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_security_group) | resource |
| [ibm_is_security_group_rule.security_group_rules](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_security_group_rule) | resource |
| [time_sleep.wait_180_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [time_sleep.wait_for_authorization_policy](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [ibm_is_vpc.vpc](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/data-sources/is_vpc) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tags"></a> [access\_tags](#input\_access\_tags) | A list of access tags to apply to the VSI resources created by the module. For more information, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial. | `list(string)` | `[]` | no |
| <a name="input_allow_ip_spoofing"></a> [allow\_ip\_spoofing](#input\_allow\_ip\_spoofing) | Allow IP spoofing on the primary network interface | `bool` | `false` | no |
| <a name="input_application_port"></a> [application\_port](#input\_application\_port) | The instance group uses when scaling up instances to supply the port for the Load Balancer pool member. | `number` | `null` | no |
| <a name="input_auto_delete_volumes"></a> [auto\_delete\_volumes](#input\_auto\_delete\_volumes) | Auto delete volumes when the instance is deleted | `bool` | `true` | no |
| <a name="input_availability_policy_host_failure"></a> [availability\_policy\_host\_failure](#input\_availability\_policy\_host\_failure) | The availability policy to use for this virtual server instance. The action to perform if the compute host experiences a failure | `string` | `"restart"` | no |
| <a name="input_block_storage_volumes"></a> [block\_storage\_volumes](#input\_block\_storage\_volumes) | List describing the block storage volumes that will be attached to each vsi | <pre>list(<br>    object({<br>      name              = string<br>      profile           = string<br>      capacity          = optional(number)<br>      iops              = optional(number)<br>      encryption_key    = optional(string)<br>      resource_group_id = optional(string)<br>    })<br>  )</pre> | `[]` | no |
| <a name="input_boot_volume_encryption_key"></a> [boot\_volume\_encryption\_key](#input\_boot\_volume\_encryption\_key) | CRN of boot volume encryption key | `string` | `null` | no |
| <a name="input_create_security_group"></a> [create\_security\_group](#input\_create\_security\_group) | Create security group for VSI. If this is passed as false, the default will be used | `bool` | n/a | yes |
| <a name="input_dedicated_host"></a> [dedicated\_host](#input\_dedicated\_host) | The placement restrictions to use for the virtual server instance. Unique Identifier of the dedicated host where the instance is placed. | `string` | `null` | no |
| <a name="input_dedicated_host_group"></a> [dedicated\_host\_group](#input\_dedicated\_host\_group) | The placement restrictions to use for the virtual server instance. Unique Identifier of the dedicated host group where the instance is placed. | `string` | `null` | no |
| <a name="input_existing_kms_instance_guid"></a> [existing\_kms\_instance\_guid](#input\_existing\_kms\_instance\_guid) | The GUID of the Hyper Protect Crypto Services instance in which the key specified in var.boot\_volume\_encryption\_key is coming from. | `string` | `null` | no |
| <a name="input_group_managers"></a> [group\_managers](#input\_group\_managers) | Instance group manager to add to the instance group | <pre>list(<br>    object({<br>      name                 = string<br>      aggregation_window   = optional(number)<br>      cooldown             = optional(number)<br>      enable_manager       = optional(bool)<br>      manager_type         = string<br>      max_membership_count = optional(number)<br>      min_membership_count = optional(number)<br>      actions = optional(<br>        list(<br>          object({<br>            name                 = string<br>            cron_spec            = optional(string)<br>            membership_count     = optional(number)<br>            max_membership_count = optional(number)<br>            min_membership_count = optional(number)<br>            run_at               = optional(string)<br>          })<br>        )<br>      )<br>      policies = optional(<br>        list(<br>          object({<br>            name         = string<br>            metric_type  = string<br>            metric_value = number<br>            policy_type  = string<br>          })<br>        )<br>      )<br>    })<br>  )</pre> | `[]` | no |
| <a name="input_image_id"></a> [image\_id](#input\_image\_id) | Image ID used for VSI. Run 'ibmcloud is images' to find available images in a region | `string` | n/a | yes |
| <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count) | The number of instances to create in the instance group. | `number` | `null` | no |
| <a name="input_kms_encryption_enabled"></a> [kms\_encryption\_enabled](#input\_kms\_encryption\_enabled) | Set this to true to control the encryption keys used to encrypt the data that for the block storage volumes for VPC. If set to false, the data is encrypted by using randomly generated keys. For more info on encrypting block storage volumes, see https://cloud.ibm.com/docs/vpc?topic=vpc-creating-instances-byok | `bool` | `false` | no |
| <a name="input_load_balancers"></a> [load\_balancers](#input\_load\_balancers) | Load balancers to add to VSI | <pre>list(<br>    object({<br>      name                    = string<br>      type                    = string<br>      logging                 = optional(bool)<br>      listener_port           = number<br>      listener_protocol       = string<br>      connection_limit        = number<br>      idle_connection_timeout = optional(number)<br>      algorithm               = string<br>      protocol                = string<br>      health_delay            = number<br>      health_retries          = number<br>      health_timeout          = number<br>      health_type             = string<br>      pool_member_port        = string<br>      profile                 = optional(string)<br>      dns = optional(<br>        object({<br>          instance_crn = string<br>          zone_id      = string<br>        })<br>      )<br>      security_group = optional(<br>        object({<br>          name = string<br>          rules = list(<br>            object({<br>              name      = string<br>              direction = string<br>              source    = string<br>              tcp = optional(<br>                object({<br>                  port_max = number<br>                  port_min = number<br>                })<br>              )<br>              udp = optional(<br>                object({<br>                  port_max = number<br>                  port_min = number<br>                })<br>              )<br>              icmp = optional(<br>                object({<br>                  type = number<br>                  code = number<br>                })<br>              )<br>            })<br>          )<br>        })<br>      )<br>    })<br>  )</pre> | `[]` | no |
| <a name="input_machine_type"></a> [machine\_type](#input\_machine\_type) | VSI machine type. Run 'ibmcloud is instance-profiles' to get a list of regional profiles | `string` | n/a | yes |
| <a name="input_placement_group_id"></a> [placement\_group\_id](#input\_placement\_group\_id) | Unique Identifier of the Placement Group for restricting the placement of the instance, default behaviour is placement on any host | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A unique identifier for resources. Must begin with a letter and end with a letter or number. This prefix will be prepended to any resources provisioned by this template. Prefixes must be 16 or fewer characters. | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | ID of resource group to create VSI and block storage volumes. If you wish to create the block storage volumes in a different resource group, you can optionally set that directly in the 'block\_storage\_volumes' variable. | `string` | n/a | yes |
| <a name="input_security_group"></a> [security\_group](#input\_security\_group) | Security group created for VSI | <pre>object({<br>    name = string<br>    rules = list(<br>      object({<br>        name      = string<br>        direction = string<br>        source    = string<br>        tcp = optional(<br>          object({<br>            port_max = number<br>            port_min = number<br>          })<br>        )<br>        udp = optional(<br>          object({<br>            port_max = number<br>            port_min = number<br>          })<br>        )<br>        icmp = optional(<br>          object({<br>            type = number<br>            code = number<br>          })<br>        )<br>      })<br>    )<br>  })</pre> | `null` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | IDs of additional security groups to be added to VSI deployment primary interface. A VSI interface can have a maximum of 5 security groups. | `list(string)` | `[]` | no |
| <a name="input_skip_iam_authorization_policy"></a> [skip\_iam\_authorization\_policy](#input\_skip\_iam\_authorization\_policy) | Set to true to skip the creation of an IAM authorization policy that permits all Storage Blocks to read the encryption key from the KMS instance. If set to false, pass in a value for the KMS instance in the existing\_kms\_instance\_guid variable. In addition, no policy is created if var.kms\_encryption\_enabled is set to false. | `bool` | `false` | no |
| <a name="input_ssh_key_ids"></a> [ssh\_key\_ids](#input\_ssh\_key\_ids) | ssh key ids to use in creating vsi | `list(string)` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | A list of subnet IDs where VSI will be deployed | <pre>list(<br>    object({<br>      name = string<br>      id   = string<br>      zone = string<br>      cidr = optional(string)<br>      crn  = optional(string)<br>    })<br>  )</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | List of tags to apply to resources created by this module. | `list(string)` | `[]` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | User data to initialize VSI deployment | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of VPC | `string` | n/a | yes |
| <a name="input_zone"></a> [zone](#input\_zone) | The zone to create the resource in | `string` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_ibm_is_instance_group"></a> [ibm\_is\_instance\_group](#output\_ibm\_is\_instance\_group) | Instance group information |
| <a name="output_intstance_template"></a> [intstance\_template](#output\_intstance\_template) | Instance template information |
| <a name="output_lbs"></a> [lbs](#output\_lbs) | Load balancer information |
| <a name="output_security_groups"></a> [security\_groups](#output\_security\_groups) | Security group information |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
