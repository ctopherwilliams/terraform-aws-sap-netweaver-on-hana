# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project aims to
follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
