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

## Provider versions

This module currently pins the AWS provider to `>= 3.0, < 4.0`. See
[`REHAUL_PLAYBOOK.md`](./REHAUL_PLAYBOOK.md) for the planned upgrade path to
modern provider versions.
