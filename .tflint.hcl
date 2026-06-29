config {
  call_module_type = "all"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "aws" {
  enabled = true
  version = "0.31.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# These two rules statically evaluate the conditional empty-string defaults
# (iam_instance_role / kms_key_arn resolve to "" when not supplied) and flag
# them as invalid. The values are intentionally optional and gated at runtime,
# so the warnings are false positives. Re-enable once those inputs are made
# non-optional or validated with explicit `validation` blocks.
rule "aws_iam_instance_profile_invalid_role" {
  enabled = false
}

rule "aws_efs_file_system_invalid_kms_key_id" {
  enabled = false
}
