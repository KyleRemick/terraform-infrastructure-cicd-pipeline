# terraform-infrastructure-cicd-pipeline

A standalone Terraform and GitHub Actions project that demonstrates safe, environment-aware CI/CD delivery to AWS using OpenID Connect (OIDC).

## Project Purpose

This repository focuses on practical infrastructure delivery discipline:

- Pull request validation for Terraform changes
- Automated development deployment on `main`
- Manually controlled production deployment
- AWS authentication through short-lived OIDC credentials

The infrastructure target is intentionally small (S3 with secure defaults) so the delivery pattern is the central focus.

## Repository Structure

```text
.
├── .github/workflows/
│   ├── terraform-pr-checks.yml
│   ├── terraform-dev-deploy.yml
│   └── terraform-prod-deploy.yml
├── terraform/
│   ├── environments/
│   │   ├── dev/
│   │   └── prod/
│   ├── modules/
│   │   └── sample_infra/
│   ├── versions.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── docs/
│   └── architecture.md
├── .gitignore
├── README.md
└── LICENSE
```

## CI/CD Workflows

### 1) Pull Request Checks

Workflow: `.github/workflows/terraform-pr-checks.yml`

Runs on pull requests to `main` and executes:

- `tflint` static analysis
- `terraform fmt -check -recursive`
- `terraform init`
- `terraform validate`
- `terraform plan` (for non-fork PRs where OIDC auth is available)

Checks run for both `dev` and `prod` environment roots.

### 2) Development Deployment

Workflow: `.github/workflows/terraform-dev-deploy.yml`

- Triggered on pushes to `main` and `workflow_dispatch`
- Runs `init`, `validate`, `plan`, then `apply` for `dev`
- Intended for continuous delivery in development

### 3) Production Deployment

Workflow: `.github/workflows/terraform-prod-deploy.yml`

- Triggered only by `workflow_dispatch`
- Runs through `init`, `validate`, `plan`, and applies saved plan output
- Uses GitHub `production` environment for approval and controls
- Designed to run only after explicit maintainer approval and branch protection policies

## AWS OIDC Setup (High Level)

Use OIDC federation to avoid long-lived static credentials in GitHub.

1. Create an IAM OIDC provider for `token.actions.githubusercontent.com` (once per AWS account).
2. Create IAM roles for GitHub Actions:
   - `AWS_ROLE_ARN_DEV` role for development deployments
   - `AWS_ROLE_ARN_PROD` role for production deployments
3. In each role trust policy, constrain access by repository and branch/environment.
4. Add role ARNs as GitHub repository/environment secrets:
   - `AWS_ROLE_ARN_DEV`
   - `AWS_ROLE_ARN_PROD`
5. In GitHub, configure environments:
   - `development`
   - `production` (enable required reviewers for manual approval)
6. In each workflow, keep `permissions` minimal and include `id-token: write` only where OIDC role assumption is required.

Example trust policy pattern (replace placeholders):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:<ORG_OR_USER>/<REPO_NAME>:ref:refs/heads/main",
            "repo:<ORG_OR_USER>/<REPO_NAME>:environment:production"
          ]
        }
      }
    }
  ]
}
```

## Local Terraform Commands

### Development

```bash
cd terraform/environments/dev
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

### Production

```bash
cd terraform/environments/prod
terraform init
terraform fmt -recursive
terraform validate
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

Before apply, update bucket names in:

- `terraform/environments/dev/dev.tfvars`
- `terraform/environments/prod/prod.tfvars`

Bucket names must be globally unique in AWS.

## Cleanup and Destroy

To remove deployed resources:

```bash
cd terraform/environments/dev
terraform destroy -var-file=dev.tfvars

cd ../prod
terraform destroy -var-file=prod.tfvars
```

By default, `dev` allows easier cleanup (`force_destroy = true`) while `prod` is stricter (`force_destroy = false`).

## Future Improvements

- move to remote Terraform state with S3 + DynamoDB locking
- add additional policy checks (e.g., `tfsec`, `checkov`)
- add reusable composite actions for common Terraform steps
- split plan and apply into separate jobs with artifact handoff

## CI Troubleshooting

- `AccessDenied` or `Not authorized to perform sts:AssumeRoleWithWebIdentity`: verify role trust policy `sub` and `aud` conditions match repository, branch, and environment names exactly.
- Plan skipped on PR: if the PR comes from a fork, OIDC role assumption is intentionally skipped for safety.
- `BucketAlreadyExists`: update `bucket_name` in tfvars to a globally unique value.
- Prod workflow waiting: check GitHub `production` environment required reviewers and approve the run.
