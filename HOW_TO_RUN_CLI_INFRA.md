# How to Run Infrastructure Checks with CLI Scripts

## Why Use CLI Scripts?
Due to IAM restrictions for the test assignment user, it is not possible to run full Terraform apply/destroy workflows (for example, due to lack of permissions for ec2:DescribeAvailabilityZones and prevent_destroy). To demonstrate infrastructure provisioning and teardown, we provide bash scripts that use AWS CLI to create and delete all core resources.

## Prerequisites
- AWS CLI installed and configured (or export AWS credentials as environment variables)
- Sufficient permissions to create and delete VPC, Subnet, IGW, Route Table, Security Group in the target AWS account
- Bash shell

## Step-by-Step Instructions

### 1. Export AWS Credentials
Export your AWS credentials and region (replace with your actual keys):
```bash
export AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=YOUR_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=us-east-2
```

### 2. Deploy Infrastructure
Run the deploy script to create all core resources:
```bash
bash scripts/deploy-infra-cli.sh
```
You will see output for each step: VPC, subnets, IGW, route table, security group, and their IDs.

### 3. Teardown Infrastructure
After testing, run the teardown script to clean up all resources:
```bash
bash scripts/teardown-infra-cli.sh
```
The script will delete all resources in the correct order, handling dependencies automatically.

## Resource Creation/Deletion Sequence
1. **VPC** is created first.
2. **Subnets** (A and B) are created in different AZs within the VPC.
3. **Internet Gateway (IGW)** is created and attached to the VPC.
4. **Route Table** is created and associated with the subnets; a default route to IGW is added.
5. **Security Group** is created and configured for SSH, HTTP, and HTTPS access.
6. **Teardown** script deletes resources in reverse order, ensuring all dependencies are handled (subnets, route table associations, IGW, VPC, etc.).

## Notes
- These scripts are for demonstration and validation in the test environment only.
- In production, use Terraform for full infrastructure as code, dynamic AZ selection, and state management.
- The CLI scripts are idempotent and safe to run multiple times, but always check AWS Console for orphaned resources after testing.

## Why Not Use Terraform Directly?
Due to explicit deny policies on the test user, some Terraform operations (like dynamic AZ discovery and resource protection) are not possible. The CLI scripts provide a way to demonstrate and validate infrastructure provisioning logic under these constraints. 

## Static Code Analysis Steps

To ensure code quality and security, the following static analysis steps were performed:

### Terraform
- **Format Check:**
  ```bash
  terraform fmt -check
  ```
  Checks that all Terraform files are properly formatted.

- **Validation:**
  ```bash
  terraform validate
  ```
  Validates the syntax and structure of Terraform configuration files.

- **Recommended (optional):**
  - **tflint** — Lint Terraform code for best practices and errors.
  - **tfsec** — Scan Terraform code for security issues.
  - **checkov** — Additional security scanning for IaC.

### Shell Scripts
- **ShellCheck:**
  ```bash
  shellcheck scripts/deploy-infra-cli.sh
  shellcheck scripts/teardown-infra-cli.sh
  ```
  Checks shell scripts for errors, security issues, and best practices.

- **Recommended (optional):**
  - **shfmt** — Auto-format shell scripts.
  - **bashate** — Lint bash scripts for style and errors.

### Kubernetes Manifests
- **Validation (already in pipeline):**
  ```bash
  kubectl apply --dry-run=client -f k8s-manifests/backend/
  kubectl apply --dry-run=client -f k8s-manifests/gateway/
  ```
  Validates Kubernetes manifests for syntax and structure.

- **Recommended (optional):**
  - **kubeval** — Validate Kubernetes YAML files against the Kubernetes schema.
  - **kube-score** or **kubesec** — Analyze Kubernetes manifests for security and best practices.
  - **yamllint** — Lint YAML files for syntax and style.

These checks help ensure that the codebase is maintainable, secure, and ready for production deployment. 