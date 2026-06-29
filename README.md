# terraform-aws-sap-netweaver-on-hana

[![CI](https://github.com/ctopherwilliams/terraform-aws-sap-netweaver-on-hana/actions/workflows/ci.yml/badge.svg)](https://github.com/ctopherwilliams/terraform-aws-sap-netweaver-on-hana/actions/workflows/ci.yml)
[![Terraform](https://img.shields.io/badge/terraform-%3E%3D%201.0-7B42BC?logo=terraform)](https://www.terraform.io)
[![AWS Provider](https://img.shields.io/badge/aws--provider-%3E%3D%205.0-FF9900?logo=amazonaws)](https://registry.terraform.io/providers/hashicorp/aws/latest)
[![License: MIT-0](https://img.shields.io/badge/license-MIT--0-blue.svg)](./LICENSE)

Provision the complete AWS infrastructure for an **SAP NetWeaver on HANA**
landscape with a single Terraform module — the HANA database tier, the ASCS
(central services) tier, the application-server tier, and the shared `/sapmnt`
storage that ties them together. Built for production: secure-by-default,
cost-aware, composable, and verified on the latest AWS provider in CI.

> **What this module does and does not do.** It provisions the *infrastructure*
> (compute, storage, networking, IAM) that SAP NetWeaver and HANA are installed
> onto. It does **not** install the SAP software itself — bring a SAP-certified
> OS AMI and run your installation tooling (e.g. SWPM, Ansible) afterwards.

## Table of contents

- [Highlights](#highlights)
- [What it creates](#what-it-creates)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick start](#quick-start)
- [Consuming the module](#consuming-the-module)
- [Configuration recipes](#configuration-recipes)
- [Sub-modules](#sub-modules)
- [Development](#development)
- [Roadmap](#roadmap)
- [Requirements / Inputs / Outputs](#requirements)
- [Contributing](#contributing) · [Security](#security) · [License](#license)

## Highlights

- **Modern toolchain** — Terraform `>= 1.0`, AWS provider `>= 5.0`; validated on
  the latest provider in CI, with no deprecated providers or functions.
- **Secure by default** — every EBS and EFS volume is encrypted, EC2 enforces
  **IMDSv2**, SSH is optional (SSM Session Manager works out of the box), and a
  customer-managed KMS key is a one-line opt-in.
- **Cost-aware** — EBS volumes default to **gp3** (cheaper and faster than gp2).
- **Composable** — HANA, ASCS, application-server, and `/sapmnt` EFS tiers are
  independent sub-modules you can adopt individually.
- **Production patterns built in** — high availability, HANA scale-out, EC2
  auto-recovery, private Route53 DNS, and consistent tagging.
- **CI-verified** — every module *and* example is `fmt` / `validate` / `tflint`
  checked and scanned with Trivy on every push.

## What it creates

For each SAP tier, the module can create:

- [EC2 instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) with [auto-recovery](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-recover.html) and [IMDSv2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html)
- [EBS volumes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_volume), [encrypted](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSEncryption.html) and gp3 by default, laid out per the SAP component
- [Security groups](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) with configurable egress
- [IAM roles & instance profiles](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) (SSM-enabled by default)
- An [EFS file system](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) for `/sapmnt` (encrypted)
- Optional [Route53 DNS records](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) in a private zone
- Consistent resource [tagging](./modules/_internal-modules/common/tagging)

## Architecture

```text
                          ┌──────────────────────────────┐
                          │   EFS  —  /sapmnt (shared)    │   ← encrypted
                          └───────────────┬──────────────┘
                                          │  NFS
        ┌──────────────────┬──────────────┼──────────────────┐
        │                  │              │                  │
 ┌──────▼───────┐  ┌───────▼──────┐  ┌────▼───────┐  ┌───────▼──────┐
 │   HANA DB    │  │     ASCS     │  │  App srv 1 │  │  App srv N   │
 │   host(s)    │  │    host(s)   │  │            │  │              │
 │ data/log/bkp │  │  + optional  │  │            │  │              │
 │  EBS (gp3)   │  │     HA pair  │  │            │  │              │
 └──────────────┘  └──────────────┘  └────────────┘  └──────────────┘
   IMDSv2 · encrypted EBS · SSM-enabled IAM role · private Route53 DNS (optional)
```

## Prerequisites

- **Terraform** `>= 1.0` and the **AWS provider** `>= 5.0`.
- An **AWS account** with permissions to create EC2, EBS, EFS, IAM, Route53, and
  security-group resources.
- An existing **VPC and subnets** (the module deploys into them; it does not
  create networking).
- A **SAP-certified OS AMI** (SLES for SAP / RHEL for SAP) for the `ami_id` input.
- A HANA-certified **instance type** (e.g. `r5.*`, `r6i.*`, `x2idn.*`) — disk
  sizing is derived from it.
- *(Optional)* a **KMS key** for customer-managed encryption and a **Route53
  private hosted zone** for DNS records.

## Quick start

```bash
git clone https://github.com/ctopherwilliams/terraform-aws-sap-netweaver-on-hana
cd terraform-aws-sap-netweaver-on-hana/examples/basic

cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your VPC, subnets, AMI, SID, ...

terraform init
terraform plan      # review what will be created
terraform apply
```

See [`examples/basic`](./examples/basic) for the complete, runnable example.

## Consuming the module

Reference it directly from Git and pin a ref:

```hcl
module "sap_netweaver_on_hana" {
  source = "git::https://github.com/ctopherwilliams/terraform-aws-sap-netweaver-on-hana.git?ref=master"

  aws_region       = "us-east-1"
  application_code = "ecc"
  application_name = "ecc"
  environment_type = "prod"

  # Networking
  vpc_id        = "vpc-0123456789abcdef0"
  subnet_ids    = ["subnet-aaaa", "subnet-bbbb"]
  dns_zone_name = "sap.internal" # leave "" to skip DNS records

  # Operating system
  ami_id  = "ami-0123456789abcdef0" # SAP-certified SLES/RHEL AMI
  ssh_key = ""                      # empty => use SSM Session Manager

  # Security
  kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/abc..." # recommended

  # SAP
  sid                = "ECC"
  hana_instance_type = "r5.2xlarge"

  # NetWeaver application tier
  ascs_instance_type = "m5.xlarge"
  as_instance_type   = "m5.xlarge"
  as_instance_count  = 2
}
```

> **Tip:** pin `?ref=` to a tag or commit SHA rather than `master` so upgrades
> are deliberate.

## Configuration recipes

**High availability** — provision a second HANA and ASCS instance:

```hcl
enable_ha = true
```

**HANA scale-out** — multiple HANA nodes backed by a shared EFS file system:

```hcl
hana_is_scale_out         = true
hana_scale_out_node_count = 4
```

**Customer-managed encryption** — supply a KMS key (volumes are encrypted either
way; this switches them from the AWS-managed key to yours):

```hcl
kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/abc..."
```

**Restrict outbound traffic** — egress defaults to all destinations (SAP hosts
generally need it for patching, SSM, and SAP downloads). Lock it down for
private/proxied networks:

```hcl
instance_egress_cidr_blocks = ["10.0.0.0/8"]
```

**Tune HANA storage** — choose volume types and sizes (data/log accept
`gp3`, `gp2`, or `io1`):

```hcl
hana_disks_data_storage_type = "io1"
hana_disks_shared_size       = "1024"
```

## Sub-modules

Each tier is an independent module you can reuse on its own:

| Module | Purpose |
|--------|---------|
| [`aws-sap-hana-host`](./modules/aws-sap-hana-host)         | HANA database instance(s) and their EBS layout |
| [`aws-sap-ascs-host`](./modules/aws-sap-ascs-host)         | ASCS / central services instance(s) |
| [`aws-sap-app-host`](./modules/aws-sap-app-host)           | NetWeaver application server instance(s) |
| [`aws-sap-netweaver-efs`](./modules/aws-sap-netweaver-efs) | Shared EFS file system for `/sapmnt` |

## Development

```bash
# format, validate and lint
terraform fmt -recursive
terraform init -backend=false
terraform validate
tflint --recursive

# or run every check the way CI does
pre-commit install
pre-commit run --all-files
```

CI runs `terraform fmt`, `validate` (root, **every sub-module, and every
example**), `tflint`, a Trivy IaC scan, and a `terraform-docs` drift check on
every push and pull request (see
[`.github/workflows/ci.yml`](./.github/workflows/ci.yml)).

## Roadmap

The major modernization is complete — AWS provider v5/v6 support, removal of the
deprecated `template` provider, gp3 defaults, encryption-by-default, IMDSv2
enforcement, and configurable egress have all shipped. Remaining enhancements are
tracked in [`REHAUL_PLAYBOOK.md`](./REHAUL_PLAYBOOK.md):

- `terraform plan` based integration tests against a real AWS account.
- Publish tagged releases to the Terraform Registry.
- Expose gp3 IOPS / throughput tunables for HANA data and log volumes.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_null"></a> [null](#requirement\_null) | >= 3.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0 |

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
| <a name="input_hana_disks_data_storage_type"></a> [hana\_disks\_data\_storage\_type](#input\_hana\_disks\_data\_storage\_type) | (Optional) EBS Volume type for hana data volumes. Can be gp3, gp2 or io1 | `string` | `"gp3"` | no |
| <a name="input_hana_disks_logs_storage_type"></a> [hana\_disks\_logs\_storage\_type](#input\_hana\_disks\_logs\_storage\_type) | (Optional) EBS Volume type for hana log volumes. Can be gp3, gp2 or io1 | `string` | `"gp3"` | no |
| <a name="input_hana_disks_shared_size"></a> [hana\_disks\_shared\_size](#input\_hana\_disks\_shared\_size) | (Optional) Size in GBs for the hana shared volumes of the instances | `string` | `"512"` | no |
| <a name="input_hana_disks_shared_storage_type"></a> [hana\_disks\_shared\_storage\_type](#input\_hana\_disks\_shared\_storage\_type) | (Optional) EBS Volume type for hana shared volumes. | `string` | `"gp3"` | no |
| <a name="input_hana_disks_usr_sap_storage_size"></a> [hana\_disks\_usr\_sap\_storage\_size](#input\_hana\_disks\_usr\_sap\_storage\_size) | (Optional) Size in GBs for the /usr/sap volumes of the instances | `number` | `50` | no |
| <a name="input_hana_disks_usr_sap_storage_type"></a> [hana\_disks\_usr\_sap\_storage\_type](#input\_hana\_disks\_usr\_sap\_storage\_type) | (Optional) EBS Volume type for hana /usr/sap volumes. | `string` | `"gp3"` | no |
| <a name="input_hana_instance_type"></a> [hana\_instance\_type](#input\_hana\_instance\_type) | (Required) Identifies the instance types to be used for HANA. Should be from the list of certified instances, since the disk sizing is done based on this | `string` | n/a | yes |
| <a name="input_hana_is_scale_out"></a> [hana\_is\_scale\_out](#input\_hana\_is\_scale\_out) | (Optional) Defines whether Shared disk should be create as an EFS file system | `bool` | `false` | no |
| <a name="input_hana_scale_out_node_count"></a> [hana\_scale\_out\_node\_count](#input\_hana\_scale\_out\_node\_count) | (Required, if hana\_is\_scale\_out = false) Defines how many nodes required for scale-out scenario | `number` | `3` | no |
| <a name="input_high_availability"></a> [high\_availability](#input\_high\_availability) | (Deprecated) Retained for backwards compatibility. High availability is controlled by `enable_ha`, which is the variable actually consumed by the module | `bool` | `false` | no |
| <a name="input_iam_instance_role"></a> [iam\_instance\_role](#input\_iam\_instance\_role) | (Optional) The IAM role name to be attached to instance profile | `string` | `""` | no |
| <a name="input_instance_egress_cidr_blocks"></a> [instance\_egress\_cidr\_blocks](#input\_instance\_egress\_cidr\_blocks) | (Optional) CIDR blocks the SAP instances may send outbound traffic to. Defaults to all destinations, which SAP hosts typically require for OS patching, SSM Session Manager, and SAP software downloads. Restrict this for private/proxied networks. | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | (Optional) ARN of a customer-managed KMS key used to encrypt EBS and EFS volumes. Volumes are always encrypted; if left empty the AWS-managed key is used. Supplying a customer-managed key is recommended | `string` | `""` | no |
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

## Acknowledgements

This module began as an AWS-authored sample for deploying SAP on AWS and has been
substantially modernized — AWS provider v5/v6 support, security hardening, gp3
defaults, CI, and documentation. See [`CHANGELOG.md`](./CHANGELOG.md) for the full
history.
