# Integration tests

[Terratest](https://terratest.gruntwork.io/) integration tests that **apply the
`examples/basic` configuration against a real AWS account**, assert the module's
outputs, and then destroy everything.

> ⚠️ **These tests create real, billable AWS resources** (EC2, EBS, EFS). They
> only run when the required environment variables are set; otherwise each test
> calls `t.Skip`.

## Prerequisites

- Go `>= 1.23`
- AWS credentials in the environment (e.g. `AWS_PROFILE`, an assumed role, or
  GitHub OIDC in CI)
- A throwaway VPC, subnets, and a SAP-certified AMI to deploy into

## Required environment variables

| Variable              | Example                          | Notes                          |
|-----------------------|----------------------------------|--------------------------------|
| `AWS_REGION`          | `us-east-1`                      | Defaults to `us-east-1`        |
| `SAP_TEST_VPC_ID`     | `vpc-0123456789abcdef0`          | Required                       |
| `SAP_TEST_SUBNET_IDS` | `subnet-aaaa,subnet-bbbb`        | Comma-separated, required      |
| `SAP_TEST_AMI_ID`     | `ami-0123456789abcdef0`          | SAP-certified AMI, required    |
| `SAP_TEST_SID`        | `ECC`                            | Required                       |

## Running locally

```bash
cd test
export AWS_REGION=us-east-1
export SAP_TEST_VPC_ID=vpc-...
export SAP_TEST_SUBNET_IDS=subnet-aaaa,subnet-bbbb
export SAP_TEST_AMI_ID=ami-...
export SAP_TEST_SID=ECC

go test -v -timeout 60m ./...
```

## Running in CI

The [`integration`](../.github/workflows/integration.yml) workflow runs these
tests on demand (`workflow_dispatch`). Configure the inputs above as repository
**secrets** and provide AWS credentials via an OIDC role (recommended) or access
keys. The workflow skips gracefully if the secrets are absent.
