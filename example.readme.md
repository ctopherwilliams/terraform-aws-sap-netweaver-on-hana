# Example: SAP NetWeaver on HANA Deployment

This repository ships a complete, runnable example under
[`examples/basic`](./examples/basic). Prefer that over the legacy snippet below.

## Requirements

- Terraform `>= 1.0`
- AWS provider `>= 3.0, < 4.0`

## How to deploy

1. Copy `examples/basic/terraform.tfvars.example` to
   `examples/basic/terraform.tfvars` and update the values for your environment.
2. From `examples/basic`:

```bash
terraform init    # initialize the working directory
terraform plan    # review the execution plan
terraform apply   # create the infrastructure
terraform destroy # tear it down when finished
```

You can also call the root module directly from your own configuration — see the
[Usage](./README.md#usage) section of the main README.
