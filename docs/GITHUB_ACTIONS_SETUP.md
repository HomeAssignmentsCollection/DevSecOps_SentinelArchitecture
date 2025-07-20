# GitHub Actions Setup Guide

This guide explains how to configure GitHub Actions for automated deployment of the Sentinel DevSecOps infrastructure.

## Overview

The GitHub Actions workflows use OpenID Connect (OIDC) to authenticate with AWS without storing long-lived credentials. This is more secure than using AWS access keys.

## Prerequisites

- AWS Account with administrative access
- GitHub repository with Actions enabled
- AWS CLI configured locally

## Step 1: Create IAM OIDC Identity Provider

First, create an OIDC identity provider in AWS to trust GitHub Actions:

```bash
# Create the OIDC identity provider
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --thumbprint-list 1c58a3a8518e8759bf075b76b750d4f2df264fcd
```

## Step 2: Create IAM Role for GitHub Actions

Create an IAM role that GitHub Actions can assume:

### 2.1 Create Trust Policy

Create a file named `github-actions-trust-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
```

**Important**: Replace `YOUR_ACCOUNT_ID`, `YOUR_GITHUB_USERNAME`, and `YOUR_REPO_NAME` with your actual values.

### 2.2 Create the Role

```bash
# Create the IAM role
aws iam create-role \
  --role-name GitHubActions-Sentinel-Role \
  --assume-role-policy-document file://github-actions-trust-policy.json \
  --description "Role for GitHub Actions to deploy Sentinel infrastructure"
```

### 2.3 Attach Policies

Attach the necessary policies for Terraform operations:

```bash
# Attach AWS managed policies
aws iam attach-role-policy \
  --role-name GitHubActions-Sentinel-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

aws iam attach-role-policy \
  --role-name GitHubActions-Sentinel-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

aws iam attach-role-policy \
  --role-name GitHubActions-Sentinel-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy \
  --role-name GitHubActions-Sentinel-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam attach-role-policy \
  --role-name GitHubActions-Sentinel-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

aws iam attach-role-policy \
  --role-name GitHubActions-Sentinel-Role \
  --policy-arn arn:aws:iam::aws:policy/IAMFullAccess

aws iam attach-role-policy \
  --role-name GitHubActions-Sentinel-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

aws iam attach-role-policy \
  --role-name GitHubActions-Sentinel-Role \
  --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
```

### 2.4 Create Custom Policy for Additional Permissions

Create a custom policy for additional permissions needed:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:GetCallerIdentity",
        "sts:AssumeRole",
        "cloudwatch:*",
        "logs:*",
        "elasticloadbalancing:*",
        "route53:*",
        "acm:*"
      ],
      "Resource": "*"
    }
  ]
}
```

Save this as `github-actions-additional-policy.json` and create the policy:

```bash
aws iam create-policy \
  --policy-name GitHubActions-Sentinel-Additional \
  --policy-document file://github-actions-additional-policy.json

aws iam attach-role-policy \
  --role-name GitHubActions-Sentinel-Role \
  --policy-arn arn:aws:iam::YOUR_ACCOUNT_ID:policy/GitHubActions-Sentinel-Additional
```

## Step 3: Configure GitHub Repository Secrets

### 3.1 Get the Role ARN

```bash
aws iam get-role --role-name GitHubActions-Sentinel-Role --query 'Role.Arn' --output text
```

### 3.2 Add Secrets to GitHub Repository

1. Go to your GitHub repository
2. Click on **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ROLE_ARN` | `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActions-Sentinel-Role` | IAM role ARN for GitHub Actions |
| `TERRAFORM_STATE_BUCKET` | `sentinel-terraform-state-YOUR_UNIQUE_SUFFIX` | S3 bucket for Terraform state |

## Step 4: Test the Configuration

Create a simple test workflow to verify the setup:

```yaml
name: Test AWS Connection
on:
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-west-2

      - name: Test AWS connection
        run: |
          aws sts get-caller-identity
          echo "✅ AWS authentication successful"
```

## Security Best Practices

1. **Principle of Least Privilege**: Only grant the minimum permissions required
2. **Repository Restrictions**: Limit the OIDC trust policy to specific repositories
3. **Branch Restrictions**: Consider limiting to specific branches (e.g., `main`)
4. **Regular Audits**: Regularly review and rotate IAM roles and policies
5. **Environment Protection**: Use GitHub environment protection rules for production deployments

## Troubleshooting

### Common Issues

1. **"No OpenIDConnect provider found"**
   - Ensure the OIDC provider is created in the correct AWS account
   - Verify the thumbprints are correct

2. **"AssumeRoleWithWebIdentity failed"**
   - Check the trust policy conditions
   - Verify the repository name and GitHub username are correct

3. **"Access Denied" during Terraform operations**
   - Review the attached IAM policies
   - Check if additional permissions are needed for specific resources

### Debug Commands

```bash
# Check OIDC provider
aws iam list-open-id-connect-providers

# Check role trust policy
aws iam get-role --role-name GitHubActions-Sentinel-Role

# Check attached policies
aws iam list-attached-role-policies --role-name GitHubActions-Sentinel-Role
```

## Next Steps

After completing this setup:

1. Test the workflows by creating a pull request
2. Monitor the workflow runs for any permission issues
3. Adjust IAM policies as needed based on actual Terraform requirements
4. Set up environment protection rules for production deployments

For more information, see:
- [GitHub OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [AWS IAM OIDC Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
