# Security Policy

## Reporting a Vulnerability

Please do **not** open a public GitHub issue for security vulnerabilities.

Instead, report suspected vulnerabilities privately using GitHub's
[private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
feature (the **"Report a vulnerability"** button under the repository's
**Security** tab), or by contacting the maintainer directly.

When reporting, please include:

- A description of the vulnerability and its impact
- Steps to reproduce
- The module version / commit affected
- Any suggested remediation

You can expect an initial response within a reasonable timeframe. Please give us
a chance to remediate before any public disclosure.

## Scope

This is Terraform infrastructure-as-code. The most relevant concerns are:

- Insecure defaults (unencrypted volumes, overly permissive security groups)
- Hardcoded secrets or credentials
- IAM policies broader than necessary

If you find any of the above, we treat it as a security issue.

## Secure defaults

- All EBS and EFS volumes are **encrypted** (AWS-managed key by default; supply
  `kms_key_arn` for a customer-managed key).
- EC2 instances enforce **IMDSv2** (`http_tokens = "required"`).
- The module targets the **AWS provider `>= 5.0`** (validated on v6) and Terraform
  `>= 1.0`, with no deprecated providers.

One finding is consciously accepted and documented in
[`.trivyignore`](./.trivyignore): SAP hosts use open egress for OS patching, SSM,
and SAP downloads. See [`REHAUL_PLAYBOOK.md`](./REHAUL_PLAYBOOK.md) for making
egress configurable.
