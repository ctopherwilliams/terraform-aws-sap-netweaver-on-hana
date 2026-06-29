# terraform-aws-sap-netweaver-on-hana

[![CI](https://github.com/ctopherwilliams/terraform-aws-sap-netweaver-on-hana/actions/workflows/ci.yml/badge.svg)](https://github.com/ctopherwilliams/terraform-aws-sap-netweaver-on-hana/actions/workflows/ci.yml)
[![Terraform](https://img.shields.io/badge/terraform-%3E%3D%201.0-7B42BC?logo=terraform)](https://www.terraform.io)
[![License: MIT-0](https://img.shields.io/badge/license-MIT--0-blue.svg)](./LICENSE)

A Terraform module that provisions the AWS infrastructure required to install and
run **SAP NetWeaver on HANA**. It builds the full landscape — the HANA database
tier, the ASCS (central services) tier, the application-server tier, and the
shared `/sapmnt` storage that ties them together.

> **Note**
> This module is a modernized continuation of an AWS-authored sample. See the
> [Roadmap](#roadmap) and [`REHAUL_PLAYBOOK.md`](./REHAUL_PLAYBOOK.md) for the
> current state of the upgrade work (provider versions, deprecated functions,
> security hardening).

## What it creates

For each SAP tier, the module can create:

- [EC2 instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) (with [auto-recovery](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-recover.html))
- [EBS volumes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume) with [encryption](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html)
- [Security groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)
- [Route53 DNS records](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) (optional)
- [IAM roles & instance profiles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
- An [EFS file system](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) for `/sapmnt`
- Consistent resource [tagging](./modules/_internal-modules/common/tagging)

## Architecture

```
                         ┌─────────────────────────┐
                         │   EFS  (/sapmnt shared)  │
                         └───────────┬─────────────┘
                                     │
        ┌──────────────┬─────────────┼──────────────┐
        │              │             │              │
 ┌──────▼─────┐ ┌──────▼─────┐ ┌─────▼──────┐ ┌─────▼──────┐
 │   HANA DB  │ │    ASCS    │ │  App srv 1 │ │  App srv N │
 │  host(s)   │ │   host(s)  │ │            │ │            │
 └────────────┘ └────────────┘ └────────────┘ └────────────┘
```

## Usage

```hcl
module "sap_netweaver_on_hana" {
  source = "github.com/ctopherwilliams/terraform-aws-sap-netweaver-on-hana"

  aws_region       = "us-east-1"
  application_code = "ecc"
  application_name = "ecc"
  environment_type = "dev"

  # Networking
  vpc_id        = "vpc-0123456789abcdef0"
  subnet_ids    = ["subnet-aaaa", "subnet-bbbb"]
  dns_zone_name = "sap.internal" # leave "" to skip DNS records

  # Operating system
  ami_id  = "ami-0123456789abcdef0" # SAP-certified SLES/RHEL AMI
  ssh_key = ""                      # empty => use SSM Session Manager

  # Security
  kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/..." # recommended

  # SAP
  sid       = "ECC"
  enable_ha = false

  # HANA
  hana_instance_type = "r5.2xlarge"

  # NetWeaver application tier
  ascs_instance_type = "m5.xlarge"
  as_instance_type   = "m5.xlarge"
  as_instance_count  = 2
}
```

A complete, runnable example lives in [`examples/basic`](./examples/basic).

## Sub-modules

The following modules are embedded and can be reused independently:

| Module | Purpose |
|--------|---------|
| [`aws-sap-hana-host`](./modules/aws-sap-hana-host)       | HANA database instance(s) and their EBS layout |
| [`aws-sap-ascs-host`](./modules/aws-sap-ascs-host)       | ASCS / central services instance(s) |
| [`aws-sap-app-host`](./modules/aws-sap-app-host)         | NetWeaver application server instance(s) |
| [`aws-sap-netweaver-efs`](./modules/aws-sap-netweaver-efs) | Shared EFS file system for `/sapmnt` |

## Development

```bash
# format, validate and lint
terraform fmt -recursive
terraform init -backend=false
terraform validate
tflint --recursive

# or run everything via pre-commit
pre-commit install
pre-commit run --all-files
```

CI runs `terraform fmt`, `validate`, `tflint`, a Trivy IaC scan, and a
`terraform-docs` drift check on every push and pull request
(see [`.github/workflows/ci.yml`](./.github/workflows/ci.yml)).

## Roadmap

This module is being brought back to a maintainable, modern baseline. Remaining
work is tracked in [`REHAUL_PLAYBOOK.md`](./REHAUL_PLAYBOOK.md), notably:

- Upgrade the AWS provider from `< 4.0` to v5/v6 (requires splitting the inline
  `aws_s3_bucket` arguments and refreshing other deprecated resource syntax).
- Replace the deprecated `hashicorp/template` provider with the built-in
  `templatefile()` function.
- Default EBS volume types from `gp2` to the cheaper/faster `gp3`.
- Enforce IMDSv2 on all instances.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.0, < 4.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 2.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 2.0 |
| <a name="requirement_template"></a> [template](#requirement\_template) | >= 2.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_hana_host"></a> [hana\_host](#module\_hana\_host) | ./modules/aws-sap-hana-host | n/a |
| <a name="module_sap_app_host"></a> [sap\_app\_host](#module\_sap\_app\_host) | ./modules/aws-sap-app-host | n/a |
| <a name="module_sap_ascs_host"></a> [sap\_ascs\_host](#module\_sap\_ascs\_host) | ./modules/aws-sap-ascs-host | n/a |
| <a name="module_sap_efs"></a> [sap\_efs](#module\_sap\_efs) | ./modules/aws-sap-netweaver-efs | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | (Required) The AMI id for the underlying OS | `string` | n/a | yes |
| <a name="input_app_server_root_volume_size"></a> [app\_server\_root\_volume\_size](#input\_app\_server\_root\_volume\_size) | (Optional) Size in GBs for the root volumes of the instances | `number` | `50` | no |
| <a name="input_application_code"></a> [application\_code](#input\_application\_code) | (Required) The unique application code for resource naming | `string` | n/a | yes |
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | (Required) The name of the application being provisioned, ex. 'datamart', 'ecc', 's4hana', etc. | `string` | n/a | yes |
| <a name="input_as_instance_count"></a> [as\_instance\_count](#input\_as\_instance\_count) | Number of application server instances to be provisioned | `number` | `1` | no |
| <a name="input_as_instance_type"></a> [as\_instance\_type](#input\_as\_instance\_type) | The instance type for SAP Application Servers | `string` | `"m5.xlarge"` | no |
| <a name="input_ascs_instance_type"></a> [ascs\_instance\_type](#input\_ascs\_instance\_type) | The instance type for SAP Central Services | `string` | `"m5.xlarge"` | no |
| <a name="input_ascs_root_volume_size"></a> [ascs\_root\_volume\_size](#input\_ascs\_root\_volume\_size) | (Optional) Size in GBs for the root volumes of the instances | `number` | `50` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | (Required) AWS Region to execute deployment to | `string` | n/a | yes |
| <a name="input_customer_cidr_blocks"></a> [customer\_cidr\_blocks](#input\_customer\_cidr\_blocks) | (Optional) The CIDR blocks to allow end-user connectivity from | `list(string)` | `[]` | no |
| <a name="input_customer_default_sg_id"></a> [customer\_default\_sg\_id](#input\_customer\_default\_sg\_id) | (Optional) List of preexisting security groups to be attached to the instance. The required security groups are created automatically, this is just for mandatory default ones | `list(string)` | `[]` | no |
| <a name="input_default_instance_role"></a> [default\_instance\_role](#input\_default\_instance\_role) | (Optional) Flag to define whether default instance role should be created | `bool` | `true` | no |
| <a name="input_dns_zone_name"></a> [dns\_zone\_name](#input\_dns\_zone\_name) | (Optional) The name of the Route53 private DNS zone. If left empty no DNS records will be created | `string` | `""` | no |
| <a name="input_efs_name"></a> [efs\_name](#input\_efs\_name) | (Optional) Name used for the EFS file system that backs /sapmnt | `string` | `"dir_sapmnt"` | no |
| <a name="input_efs_sapmnt"></a> [efs\_sapmnt](#input\_efs\_sapmnt) | (Optional) Flag to define whether EFS File Systems should be provisioned for /sapmnt | `bool` | `true` | no |
| <a name="input_enable_ha"></a> [enable\_ha](#input\_enable\_ha) | (Optional) Defines how many instances should be deployed | `bool` | `false` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | (Optional) Enable the provisioning of resources of the module or not | `bool` | `true` | no |
| <a name="input_environment_type"></a> [environment\_type](#input\_environment\_type) | (Required) Environment type of SAP Netweaver system, e.x. 'dev', 'test', 'prod' | `string` | n/a | yes |
| <a name="input_hana_disks_backup_storage_type"></a> [hana\_disks\_backup\_storage\_type](#input\_hana\_disks\_backup\_storage\_type) | (Optional) EBS Volume type for hana backup volumes. | `string` | `"st1"` | no |
| <a name="input_hana_disks_data_storage_type"></a> [hana\_disks\_data\_storage\_type](#input\_hana\_disks\_data\_storage\_type) | (Optional) EBS Volume type for hana data volumes. Can be gp2 or io1 | `string` | `"gp2"` | no |
| <a name="input_hana_disks_logs_storage_type"></a> [hana\_disks\_logs\_storage\_type](#input\_hana\_disks\_logs\_storage\_type) | (Optional) EBS Volume type for hana log volumes. Can be gp2 or io1 | `string` | `"gp2"` | no |
| <a name="input_hana_disks_shared_size"></a> [hana\_disks\_shared\_size](#input\_hana\_disks\_shared\_size) | (Optional) Size in GBs for the hana shared volumes of the instances | `string` | `"512"` | no |
| <a name="input_hana_disks_shared_storage_type"></a> [hana\_disks\_shared\_storage\_type](#input\_hana\_disks\_shared\_storage\_type) | (Optional) EBS Volume type for hana shared volumes. | `string` | `"gp2"` | no |
| <a name="input_hana_disks_usr_sap_storage_size"></a> [hana\_disks\_usr\_sap\_storage\_size](#input\_hana\_disks\_usr\_sap\_storage\_size) | (Optional) Size in GBs for the /usr/sap volumes of the instances | `number` | `50` | no |
| <a name="input_hana_disks_usr_sap_storage_type"></a> [hana\_disks\_usr\_sap\_storage\_type](#input\_hana\_disks\_usr\_sap\_storage\_type) | (Optional) EBS Volume type for hana /usr/sap volumes. | `string` | `"gp2"` | no |
| <a name="input_hana_instance_type"></a> [hana\_instance\_type](#input\_hana\_instance\_type) | (Required) Identifies the instance types to be used for HANA. Should be from the list of certified instances, since the disk sizing is done based on this | `string` | n/a | yes |
| <a name="input_hana_is_scale_out"></a> [hana\_is\_scale\_out](#input\_hana\_is\_scale\_out) | (Optional) Defines whether Shared disk should be create as an EFS file system | `bool` | `false` | no |
| <a name="input_hana_scale_out_node_count"></a> [hana\_scale\_out\_node\_count](#input\_hana\_scale\_out\_node\_count) | (Required, if hana\_is\_scale\_out = false) Defines how many nodes required for scale-out scenario | `number` | `3` | no |
| <a name="input_high_availability"></a> [high\_availability](#input\_high\_availability) | (Deprecated) Retained for backwards compatibility. High availability is controlled by `enable_ha`, which is the variable actually consumed by the module | `bool` | `false` | no |
| <a name="input_iam_instance_role"></a> [iam\_instance\_role](#input\_iam\_instance\_role) | (Optional) The IAM role name to be attached to instance profile | `string` | `""` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | (Optional) ARN of the KMS key used to encrypt EBS and EFS volumes. If left empty, volumes are created unencrypted. Supplying a key is strongly recommended | `string` | `""` | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | (Optional) Size in GBs for the root volumes of the instances | `number` | `50` | no |
| <a name="input_sapmnt_volume_size"></a> [sapmnt\_volume\_size](#input\_sapmnt\_volume\_size) | (Optional) Size in GBs for the /sapmnt volume. Use it only for non-EFS scenario. Not provisioned if value = 0 | `number` | `0` | no |
| <a name="input_sid"></a> [sid](#input\_sid) | (Required) The System id for the SAP Netweaver system | `string` | n/a | yes |
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | (Optional) The key pair name for the instances. If not provided - you can use SSM session manager for console access | `string` | `""` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | (Required) List of subnets for instance distribution | `list(string)` | n/a | yes |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | (Optional) The user data script for the instance. If none provisioned - default one will be used to install AWS CLI and SSM agent | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | (Required) VPC to deploy infrastructure to | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_app_instance_ids"></a> [app\_instance\_ids](#output\_app\_instance\_ids) | EC2 instance IDs of the application server host(s) |
| <a name="output_app_private_ips"></a> [app\_private\_ips](#output\_app\_private\_ips) | Private IP addresses of the application server host(s) |
| <a name="output_ascs_instance_ids"></a> [ascs\_instance\_ids](#output\_ascs\_instance\_ids) | EC2 instance IDs of the ASCS host(s) |
| <a name="output_ascs_private_ips"></a> [ascs\_private\_ips](#output\_ascs\_private\_ips) | Private IP addresses of the ASCS host(s) |
| <a name="output_hana_instance_ids"></a> [hana\_instance\_ids](#output\_hana\_instance\_ids) | EC2 instance IDs of the HANA host(s) |
| <a name="output_hana_private_ips"></a> [hana\_private\_ips](#output\_hana\_private\_ips) | Private IP addresses of the HANA host(s) |
| <a name="output_sapmnt_efs_id"></a> [sapmnt\_efs\_id](#output\_sapmnt\_efs\_id) | EFS file system ID backing /sapmnt |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md). Please run `pre-commit run --all-files`
before opening a pull request.

## Security

See [SECURITY.md](./SECURITY.md) for how to report vulnerabilities.

## License

Licensed under the MIT-0 License. See [LICENSE](./LICENSE).
