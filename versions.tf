terraform {
  # Terraform 1.x is required. The module is written in HCL2 and uses
  # features available since the 1.0 release line.
  required_version = ">= 1.0"

  required_providers {
    # NOTE: The AWS provider is intentionally capped below v4.0. The S3
    # sub-module (modules/_internal-modules/storage/s3) still relies on the
    # inline `aws_s3_bucket` arguments that were removed in AWS provider v4.
    # Upgrading to v5/v6 requires splitting those into the dedicated
    # `aws_s3_bucket_*` resources first. See REHAUL_PLAYBOOK.md.
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0, < 6.53"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
    # The hashicorp/template provider is deprecated and unavailable for
    # darwin_arm64. It is still used by the ASCS sub-module via the
    # `template_file` data source. Migrate to the built-in `templatefile()`
    # function to drop this dependency (tracked in REHAUL_PLAYBOOK.md).
    template = {
      source  = "hashicorp/template"
      version = ">= 2.0"
    }
  }
}
