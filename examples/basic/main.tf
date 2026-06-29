terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Minimal single-AZ, non-HA SAP NetWeaver on HANA deployment.
# Copy terraform.tfvars.example to terraform.tfvars and fill in your values.
module "sap_netweaver_on_hana" {
  source = "../../"

  aws_region       = var.aws_region
  application_code = "ecc"
  application_name = "ecc"
  environment_type = "dev"

  # Networking
  vpc_id        = var.vpc_id
  subnet_ids    = var.subnet_ids
  dns_zone_name = var.dns_zone_name

  # OS
  ami_id  = var.ami_id
  ssh_key = var.ssh_key

  # Security
  kms_key_arn           = var.kms_key_arn
  default_instance_role = true

  # SAP
  sid       = var.sid
  enable_ha = false

  # HANA
  hana_is_scale_out  = false
  hana_instance_type = var.hana_instance_type

  # NetWeaver application tier
  ascs_instance_type = "m5.xlarge"
  as_instance_type   = "m5.xlarge"
  as_instance_count  = 1
  efs_sapmnt         = true
}
