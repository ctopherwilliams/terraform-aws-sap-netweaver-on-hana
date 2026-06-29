---
name: Bug report
about: Report a problem with the module
title: "[BUG] "
labels: bug
---

## Describe the bug

A clear and concise description of what the bug is.

## Module version

<!-- e.g. a git tag, release, or commit SHA -->

## Terraform & provider versions

```
terraform version
```

- Terraform:
- AWS provider:

## To reproduce

Relevant module call / `.tfvars` (redact secrets):

```hcl
module "sap" {
  source = "..."
  # ...
}
```

## Expected behavior

What you expected to happen.

## Actual behavior

What actually happened, including the relevant `terraform plan`/`apply` output (redact secrets).

## Additional context

Anything else that helps us reproduce or understand the issue.
