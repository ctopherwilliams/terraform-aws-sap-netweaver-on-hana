# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Configurable instance egress** via `instance_egress_cidr_blocks` (root) and
  `egress_cidr_blocks` (host sub-modules); defaults to the existing open behavior.
- **Terratest integration-test harness** under `test/` and an on-demand
  `integration` CI workflow that applies `examples/basic` against a real AWS
  account, asserts outputs, and destroys (runs when AWS credentials/secrets are
  configured; self-skips otherwise).
- World-class README (value proposition, table of contents, prerequisites, quick
  start, configuration recipes, acknowledgements).

## [2.0.0] - 2026-06-29

### AWS provider v5/v6 modernization

#### Changed (potentially breaking)
- **Bumped the AWS provider constraint to `>= 5.0`** (validated on v6) and
  `null`/`random` to `>= 3.0`. The active module graph never used the v4-breaking
  S3 sub-module, so the upgrade required no resource rewrites.
- **EBS/EFS volumes are now always encrypted** (previously only when a KMS key
  was supplied). Without a customer-managed key the AWS-managed key is used.
  `kms_key_id` is now null-safe. Volume `encrypted`/`kms_key_id` remain under
  `ignore_changes`, so existing deployments are not disturbed.
- **EBS volume types default to `gp3`** (was `gp2`) for root, swap, `/usr/sap`,
  shared, and HANA data/log volumes. The HANA data/log sizing logic now treats
  any non-`io1` SSD type via the general-purpose profile (this also fixes a bug
  where a map was compared to the string `"io1"`).
- **Removed nine unused, non-SAP internal sub-modules** (`alb`, `alb-acm`,
  `nlb`, `dynamodb`, `s3`, `monitoring/*`, `systems-manager/*`). They were not
  referenced by the SAP solution and did not build on the modern AWS provider.

#### Added
- **IMDSv2 is now enforced** on all EC2 instances (`http_tokens = "required"`).
- Root variables that were previously declared but never passed through
  (`ssh_key`, `user_data`, `root_volume_size`, the `hana_disks_*` types/sizes,
  `ascs_instance_type`, `as_instance_type`, the per-tier root-volume sizes,
  `sapmnt_volume_size`, `efs_sapmnt`) are now **wired into the sub-modules**, so
  setting them actually takes effect.
- `.trivyignore` documenting the one consciously accepted finding (open egress).
- CI now validates **every sub-module and example**, not just the root.

#### Fixed
- Replaced the deprecated `data.aws_region.current.name` with `.region`.
- Removed the dead `template_file` data source and dropped the deprecated
  `hashicorp/template` provider entirely.
- ASCS instances now receive the `ssh_key` input (it was silently dropped).

## [Conservative baseline]

### Added
- `versions.tf` with `required_version` and pinned `required_providers`
  (`aws >= 3.0, < 4.0`, `null`, `random`, `template`).
- Root-level `outputs.tf` exposing HANA / ASCS / application-server instance IDs
  and private IPs, plus the `/sapmnt` EFS file system ID.
- Continuous integration (`.github/workflows/ci.yml`): `terraform fmt`,
  `validate`, `tflint`, a Trivy IaC scan, and a `terraform-docs` drift check.
- Tooling config: `.gitignore`, `.editorconfig`, `.tflint.hcl`,
  `.pre-commit-config.yaml`, and Dependabot.
- Community health files: `SECURITY.md`, issue templates, and a pull-request
  template.
- A complete, runnable example under `examples/basic`.
- `REHAUL_PLAYBOOK.md` documenting the remaining modernization work and a
  reusable checklist for other repositories.

### Changed
- Modernized `README.md` with badges, usage, an architecture diagram, and full
  inputs/outputs tables.
- Rewrote `variables.tfvars.sample` and `example.readme.md` to be valid and to
  point at `examples/basic`.

### Fixed
- Replaced the `map()` function (removed in Terraform 0.12+) with `tomap({...})`
  throughout, so the module validates on modern Terraform.
- Corrected the `dns_zone_name` variable, whose default mistakenly held the
  description text (which would have caused a spurious Route53 zone lookup); the
  default is now `""`.
- Added missing `type` constraints and descriptions to several root variables.
- Applied `terraform fmt` across the codebase.

### Removed
- Stray, misnamed `modules/aws-sap-hana-host/test.md` duplicate documentation.
