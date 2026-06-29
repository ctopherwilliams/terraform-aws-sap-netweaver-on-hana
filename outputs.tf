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

# HANA database tier
output "hana_instance_ids" {
  description = "EC2 instance IDs of the HANA host(s)"
  value       = module.hana_host.instance_ids
}

output "hana_private_ips" {
  description = "Private IP addresses of the HANA host(s)"
  value       = module.hana_host.server_private_ip
}

# ASCS tier
output "ascs_instance_ids" {
  description = "EC2 instance IDs of the ASCS host(s)"
  value       = module.sap_ascs_host.instance_ids
}

output "ascs_private_ips" {
  description = "Private IP addresses of the ASCS host(s)"
  value       = module.sap_ascs_host.server_private_ip
}

# Application server tier
output "app_instance_ids" {
  description = "EC2 instance IDs of the application server host(s)"
  value       = module.sap_app_host.instance_ids
}

output "app_private_ips" {
  description = "Private IP addresses of the application server host(s)"
  value       = module.sap_app_host.server_private_ip
}

# Shared storage
output "sapmnt_efs_id" {
  description = "EFS file system ID backing /sapmnt"
  value       = module.sap_efs.efs_file_system_id
}
