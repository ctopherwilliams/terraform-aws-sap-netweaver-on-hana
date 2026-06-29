# Repository Rehaul Playbook

This document has two parts:

1. **This repo's remaining work** — the deferred, higher-risk modernization items
   for `terraform-aws-sap-netweaver-on-hana`.
2. **A reusable checklist** — a generic process for bringing any dormant repo up
   to a "someone could evaluate and adopt this today" standard. Use it to rehaul
   the rest of the repositories under `github.com/ctopherwilliams`.

---

## Part 1 — Remaining work for this repo

The first-pass overhaul intentionally avoided changes that alter resource
behavior and require a real `terraform apply` to verify. Those are tracked here.

### 1. Upgrade the AWS provider to v5/v6  *(high value, breaking)*

Currently pinned to `>= 3.0, < 4.0`. The blocker is the S3 sub-module
(`modules/_internal-modules/storage/s3`), which uses inline `aws_s3_bucket`
arguments (ACL, versioning, SSE, lifecycle) that were **removed in AWS provider
v4**. Upgrading requires:

- Splitting those into dedicated resources: `aws_s3_bucket_acl`,
  `aws_s3_bucket_versioning`, `aws_s3_bucket_server_side_encryption_configuration`,
  `aws_s3_bucket_lifecycle_configuration`, `aws_s3_bucket_public_access_block`.
- Reviewing every other resource for v4/v5/v6 deprecations.
- Running `terraform plan`/`apply` against a real account to confirm no
  destructive diffs.

### 2. Drop the deprecated `hashicorp/template` provider

`modules/aws-sap-ascs-host/data.tf` uses `data "template_file"`. The provider is
archived and unavailable on `darwin_arm64` (Apple Silicon). Replace with the
built-in [`templatefile()`](https://developer.hashicorp.com/terraform/language/functions/templatefile)
function and remove `template` from `required_providers`.

### 3. Default EBS volume types `gp2` -> `gp3`

`gp3` is cheaper and faster. Update the `hana_disks_*_storage_type` defaults and
the hardcoded `gp2` swap volumes. Verify IOPS/throughput defaults are adequate
for HANA.

### 4. Enforce IMDSv2

Add a `metadata_options { http_tokens = "required" }` block to the EC2 instance
resource in `modules/_internal-modules/compute/ec2-instance-linux`.

### 5. Make `tflint` and the Trivy scan blocking

They run as informational in CI today. Once the findings above are cleared,
remove `continue-on-error` so they gate merges.

### 6. Reconcile `high_availability` vs `enable_ha`

`main.tf` only consumes `enable_ha`; `high_availability` is declared but unused.
Either wire it up or remove it in a tagged major release with a note in the
changelog.

---

## Part 2 — Reusable rehaul checklist for any repo

Work top-to-bottom. Skip what does not apply to the repo's language/stack.

### Hygiene & metadata
- [ ] Add/refresh `README.md`: one-line description, badges, install/usage,
      requirements, examples, license. Lead with what it does and how to use it.
- [ ] Add `LICENSE` if missing; confirm it matches the README's stated license.
- [ ] Add `.gitignore` appropriate to the stack (state files, build output, env).
- [ ] Add `.editorconfig` for consistent whitespace.
- [ ] Add `CHANGELOG.md` (Keep a Changelog format).
- [ ] Add `SECURITY.md` with private vulnerability-reporting instructions.
- [ ] Add `CONTRIBUTING.md` and a `CODE_OF_CONDUCT.md`.
- [ ] Add issue templates and a pull-request template under `.github/`.
- [ ] Update the repo description and topics on GitHub for discoverability.
- [ ] Archive the repo instead of rehauling it if it is truly dead — be honest.

### Dependencies & versions
- [ ] Pin language/runtime and dependency versions explicitly.
- [ ] Bump dependencies to supported releases; note breaking ones in the changelog.
- [ ] Add Dependabot (`.github/dependabot.yml`) for automated updates.
- [ ] Remove deprecated/abandoned dependencies.

### Correctness & quality
- [ ] Make the project build/validate from a clean checkout. Document the steps.
- [ ] Run the formatter and linter; fix or suppress findings deliberately.
- [ ] Fix removed/deprecated API or function usage so it runs on current tooling.
- [ ] Add or repair a minimal test/example that actually executes.

### Automation (CI)
- [ ] Add a CI workflow: format check, build/validate, lint, tests, security scan.
- [ ] Keep first-pass-noisy checks non-blocking; tighten once the backlog clears.
- [ ] Add a status badge to the README so health is visible at a glance.
- [ ] Add `pre-commit` config mirroring the CI checks for fast local feedback.

### Security
- [ ] Scan for committed secrets; rotate anything exposed and purge from history.
- [ ] Run a static/IaC security scanner (Trivy, Checkov, CodeQL, Bandit, etc.).
- [ ] Review default permissions/exposure for insecure defaults.

### Release
- [ ] Tag a release (semver) so consumers can pin a version.
- [ ] For Terraform modules, publish to the Terraform Registry (tag `vX.Y.Z`).
- [ ] Write release notes from the changelog.

### Per-repo tips by stack
- **Terraform**: `versions.tf` with `required_providers`; `terraform-docs`;
  `tflint` + `trivy`; `examples/` dir; cap provider versions you have verified.
- **Node**: lockfile committed; `engines` set; `npm audit`; ESLint + Prettier.
- **Python**: pin via `pyproject.toml`; `ruff`/`black`; `pytest`; `pip-audit`.
- **Go**: `go.mod` tidy; `golangci-lint`; `go test ./...`; `govulncheck`.

> **Scope note:** A single Claude Code web session is scoped to one repository.
> To apply this across all your repos, start a separate session per repo (or run
> these steps locally), using this checklist as the script.
