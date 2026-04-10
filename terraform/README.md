# Terraform Layout

This directory contains reusable Terraform code and environment-specific roots for `dev` and `prod`.

## Structure

- `modules/sample_infra`: lightweight AWS infrastructure module (S3 bucket with secure defaults)
- `environments/dev`: root module and variables for development
- `environments/prod`: root module and variables for production

## Prerequisites

- Terraform `>= 1.6.0`
- AWS credentials configured locally (for manual runs)
- `tflint` (optional for local parity with CI checks)

## Local Workflow

### Development environment

```bash
cd terraform/environments/dev
terraform init
terraform fmt -recursive ../../
tflint --init && tflint --recursive ../../
terraform validate
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

### Production environment

```bash
cd terraform/environments/prod
terraform init
terraform fmt -recursive ../../
tflint --init && tflint --recursive ../../
terraform validate
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

## Cleanup

```bash
cd terraform/environments/dev
terraform destroy -var-file=dev.tfvars

cd ../prod
terraform destroy -var-file=prod.tfvars
```

Set unique bucket names in `dev.tfvars` and `prod.tfvars` before applying.
