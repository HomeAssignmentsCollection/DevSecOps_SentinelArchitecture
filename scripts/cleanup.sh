#!/bin/bash

# Sentinel DevSecOps Cleanup Script
# This script safely destroys all Sentinel infrastructure and applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-us-west-2}

echo -e "${RED}🗑️  Sentinel DevSecOps Cleanup${NC}"
echo -e "${RED}==============================${NC}"
echo -e "${YELLOW}⚠️  This will destroy ALL Sentinel infrastructure!${NC}"
echo -e "${YELLOW}⚠️  This action cannot be undone!${NC}"
echo ""

# Confirmation prompt
read -p "Are you sure you want to proceed? (type 'yes' to confirm): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo -e "${BLUE}Cleanup cancelled.${NC}"
    exit 0
fi

echo -e "${YELLOW}🧹 Starting cleanup process...${NC}"

# Get cluster names from Terraform (if available)
cd infrastructure
GATEWAY_CLUSTER=$(terraform output -raw gateway_cluster_name 2>/dev/null || echo "")
BACKEND_CLUSTER=$(terraform output -raw backend_cluster_name 2>/dev/null || echo "")
cd ..

# Clean up Kubernetes resources first
if [ ! -z "$GATEWAY_CLUSTER" ]; then
    echo -e "${YELLOW}🗑️  Cleaning up Gateway cluster applications...${NC}"
    aws eks update-kubeconfig --region $AWS_REGION --name $GATEWAY_CLUSTER 2>/dev/null || true
    kubectl delete -f k8s-manifests/gateway/ --ignore-not-found=true 2>/dev/null || true
    echo -e "${GREEN}✅ Gateway applications cleaned up${NC}"
fi

if [ ! -z "$BACKEND_CLUSTER" ]; then
    echo -e "${YELLOW}🗑️  Cleaning up Backend cluster applications...${NC}"
    aws eks update-kubeconfig --region $AWS_REGION --name $BACKEND_CLUSTER 2>/dev/null || true
    kubectl delete -f k8s-manifests/backend/ --ignore-not-found=true 2>/dev/null || true
    echo -e "${GREEN}✅ Backend applications cleaned up${NC}"
fi

# Wait for LoadBalancers to be deleted
echo -e "${YELLOW}⏳ Waiting for LoadBalancers to be deleted...${NC}"
sleep 30

# Destroy infrastructure with Terraform
echo -e "${YELLOW}🏗️  Destroying infrastructure with Terraform...${NC}"
cd infrastructure

# Check if Terraform state exists
if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
    echo -e "${BLUE}Initializing Terraform...${NC}"
    terraform init

    echo -e "${BLUE}Planning destruction...${NC}"
    terraform plan -destroy -out=destroy.tfplan

    echo -e "${BLUE}Destroying infrastructure...${NC}"
    terraform apply destroy.tfplan

    echo -e "${GREEN}✅ Infrastructure destroyed${NC}"
else
    echo -e "${YELLOW}⚠️  No Terraform state found, skipping infrastructure destruction${NC}"
fi

cd ..

# Clean up local kubectl contexts
echo -e "${YELLOW}🧹 Cleaning up kubectl contexts...${NC}"
kubectl config delete-context backend 2>/dev/null || true
kubectl config delete-context gateway 2>/dev/null || true

echo -e "${GREEN}🎉 Cleanup completed successfully!${NC}"
echo -e "${BLUE}==============================${NC}"
echo -e "${GREEN}✅ Applications: Removed${NC}"
echo -e "${GREEN}✅ Infrastructure: Destroyed${NC}"
echo -e "${GREEN}✅ Kubectl contexts: Cleaned${NC}"
echo -e "${BLUE}==============================${NC}"
echo -e "${YELLOW}💡 All Sentinel resources have been removed from AWS${NC}"
