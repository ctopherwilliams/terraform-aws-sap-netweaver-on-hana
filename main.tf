/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

module "sap_efs" {
  source = "./modules/aws-sap-netweaver-efs"
  # The EFS security group is always created so the ASCS/app tiers can
  # reference it; only the /sapmnt file system itself is gated by efs_sapmnt.
  enabled = var.enabled && var.efs_sapmnt

  kms_key_arn = var.kms_key_arn

  aws_region = var.aws_region

  subnet_ids         = var.subnet_ids
  vpc_id             = var.vpc_id
  security_group_ids = concat(module.sap_ascs_host.security_group_id, module.sap_app_host.security_group_id)
  name               = var.efs_name

  application_code = lower(var.application_code)
  environment      = lower(var.environment_type)
  application_name = lower(var.application_name)
}


module "hana_host" {
  source = "./modules/aws-sap-hana-host"

  # Instance Count depending on the environment
  instance_count = var.hana_is_scale_out ? (var.enable_ha ? 2 * var.hana_scale_out_node_count : var.hana_scale_out_node_count) : (var.enable_ha ? 2 : 1)
  instance_type  = var.hana_instance_type

  is_scale_out = var.hana_is_scale_out

  enabled = var.enabled
  ami_id  = var.ami_id

  # General

  # KMS Key for EBS Volumes Encryption
  kms_key_arn = var.kms_key_arn

  # Networking
  vpc_id = var.vpc_id

  # The list of subnets to deploy the instances
  subnet_ids = var.subnet_ids
  # The Route53 private Zone name to create the host entry
  dns_zone_name = var.dns_zone_name
  # The CIDR block for the onPremise Network
  customer_cidr_blocks = var.customer_cidr_blocks
  # The default security group to be added
  customer_default_sg_id = var.customer_default_sg_id

  # Operating system
  ssh_key   = var.ssh_key
  user_data = var.user_data

  # Networking (egress)
  egress_cidr_blocks = var.instance_egress_cidr_blocks

  # Storage
  root_volume_size                = var.root_volume_size
  hana_disks_data_storage_type    = var.hana_disks_data_storage_type
  hana_disks_logs_storage_type    = var.hana_disks_logs_storage_type
  hana_disks_backup_storage_type  = var.hana_disks_backup_storage_type
  hana_disks_shared_storage_type  = var.hana_disks_shared_storage_type
  hana_disks_shared_size          = var.hana_disks_shared_size
  hana_disks_usr_sap_storage_type = var.hana_disks_usr_sap_storage_type
  hana_disks_usr_sap_storage_size = var.hana_disks_usr_sap_storage_size

  # Instance Role
  iam_instance_role = var.default_instance_role ? "" : var.iam_instance_role

  # Tags
  application_code = lower(var.application_code)
  environment      = lower(var.environment_type)
  application_name = lower(var.application_name)

  # SAP
  sid = var.sid
}

module "sap_ascs_host" {
  source  = "./modules/aws-sap-ascs-host"
  enabled = var.enabled

  # Instance Count depending on the environment
  instance_count = var.enable_ha ? 2 : 1
  instance_type  = var.ascs_instance_type

  # General
  ami_id      = var.ami_id
  kms_key_arn = var.kms_key_arn

  # Operating system
  ssh_key   = var.ssh_key
  user_data = var.user_data

  # Networking (egress)
  egress_cidr_blocks = var.instance_egress_cidr_blocks

  # Storage
  root_volume_size   = var.ascs_root_volume_size
  sapmnt_volume_size = var.sapmnt_volume_size

  # Networking
  vpc_id = var.vpc_id
  # The list of subnets to deploy the instances
  subnet_ids = var.subnet_ids
  # The Route53 private Zone name to create the host entry
  dns_zone_name = var.dns_zone_name
  # The CIDR block for the onPremise Network
  customer_default_sg_ids = var.customer_default_sg_id
  # The default security group to be added
  efs_security_group_id = module.sap_efs.security_group_id

  # Instance Role
  iam_instance_role = var.default_instance_role ? "" : var.iam_instance_role

  # Tags
  application_code = lower(var.application_code)
  environment      = lower(var.environment_type)
  application_name = lower(var.application_name)
  # SAP
  sid = var.sid
}


module "sap_app_host" {
  source  = "./modules/aws-sap-app-host"
  enabled = var.enabled

  # Instance Count depending on the environment
  instance_count = var.as_instance_count
  instance_type  = var.as_instance_type

  # General
  ami_id      = var.ami_id
  kms_key_arn = var.kms_key_arn

  # Operating system
  ssh_key   = var.ssh_key
  user_data = var.user_data

  # Networking (egress)
  egress_cidr_blocks = var.instance_egress_cidr_blocks

  # Storage
  root_volume_size = var.app_server_root_volume_size

  # Networking
  vpc_id = var.vpc_id
  # The list of subnets to deploy the instances
  subnet_ids = var.subnet_ids
  # The Route53 private Zone name to create the host entry
  dns_zone_name = var.dns_zone_name
  # The CIDR block for the onPremise Network
  customer_default_sg_ids = var.customer_default_sg_id
  # The default security group to be added
  efs_security_group_id = module.sap_efs.security_group_id

  # Instance Role
  iam_instance_role = var.default_instance_role ? "" : var.iam_instance_role

  # Tags
  application_code = lower(var.application_code)
  environment      = lower(var.environment_type)
  application_name = lower(var.application_name)
  # SAP
  sid = var.sid
}