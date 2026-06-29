variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "VPC to deploy the SAP infrastructure into"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for instance placement"
  type        = list(string)
}

variable "dns_zone_name" {
  description = "Route53 private hosted zone name (leave empty to skip DNS records)"
  type        = string
  default     = ""
}

variable "ami_id" {
  description = "AMI ID for the SAP-certified operating system"
  type        = string
}

variable "ssh_key" {
  description = "EC2 key pair name (leave empty to rely on SSM Session Manager)"
  type        = string
  default     = ""
}

variable "kms_key_arn" {
  description = "KMS key ARN used to encrypt EBS/EFS volumes (recommended)"
  type        = string
  default     = ""
}

variable "sid" {
  description = "SAP System ID"
  type        = string
}

variable "hana_instance_type" {
  description = "SAP-certified instance type for HANA"
  type        = string
  default     = "r5.2xlarge"
}
