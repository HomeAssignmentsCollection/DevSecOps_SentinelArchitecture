#!/bin/bash

# Sentinel Infrastructure Fixes Validation Script
# This script validates all the high and medium priority fixes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Validating Sentinel Infrastructure Fixes${NC}"
echo -e "${BLUE}===========================================${NC}"

# Test 1: VPC Peering Race Condition Fix
echo -e "${YELLOW}🔧 Test 1: VPC Peering Race Condition Fix${NC}"
cd infrastructure

# Check if time provider is configured
if grep -q "time" main.tf; then
    echo -e "${GREEN}✅ Time provider configured${NC}"
else
    echo -e "${RED}❌ Time provider missing${NC}"
fi

# Check if networking module has proper dependencies
if grep -q "depends_on.*time_sleep" ../modules/networking/main.tf; then
    echo -e "${GREEN}✅ VPC peering dependencies configured${NC}"
else
    echo -e "${RED}❌ VPC peering dependencies missing${NC}"
fi

# Test 2: Network Policy Security Fix
echo -e "${YELLOW}🔒 Test 2: Network Policy Security Fix${NC}"
cd ..

# Validate backend network policy
if kubectl apply --dry-run=client -f k8s-manifests/backend/network-policy.yaml > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend network policy is valid${NC}"
    
    # Check if it properly restricts to gateway namespace
    if grep -q "name: gateway" k8s-manifests/backend/network-policy.yaml; then
        echo -e "${GREEN}✅ Network policy restricts to gateway namespace${NC}"
    else
        echo -e "${RED}❌ Network policy not properly restricted${NC}"
    fi
else
    echo -e "${RED}❌ Backend network policy is invalid${NC}"
fi

# Test 3: NAT Gateway Monitoring
echo -e "${YELLOW}📊 Test 3: NAT Gateway Monitoring${NC}"

# Check if CloudWatch alarms are configured
if grep -q "aws_cloudwatch_metric_alarm.*nat_gateway" modules/vpc/main.tf; then
    echo -e "${GREEN}✅ NAT Gateway CloudWatch alarms configured${NC}"
else
    echo -e "${RED}❌ NAT Gateway monitoring missing${NC}"
fi

# Check if monitoring variables are defined
if grep -q "alarm_actions" modules/vpc/variables.tf; then
    echo -e "${GREEN}✅ Monitoring variables defined${NC}"
else
    echo -e "${RED}❌ Monitoring variables missing${NC}"
fi

# Test 4: GitHub Actions Credential Validation
echo -e "${YELLOW}🔐 Test 4: GitHub Actions Credential Validation${NC}"

# Check if AWS credential validation is in workflows
if grep -q "Validate AWS credentials" .github/workflows/terraform-apply.yml; then
    echo -e "${GREEN}✅ AWS credential validation in terraform-apply workflow${NC}"
else
    echo -e "${RED}❌ AWS credential validation missing in terraform-apply${NC}"
fi

if grep -q "Terraform state not found" .github/workflows/k8s-deploy.yml; then
    echo -e "${GREEN}✅ Error handling in k8s-deploy workflow${NC}"
else
    echo -e "${RED}❌ Error handling missing in k8s-deploy${NC}"
fi

# Test 5: Resource Limits and HPA
echo -e "${YELLOW}⚡ Test 5: Resource Limits and HPA${NC}"

# Check gateway resource limits
GATEWAY_CPU_LIMIT=$(grep -A 10 "limits:" k8s-manifests/gateway/deployment.yaml | grep "cpu:" | awk '{print $2}')
if [ "$GATEWAY_CPU_LIMIT" = "500m" ]; then
    echo -e "${GREEN}✅ Gateway CPU limits increased${NC}"
else
    echo -e "${RED}❌ Gateway CPU limits not updated (found: $GATEWAY_CPU_LIMIT)${NC}"
fi

# Check if HPA is configured
if grep -q "HorizontalPodAutoscaler" k8s-manifests/gateway/deployment.yaml; then
    echo -e "${GREEN}✅ Gateway HPA configured${NC}"
else
    echo -e "${RED}❌ Gateway HPA missing${NC}"
fi

if grep -q "HorizontalPodAutoscaler" k8s-manifests/backend/deployment.yaml; then
    echo -e "${GREEN}✅ Backend HPA configured${NC}"
else
    echo -e "${RED}❌ Backend HPA missing${NC}"
fi

# Test 6: Dynamic Subnet Allocation
echo -e "${YELLOW}🌐 Test 6: Dynamic Subnet Allocation${NC}"

# Check if locals block with subnet calculation exists
if grep -q "subnet_bits.*ceil.*log" modules/vpc/main.tf; then
    echo -e "${GREEN}✅ Dynamic subnet calculation implemented${NC}"
else
    echo -e "${RED}❌ Dynamic subnet calculation missing${NC}"
fi

# Check if validation is in place
if grep -q "validate_subnet_allocation" modules/vpc/main.tf; then
    echo -e "${GREEN}✅ Subnet allocation validation configured${NC}"
else
    echo -e "${RED}❌ Subnet allocation validation missing${NC}"
fi

# Test 7: Restrictive Security Groups
echo -e "${YELLOW}🛡️  Test 7: Restrictive Security Groups${NC}"

# Check if security groups use specific ports instead of all traffic
if grep -q "from_port.*8080" modules/security/main.tf; then
    echo -e "${GREEN}✅ Gateway security group uses specific ports${NC}"
else
    echo -e "${RED}❌ Gateway security group still allows all traffic${NC}"
fi

if grep -q "from_port.*80" modules/security/main.tf && ! grep -q "from_port.*0" modules/security/main.tf; then
    echo -e "${GREEN}✅ Backend security group uses specific ports${NC}"
else
    echo -e "${RED}❌ Backend security group configuration needs review${NC}"
fi

# Test 8: Terraform State Backup
echo -e "${YELLOW}💾 Test 8: Terraform State Backup${NC}"

# Check if backup step is in workflow
if grep -q "Backup Terraform State" .github/workflows/terraform-apply.yml; then
    echo -e "${GREEN}✅ Terraform state backup configured${NC}"
else
    echo -e "${RED}❌ Terraform state backup missing${NC}"
fi

# Check if rollback logic is present
if grep -q "restore from backup" .github/workflows/terraform-apply.yml; then
    echo -e "${GREEN}✅ State rollback logic configured${NC}"
else
    echo -e "${RED}❌ State rollback logic missing${NC}"
fi

# Terraform Validation
echo -e "${YELLOW}🔍 Terraform Validation${NC}"
cd infrastructure

# Format check
if terraform fmt -check -recursive > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Terraform formatting is correct${NC}"
else
    echo -e "${YELLOW}⚠️  Terraform formatting issues found, running fmt...${NC}"
    terraform fmt -recursive
fi

# Validation check
if terraform validate > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Terraform configuration is valid${NC}"
else
    echo -e "${RED}❌ Terraform validation failed${NC}"
    terraform validate
fi

cd ..

# Kubernetes Manifest Validation
echo -e "${YELLOW}☸️  Kubernetes Manifest Validation${NC}"

# Validate all manifests
for file in k8s-manifests/**/*.yaml; do
    if kubectl apply --dry-run=client -f "$file" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ $(basename $file) is valid${NC}"
    else
        echo -e "${RED}❌ $(basename $file) validation failed${NC}"
        kubectl apply --dry-run=client -f "$file"
    fi
done

# Summary
echo -e "${BLUE}===========================================${NC}"
echo -e "${GREEN}🎉 Validation completed!${NC}"
echo -e "${BLUE}===========================================${NC}"

echo -e "${YELLOW}📋 Summary of Fixes Implemented:${NC}"
echo -e "${GREEN}✅ High Priority Fixes:${NC}"
echo -e "   • VPC peering race condition resolved"
echo -e "   • Network policy security hardened"
echo -e "   • NAT Gateway monitoring added"
echo -e "   • GitHub Actions credential validation enhanced"

echo -e "${GREEN}✅ Medium Priority Fixes:${NC}"
echo -e "   • Resource limits increased with HPA"
echo -e "   • Dynamic subnet allocation implemented"
echo -e "   • Security group rules made restrictive"
echo -e "   • Terraform state backup automated"

echo -e "${YELLOW}🚀 Next Steps:${NC}"
echo -e "   1. Review any failed validations above"
echo -e "   2. Test deployment in a development environment"
echo -e "   3. Monitor CloudWatch alarms after deployment"
echo -e "   4. Validate cross-VPC connectivity"
echo -e "   5. Test auto-scaling behavior under load"
