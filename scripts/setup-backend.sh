#!/bin/bash

# Sentinel Backend Setup Script
# This script sets up the S3 backend for Terraform state management

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Setting up Terraform Backend${NC}"
echo -e "${BLUE}==============================${NC}"

# Check if we're in the right directory
if [ ! -f "infrastructure/main.tf" ]; then
    echo -e "${RED}❌ Please run this script from the project root directory${NC}"
    exit 1
fi

cd infrastructure

# First deployment to create backend resources
echo -e "${YELLOW}📦 Creating S3 bucket and DynamoDB table for state management...${NC}"
terraform init
terraform plan -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_locks -target=random_id.bucket_suffix -out=backend.tfplan
terraform apply backend.tfplan

# Get the bucket name
BUCKET_NAME=$(terraform output -raw terraform_state_bucket_name 2>/dev/null || terraform show -json | jq -r '.values.root_module.resources[] | select(.address=="aws_s3_bucket.terraform_state") | .values.bucket')

if [ -z "$BUCKET_NAME" ]; then
    echo -e "${RED}❌ Could not determine bucket name${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Backend resources created${NC}"
echo -e "${BLUE}S3 Bucket: ${BUCKET_NAME}${NC}"

# Update main.tf to use the backend
echo -e "${YELLOW}🔄 Configuring Terraform to use S3 backend...${NC}"

# Create a backup of main.tf
cp main.tf main.tf.backup

# Update the backend configuration
sed -i.tmp 's|# backend "s3" {|backend "s3" {|g' main.tf
sed -i.tmp 's|#   bucket         = "sentinel-terraform-state-bucket"|  bucket         = "'$BUCKET_NAME'"|g' main.tf
sed -i.tmp 's|#   key            = "sentinel/terraform.tfstate"|  key            = "sentinel/terraform.tfstate"|g' main.tf
sed -i.tmp 's|#   region         = "us-west-2"|  region         = "us-west-2"|g' main.tf
sed -i.tmp 's|#   dynamodb_table = "sentinel-terraform-locks"|  dynamodb_table = "sentinel-terraform-locks"|g' main.tf
sed -i.tmp 's|#   encrypt        = true|  encrypt        = true|g' main.tf
sed -i.tmp 's|# }|}|g' main.tf

# Clean up temporary file
rm -f main.tf.tmp

# Reinitialize with backend
echo -e "${YELLOW}🔄 Reinitializing Terraform with S3 backend...${NC}"
terraform init -migrate-state -force-copy

echo -e "${GREEN}✅ Terraform backend setup completed${NC}"
echo -e "${BLUE}==============================${NC}"
echo -e "${GREEN}✅ S3 Bucket: ${BUCKET_NAME}${NC}"
echo -e "${GREEN}✅ DynamoDB Table: sentinel-terraform-locks${NC}"
echo -e "${GREEN}✅ State Migration: Completed${NC}"
echo -e "${BLUE}==============================${NC}"

cd ..

echo -e "${YELLOW}💡 Your Terraform state is now stored in S3 with DynamoDB locking${NC}"
echo -e "${YELLOW}💡 You can now safely run terraform commands from multiple locations${NC}"
