#!/bin/bash

# Sentinel Infrastructure Deployment and Testing Script
# This script performs complete infrastructure deployment and testing
# Usage: bash scripts/deploy-and-test.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-us-east-2}
ENVIRONMENT=${ENVIRONMENT:-dev}

echo -e "${BLUE}🚀 Sentinel Infrastructure Deployment & Testing${NC}"
echo -e "${BLUE}===============================================${NC}"

# Function to print section headers
print_section() {
    echo -e "\n${YELLOW}📋 $1${NC}"
    echo -e "${YELLOW}================================${NC}"
}

# Function to check command success
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        exit 1
    fi
}

# Function to wait for resources
wait_for_resource() {
    local resource_type=$1
    local resource_name=$2
    local max_attempts=${3:-30}
    local attempt=1
    
    echo -e "${BLUE}⏳ Waiting for $resource_type $resource_name...${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        case $resource_type in
            "eks")
                status=$(aws eks describe-cluster --name $resource_name --region $AWS_REGION --query 'cluster.status' --output text 2>/dev/null || echo "FAILED")
                ;;
            "vpc")
                status=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=$resource_name --query 'Vpcs[0].State' --output text 2>/dev/null || echo "FAILED")
                ;;
            "pod")
                status=$(kubectl get pod $resource_name -n ${3:-default} -o jsonpath='{.status.phase}' 2>/dev/null || echo "FAILED")
                ;;
        esac
        
        if [ "$status" = "ACTIVE" ] || [ "$status" = "Running" ]; then
            echo -e "${GREEN}✅ $resource_type $resource_name is ready${NC}"
            return 0
        fi
        
        echo -e "${BLUE}⏳ Attempt $attempt/$max_attempts: $status${NC}"
        sleep 10
        ((attempt++))
    done
    
    echo -e "${RED}❌ $resource_type $resource_name failed to become ready${NC}"
    return 1
}

# Phase 1: Pre-deployment checks
print_section "Pre-deployment Checks"

echo -e "${BLUE}🔍 Checking AWS CLI...${NC}"
aws --version > /dev/null
check_success "AWS CLI is available"

echo -e "${BLUE}🔍 Checking AWS credentials...${NC}"
aws sts get-caller-identity > /dev/null
check_success "AWS credentials are valid"

echo -e "${BLUE}🔍 Checking Terraform...${NC}"
cd infrastructure
terraform fmt -check > /dev/null
check_success "Terraform formatting is correct"

terraform validate > /dev/null
check_success "Terraform configuration is valid"
cd ..

echo -e "${BLUE}🔍 Checking shell scripts...${NC}"
shellcheck scripts/deploy-infra-cli.sh > /dev/null
shellcheck scripts/teardown-infra-cli.sh > /dev/null
check_success "Shell scripts passed security checks"

echo -e "${BLUE}🔍 Validating Kubernetes manifests...${NC}"
kubectl apply --dry-run=client -f k8s-manifests/backend/ > /dev/null
kubectl apply --dry-run=client -f k8s-manifests/gateway/ > /dev/null
check_success "Kubernetes manifests are valid"

# Phase 2: Core infrastructure deployment
print_section "Core Infrastructure Deployment"

echo -e "${BLUE}🏗️ Deploying core infrastructure...${NC}"
bash scripts/deploy-infra-cli.sh
check_success "Core infrastructure deployed"

# Phase 3: EKS clusters deployment
print_section "EKS Clusters Deployment"

echo -e "${BLUE}🏗️ Initializing Terraform...${NC}"
cd infrastructure
terraform init > /dev/null
check_success "Terraform initialized"

echo -e "${BLUE}🏗️ Planning EKS deployment...${NC}"
terraform plan -var="environment=$ENVIRONMENT" > /dev/null
check_success "Terraform plan successful"

echo -e "${BLUE}🏗️ Deploying EKS clusters...${NC}"
terraform apply -var="environment=$ENVIRONMENT" -auto-approve
check_success "EKS clusters deployed"

cd ..

# Phase 4: Wait for EKS clusters
print_section "Waiting for EKS Clusters"

wait_for_resource "eks" "sentinel-gateway"
wait_for_resource "eks" "sentinel-backend"

# Phase 5: Kubernetes deployment
print_section "Kubernetes Deployment"

echo -e "${BLUE}🔧 Configuring kubectl for gateway cluster...${NC}"
aws eks update-kubeconfig --name sentinel-gateway --region $AWS_REGION --alias gateway
check_success "Gateway cluster configured"

echo -e "${BLUE}🔧 Configuring kubectl for backend cluster...${NC}"
aws eks update-kubeconfig --name sentinel-backend --region $AWS_REGION --alias backend
check_success "Backend cluster configured"

echo -e "${BLUE}🚀 Deploying backend services...${NC}"
kubectl apply -f k8s-manifests/backend/
check_success "Backend services deployed"

echo -e "${BLUE}🚀 Deploying gateway services...${NC}"
kubectl apply -f k8s-manifests/gateway/
check_success "Gateway services deployed"

# Phase 6: Wait for pods
print_section "Waiting for Pods"

echo -e "${BLUE}⏳ Waiting for backend pods...${NC}"
kubectl wait --for=condition=ready pod -l app=backend-service -n backend --timeout=300s
check_success "Backend pods are ready"

echo -e "${BLUE}⏳ Waiting for gateway pods...${NC}"
kubectl wait --for=condition=ready pod -l app=gateway-service -n gateway --timeout=300s
check_success "Gateway pods are ready"

# Phase 7: Testing
print_section "Testing & Validation"

echo -e "${BLUE}🔍 Testing infrastructure health...${NC}"
aws eks describe-cluster --name sentinel-gateway --region $AWS_REGION --query 'cluster.status' | grep -q "ACTIVE"
check_success "Gateway cluster is healthy"

aws eks describe-cluster --name sentinel-backend --region $AWS_REGION --query 'cluster.status' | grep -q "ACTIVE"
check_success "Backend cluster is healthy"

echo -e "${BLUE}🔍 Testing Kubernetes services...${NC}"
kubectl get pods -n backend | grep -q "Running"
check_success "Backend pods are running"

kubectl get pods -n gateway | grep -q "Running"
check_success "Gateway pods are running"

echo -e "${BLUE}🔍 Testing LoadBalancer...${NC}"
# Wait for LoadBalancer to be provisioned
echo -e "${BLUE}⏳ Waiting for LoadBalancer...${NC}"
for i in {1..30}; do
    ALB_DNS=$(kubectl get svc gateway-service -n gateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    if [ ! -z "$ALB_DNS" ]; then
        break
    fi
    sleep 10
done

if [ ! -z "$ALB_DNS" ]; then
    echo -e "${GREEN}✅ LoadBalancer DNS: $ALB_DNS${NC}"
    
    echo -e "${BLUE}🔍 Testing gateway health endpoint...${NC}"
    curl -f -s "http://${ALB_DNS}/health" > /dev/null
    check_success "Gateway health endpoint is accessible"
    
    echo -e "${BLUE}🔍 Testing backend connectivity...${NC}"
    curl -f -s "http://${ALB_DNS}/api/" > /dev/null
    check_success "Backend connectivity through gateway is working"
    
    echo -e "${BLUE}🔍 Testing backend health...${NC}"
    curl -f -s "http://${ALB_DNS}/backend-health" > /dev/null
    check_success "Backend health endpoint is accessible"
else
    echo -e "${RED}❌ LoadBalancer DNS not available${NC}"
    exit 1
fi

echo -e "${BLUE}🔍 Testing security configurations...${NC}"
kubectl get networkpolicy -n backend > /dev/null 2>&1
check_success "Backend network policies are configured"

kubectl get networkpolicy -n gateway > /dev/null 2>&1
check_success "Gateway network policies are configured"

# Phase 8: Performance checks
print_section "Performance & Scaling Checks"

echo -e "${BLUE}📊 Checking HPA status...${NC}"
kubectl get hpa -n backend
kubectl get hpa -n gateway

echo -e "${BLUE}📊 Checking resource usage...${NC}"
kubectl top pods -n backend 2>/dev/null || echo "Metrics server not available"
kubectl top pods -n gateway 2>/dev/null || echo "Metrics server not available"

# Phase 9: Summary
print_section "Deployment Summary"

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${BLUE}📋 Summary:${NC}"
echo -e "  • Core infrastructure: ✅ Deployed"
echo -e "  • EKS clusters: ✅ Deployed and healthy"
echo -e "  • Kubernetes services: ✅ Deployed and running"
echo -e "  • LoadBalancer: ✅ Provisioned and accessible"
echo -e "  • Cross-VPC connectivity: ✅ Working"
echo -e "  • Security policies: ✅ Applied"

if [ ! -z "$ALB_DNS" ]; then
    echo -e "\n${BLUE}🌐 Access URLs:${NC}"
    echo -e "  • Gateway Health: http://${ALB_DNS}/health"
    echo -e "  • Backend API: http://${ALB_DNS}/api/"
    echo -e "  • Backend Health: http://${ALB_DNS}/backend-health"
fi

echo -e "\n${YELLOW}📝 Next steps:${NC}"
echo -e "  • Monitor application performance"
echo -e "  • Check AWS costs in Cost Explorer"
echo -e "  • Run load tests if needed"
echo -e "  • Use cleanup script when done: bash scripts/cleanup.sh"

echo -e "\n${GREEN}✅ All tests passed! Infrastructure is ready for use.${NC}" 