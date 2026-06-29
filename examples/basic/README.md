# Basic example — SAP NetWeaver on HANA

A minimal, single-AZ, non-HA deployment of the module.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your VPC, subnets, AMI, etc.

terraform init
terraform plan
terraform apply
```

To tear everything down:

```bash
terraform destroy
```

> This example provisions real, billable AWS resources (EC2, EBS, EFS). Review
> the plan before applying and destroy when you are done.
