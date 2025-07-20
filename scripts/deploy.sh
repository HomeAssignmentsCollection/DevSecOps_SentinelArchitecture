#!/bin/bash

# Sentinel DevSecOps Deployment Script
# This script deploys the complete Sentinel infrastructure and applications

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-us-west-2}
PROJECT_NAME=${PROJECT_NAME:-sentinel}

echo -e "${BLUE}🚀 Starting Sentinel DevSecOps Deployment${NC}"
echo -e "${BLUE}======================================${NC}"

# Check prerequisites
echo -e "${YELLOW}📋 Checking prerequisites...${NC}"

# Check if AWS CLI is installed and configured
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    exit 1
fi

# Check if Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Terraform is not installed${NC}"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed${NC}"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Deploy infrastructure
echo -e "${YELLOW}🏗️  Deploying infrastructure with Terraform...${NC}"
cd infrastructure

# Initialize Terraform
echo -e "${BLUE}Initializing Terraform...${NC}"
terraform init

# Validate configuration
echo -e "${BLUE}Validating Terraform configuration...${NC}"
terraform validate

# Plan deployment
echo -e "${BLUE}Planning Terraform deployment...${NC}"
terraform plan -out=tfplan

# Apply deployment
echo -e "${BLUE}Applying Terraform deployment...${NC}"
terraform apply tfplan

# Get outputs
GATEWAY_CLUSTER=$(terraform output -raw gateway_cluster_name)
BACKEND_CLUSTER=$(terraform output -raw backend_cluster_name)

echo -e "${GREEN}✅ Infrastructure deployment completed${NC}"
echo -e "${BLUE}Gateway Cluster: ${GATEWAY_CLUSTER}${NC}"
echo -e "${BLUE}Backend Cluster: ${BACKEND_CLUSTER}${NC}"

cd ..

# Deploy applications
echo -e "${YELLOW}🚀 Deploying applications to Kubernetes...${NC}"

# Update kubeconfig for backend cluster
echo -e "${BLUE}Configuring kubectl for backend cluster...${NC}"
aws eks update-kubeconfig --region $AWS_REGION --name $BACKEND_CLUSTER

# Deploy backend service
echo -e "${BLUE}Deploying backend service...${NC}"
kubectl apply -f k8s-manifests/backend/

# Wait for backend deployment
echo -e "${BLUE}Waiting for backend deployment to be ready...${NC}"
kubectl rollout status deployment/backend-service -n backend --timeout=300s

# Update kubeconfig for gateway cluster
echo -e "${BLUE}Configuring kubectl for gateway cluster...${NC}"
aws eks update-kubeconfig --region $AWS_REGION --name $GATEWAY_CLUSTER

# Deploy gateway service
echo -e "${BLUE}Deploying gateway service...${NC}"
kubectl apply -f k8s-manifests/gateway/

# Wait for gateway deployment
echo -e "${BLUE}Waiting for gateway deployment to be ready...${NC}"
kubectl rollout status deployment/gateway-service -n gateway --timeout=300s

# Get ALB DNS name
echo -e "${BLUE}Waiting for LoadBalancer to be ready...${NC}"
sleep 60

ALB_DNS=$(kubectl get svc gateway-service -n gateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -z "$ALB_DNS" ]; then
    echo -e "${YELLOW}⚠️  LoadBalancer DNS not yet available. Please check later with:${NC}"
    echo -e "${BLUE}kubectl get svc gateway-service -n gateway${NC}"
else
    echo -e "${GREEN}✅ LoadBalancer DNS: ${ALB_DNS}${NC}"
fi

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}✅ Infrastructure: Deployed${NC}"
echo -e "${GREEN}✅ Backend Service: Running in private VPC${NC}"
echo -e "${GREEN}✅ Gateway Service: Running with public access${NC}"
echo -e "${BLUE}======================================${NC}"

if [ ! -z "$ALB_DNS" ]; then
    echo -e "${YELLOW}🌐 Access your application at: http://${ALB_DNS}${NC}"
    echo -e "${YELLOW}🔍 Test backend connectivity: http://${ALB_DNS}/api/${NC}"
    echo -e "${YELLOW}❤️  Health check: http://${ALB_DNS}/health${NC}"
fi

echo -e "${BLUE}📚 For more information, see the README.md file${NC}"
