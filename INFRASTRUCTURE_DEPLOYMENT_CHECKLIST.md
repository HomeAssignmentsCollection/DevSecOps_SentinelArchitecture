# 🚀 Infrastructure Deployment & Testing Checklist

## 📋 Pre-Deployment Checks

### 1. **Environment Setup**
```bash
# Check AWS CLI availability
aws --version

# Export AWS credentials
export AWS_ACCESS_KEY_ID=YOUR_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=YOUR_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=us-east-2

# Verify AWS access
aws sts get-caller-identity
```

### 2. **Static Code Analysis**
```bash
# Terraform validation
cd infrastructure
terraform fmt -check
terraform validate
cd ..

# Shell script security check
shellcheck scripts/deploy-infra-cli.sh
shellcheck scripts/teardown-infra-cli.sh

# Kubernetes manifests validation
kubectl apply --dry-run=client -f k8s-manifests/backend/
kubectl apply --dry-run=client -f k8s-manifests/gateway/
```

## 🏗️ Infrastructure Deployment Sequence

### Phase 1: Core Infrastructure (CLI Approach)
```bash
# Step 1: Deploy basic infrastructure
bash scripts/deploy-infra-cli.sh

# Step 2: Verify resources created
aws ec2 describe-vpcs --filters Name=tag:Name,Values=sentinel-vpc
aws ec2 describe-subnets --filters Name=tag:Name,Values=sentinel-subnet-*
aws ec2 describe-internet-gateways --filters Name=tag:Name,Values=sentinel-igw
```

### Phase 2: EKS Clusters (Terraform Approach)
```bash
# Step 3: Initialize Terraform
cd infrastructure
terraform init

# Step 4: Plan EKS deployment
terraform plan -var="environment=dev"

# Step 5: Apply EKS clusters
terraform apply -var="environment=dev" -auto-approve

# Step 6: Verify EKS clusters
aws eks list-clusters --region us-east-2
aws eks describe-cluster --name sentinel-gateway --region us-east-2
aws eks describe-cluster --name sentinel-backend --region us-east-2
```

### Phase 3: Kubernetes Deployment
```bash
# Step 7: Configure kubectl for both clusters
aws eks update-kubeconfig --name sentinel-gateway --region us-east-2 --alias gateway
aws eks update-kubeconfig --name sentinel-backend --region us-east-2 --alias backend

# Step 8: Deploy Kubernetes manifests
kubectl apply -f k8s-manifests/backend/
kubectl apply -f k8s-manifests/gateway/

# Step 9: Verify deployments
kubectl get pods -A
kubectl get services -A
kubectl get hpa -A
```

## 🔍 Testing & Validation Sequence

### Test 1: Infrastructure Health
```bash
# Check VPC connectivity
aws ec2 describe-vpcs --vpc-ids $(aws ec2 describe-vpcs --filters Name=tag:Name,Values=sentinel-vpc --query 'Vpcs[0].VpcId' --output text)

# Check EKS cluster status
aws eks describe-cluster --name sentinel-gateway --region us-east-2 --query 'cluster.status'
aws eks describe-cluster --name sentinel-backend --region us-east-2 --query 'cluster.status'
```

### Test 2: Kubernetes Services
```bash
# Check pod status
kubectl get pods -n backend
kubectl get pods -n gateway

# Check service endpoints
kubectl get endpoints -n backend
kubectl get endpoints -n gateway

# Check LoadBalancer status
kubectl get svc -n gateway gateway-service
```

### Test 3: Application Connectivity
```bash
# Get LoadBalancer DNS
ALB_DNS=$(kubectl get svc gateway-service -n gateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test gateway health endpoint
curl -f "http://${ALB_DNS}/health"

# Test backend connectivity through gateway
curl -f "http://${ALB_DNS}/api/"

# Test backend health through gateway
curl -f "http://${ALB_DNS}/backend-health"
```

### Test 4: Security Validation
```bash
# Check network policies
kubectl get networkpolicy -n backend
kubectl get networkpolicy -n gateway

# Check security groups
aws ec2 describe-security-groups --filters Name=group-name,Values=sentinel-sg

# Verify VPC peering
aws ec2 describe-vpc-peering-connections --filters Name=tag:Name,Values=*sentinel*
```

### Test 5: Performance & Scaling
```bash
# Check HPA status
kubectl get hpa -n backend
kubectl get hpa -n gateway

# Check resource usage
kubectl top pods -n backend
kubectl top pods -n gateway

# Check node resources
kubectl top nodes
```

## 🧹 Cleanup Sequence

### Phase 1: Kubernetes Cleanup
```bash
# Delete Kubernetes resources
kubectl delete -f k8s-manifests/gateway/
kubectl delete -f k8s-manifests/backend/

# Verify cleanup
kubectl get pods -A
kubectl get services -A
```

### Phase 2: EKS Cleanup
```bash
# Destroy EKS clusters
cd infrastructure
terraform destroy -var="environment=dev" -auto-approve
cd ..

# Verify EKS cleanup
aws eks list-clusters --region us-east-2
```

### Phase 3: Core Infrastructure Cleanup
```bash
# Clean up basic infrastructure
bash scripts/teardown-infra-cli.sh

# Verify complete cleanup
aws ec2 describe-vpcs --filters Name=tag:Name,Values=sentinel-vpc
```

## 📊 Monitoring & Logging

### Real-time Monitoring
```bash
# Watch pod status
kubectl get pods -n backend -w
kubectl get pods -n gateway -w

# Monitor logs
kubectl logs -f deployment/gateway-service -n gateway
kubectl logs -f deployment/backend-service -n backend

# Check events
kubectl get events -n backend --sort-by='.lastTimestamp'
kubectl get events -n gateway --sort-by='.lastTimestamp'
```

### Cost Monitoring
```bash
# Check AWS costs (requires Cost Explorer access)
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

## ⚠️ Troubleshooting Guide

### Common Issues & Solutions

#### Issue 1: EKS Cluster Creation Fails
```bash
# Check IAM permissions
aws sts get-caller-identity
aws iam get-user

# Check VPC configuration
aws ec2 describe-vpcs --vpc-ids <vpc-id>
```

#### Issue 2: Pods Not Starting
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Check node resources
kubectl describe nodes

# Check image pull issues
kubectl get events -n <namespace> | grep Failed
```

#### Issue 3: LoadBalancer Not Available
```bash
# Check ALB controller
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# Check service configuration
kubectl describe svc gateway-service -n gateway
```

#### Issue 4: Cross-VPC Connectivity Issues
```bash
# Check VPC peering status
aws ec2 describe-vpc-peering-connections

# Check route tables
aws ec2 describe-route-tables --filters Name=vpc-id,Values=<vpc-id>

# Test connectivity
kubectl exec -it <gateway-pod> -n gateway -- curl backend-service.backend.svc.cluster.local
```

## 🎯 Success Criteria

### Infrastructure Success:
- ✅ VPC created with correct CIDR blocks
- ✅ EKS clusters running and healthy
- ✅ VPC peering established
- ✅ Security groups configured correctly

### Application Success:
- ✅ Gateway service accessible via LoadBalancer
- ✅ Backend service accessible through gateway
- ✅ Health checks passing
- ✅ Cross-VPC communication working

### Security Success:
- ✅ Network policies applied
- ✅ Security groups restrictive
- ✅ Backend service not directly accessible
- ✅ Gateway service properly exposed

### Performance Success:
- ✅ Pods running with optimal resource allocation
- ✅ HPA configured and functional
- ✅ LoadBalancer responding within SLA
- ✅ No resource contention

## 📝 Documentation

After successful deployment, document:
1. **Resource IDs** for all created resources
2. **LoadBalancer DNS** for external access
3. **Cost estimates** based on current configuration
4. **Performance metrics** and baseline measurements
5. **Security configurations** and compliance status
6. **Troubleshooting steps** for common issues

This checklist ensures systematic, repeatable, and verifiable infrastructure deployment and testing. 