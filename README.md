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
| terraform | >= 1.0 |
| aws | >= 3.0, < 4.0 |
| null | >= 2.0 |
| random | >= 2.0 |
| template | >= 2.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.0, < 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS Region to execute deployment to | `string` | n/a | yes |
| application_code | Unique application code for resource naming | `string` | n/a | yes |
| application_name | Name of the application (e.g. `ecc`, `s4hana`) | `string` | n/a | yes |
| environment_type | Environment type (`dev`, `test`, `prod`) | `string` | n/a | yes |
| vpc_id | VPC to deploy infrastructure to | `string` | n/a | yes |
| subnet_ids | List of subnets for instance distribution | `list(string)` | n/a | yes |
| ami_id | AMI id for the underlying OS | `string` | n/a | yes |
| sid | System ID for the SAP NetWeaver system | `string` | n/a | yes |
| hana_instance_type | SAP-certified instance type for HANA | `string` | n/a | yes |
| enabled | Enable provisioning of the module's resources | `bool` | `true` | no |
| dns_zone_name | Route53 private DNS zone name (empty = no records) | `string` | `""` | no |
| customer_default_sg_id | Preexisting security groups to attach | `list(string)` | `[]` | no |
| customer_cidr_blocks | CIDR blocks to allow end-user connectivity from | `list(string)` | `[]` | no |
| ssh_key | EC2 key pair name (empty = use SSM Session Manager) | `string` | `""` | no |
| user_data | User-data script (empty = default bootstrap) | `string` | `""` | no |
| kms_key_arn | KMS key ARN for EBS/EFS encryption (recommended) | `string` | `""` | no |
| default_instance_role | Create the default instance role | `bool` | `true` | no |
| iam_instance_role | IAM role name to attach to the instance profile | `string` | `""` | no |
| enable_ha | Provision a second HANA and ASCS instance | `bool` | `false` | no |
| high_availability | Deprecated; superseded by `enable_ha` | `bool` | `false` | no |
| hana_is_scale_out | Use EFS-backed shared disk for scale-out | `bool` | `false` | no |
| hana_scale_out_node_count | Nodes for the scale-out scenario | `number` | `3` | no |
| root_volume_size | Root volume size (GB) | `number` | `50` | no |
| hana_disks_data_storage_type | EBS type for HANA data volumes (`gp2`/`io1`) | `string` | `"gp2"` | no |
| hana_disks_logs_storage_type | EBS type for HANA log volumes (`gp2`/`io1`) | `string` | `"gp2"` | no |
| hana_disks_backup_storage_type | EBS type for HANA backup volumes | `string` | `"st1"` | no |
| hana_disks_shared_storage_type | EBS type for HANA shared volumes | `string` | `"gp2"` | no |
| hana_disks_shared_size | Size (GB) for HANA shared volumes | `string` | `"512"` | no |
| hana_disks_usr_sap_storage_type | EBS type for `/usr/sap` volumes | `string` | `"gp2"` | no |
| hana_disks_usr_sap_storage_size | Size (GB) for `/usr/sap` volumes | `number` | `50` | no |
| ascs_instance_type | Instance type for SAP central services | `string` | `"m5.xlarge"` | no |
| as_instance_type | Instance type for application servers | `string` | `"m5.xlarge"` | no |
| as_instance_count | Number of application servers | `number` | `1` | no |
| efs_sapmnt | Provision EFS for `/sapmnt` | `bool` | `true` | no |
| efs_name | Name for the `/sapmnt` EFS file system | `string` | `"dir_sapmnt"` | no |
| sapmnt_volume_size | `/sapmnt` size (GB) for the non-EFS scenario (0 = none) | `number` | `0` | no |
| ascs_root_volume_size | Root volume size (GB) for ASCS | `number` | `50` | no |
| app_server_root_volume_size | Root volume size (GB) for app servers | `number` | `50` | no |

## Outputs

| Name | Description |
|------|-------------|
| hana_instance_ids | EC2 instance IDs of the HANA host(s) |
| hana_private_ips | Private IP addresses of the HANA host(s) |
| ascs_instance_ids | EC2 instance IDs of the ASCS host(s) |
| ascs_private_ips | Private IP addresses of the ASCS host(s) |
| app_instance_ids | EC2 instance IDs of the application server host(s) |
| app_private_ips | Private IP addresses of the application server host(s) |
| sapmnt_efs_id | EFS file system ID backing `/sapmnt` |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md). Please run `pre-commit run --all-files`
before opening a pull request.

## Security

See [SECURITY.md](./SECURITY.md) for how to report vulnerabilities.

## License

Licensed under the MIT-0 License. See [LICENSE](./LICENSE).
