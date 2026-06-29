# Repository Rehaul Playbook

This document has two parts:

1. **This repo's remaining work** — the deferred, higher-risk modernization items
   for `terraform-aws-sap-netweaver-on-hana`.
2. **A reusable checklist** — a generic process for bringing any dormant repo up
   to a "someone could evaluate and adopt this today" standard. Use it to rehaul
   the rest of the repositories under `github.com/ctopherwilliams`.

---

## Part 1 — Status & remaining work for this repo

### Done (AWS provider v5/v6 modernization)

- ✅ **AWS provider upgraded to `>= 5.0`** (validated on v6). The active module
  graph never used the v4-breaking S3 sub-module, so no resource rewrites were
  needed.
- ✅ **Removed the deprecated `hashicorp/template` provider** — the `template_file`
  data source was dead code; deleted it and dropped the provider.
- ✅ **gp3 defaults** for root, swap, `/usr/sap`, shared, and HANA data/log
  volumes. Sizing logic is now gp3-aware (non-`io1` SSD → general-purpose
  profile).
- ✅ **IMDSv2 enforced** on all EC2 instances.
- ✅ **Encryption-by-default** for all EBS and EFS volumes (AWS-managed key when
  no CMK is supplied), with null-safe `kms_key_id`.
- ✅ **Removed nine unused, non-SAP internal sub-modules** that did not build on
  the modern provider.
- ✅ **Wired through** previously-ignored root variables so they take effect.
- ✅ CI now validates every sub-module and example; `.trivyignore` documents the
  one accepted finding.

### Remaining enhancements

1. **Make instance egress configurable.** Outbound is currently open
   (`0.0.0.0/0`), which SAP hosts generally require for OS patching, SSM, and SAP
   downloads (accepted in `.trivyignore`). Expose an `egress_cidr_blocks`
   variable for operators running in fully private/proxied networks.
2. **Run the integration tests.** A Terratest harness (`test/`) and an on-demand
   `integration` workflow now apply `examples/basic`, assert outputs, and
   destroy. They self-skip until a test AWS account is wired up via the
   documented secrets (`AWS_ROLE_ARN`, `SAP_TEST_*`). Configure those secrets and
   run the workflow to get apply-time verification.
3. **Tagged Registry releases.** Publish semver tags so consumers can pin a
   version and adopt via the Terraform Registry.
4. **Reconcile `high_availability` vs `enable_ha`.** `main.tf` consumes only
   `enable_ha`; `high_availability` is retained (deprecated) for compatibility.
   Remove it in the next major release.
5. **gp3 IOPS/throughput tuning.** Defaults inherit the gp3 baseline
   (3000 IOPS / 125 MB/s). Expose tunables for HANA data/log if higher
   performance is required.

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
