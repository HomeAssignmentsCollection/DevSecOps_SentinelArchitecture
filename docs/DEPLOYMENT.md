# Deployment Guide

This guide provides detailed instructions for deploying the Sentinel DevSecOps infrastructure and applications.

## Prerequisites

### Required Tools

1. **AWS CLI v2**

   ```bash
   # Install AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Verify installation
   aws --version
   ```

2. **Terraform >= 1.6.0**

   ```bash
   # Install Terraform
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   
   # Verify installation
   terraform --version
   ```

3. **kubectl >= 1.28.0**

   ```bash
   # Install kubectl
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/
   
   # Verify installation
   kubectl version --client
   ```

### AWS Configuration

1. **Configure AWS Credentials**

   ```bash
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Enter your default region (us-west-2)
   # Enter your default output format (json)
   ```

2. **Verify AWS Access**

   ```bash
   aws sts get-caller-identity
   ```

3. **Required AWS Permissions**
   Your AWS user/role needs the following permissions:
   - EC2 (VPC, Security Groups, Subnets)
   - EKS (Clusters, Node Groups)
   - IAM (Roles, Policies)
   - S3 (Buckets, Objects)
   - DynamoDB (Tables)
   - CloudWatch (Logs)

## Deployment Steps

### Step 1: Clone Repository

```bash
git clone <repository-url>
cd devsecops-technical-challenge
```

### Step 2: Setup Terraform Backend

The first deployment creates the S3 bucket and DynamoDB table for Terraform state management:

```bash
chmod +x scripts/setup-backend.sh
./scripts/setup-backend.sh
```

This script will:

- Create S3 bucket for Terraform state
- Create DynamoDB table for state locking
- Configure Terraform to use the remote backend
- Migrate local state to S3

### Step 3: Deploy Infrastructure

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

This script will:

- Validate Terraform configuration
- Deploy VPCs and networking
- Create EKS clusters
- Deploy applications to Kubernetes
- Configure load balancers
- Test connectivity

### Step 4: Verify Deployment

```bash
chmod +x scripts/test-connectivity.sh
./scripts/test-connectivity.sh
```

This script will:

- Check EKS cluster status
- Verify application deployments
- Test cross-VPC connectivity
- Validate security configurations
- Provide access URLs

## Manual Deployment (Step by Step)

If you prefer to deploy manually or need to troubleshoot:

### Infrastructure Deployment

1. **Initialize Terraform**

   ```bash
   cd infrastructure
   terraform init
   ```

2. **Plan Deployment**

   ```bash
   terraform plan -out=tfplan
   ```

3. **Apply Infrastructure**

   ```bash
   terraform apply tfplan
   ```

4. **Get Outputs**

   ```bash
   terraform output
   ```

### Application Deployment

1. **Configure kubectl for Backend Cluster**

   ```bash
   aws eks update-kubeconfig --region us-west-2 --name sentinel-backend
   ```

2. **Deploy Backend Application**

   ```bash
   kubectl apply -f k8s-manifests/backend/
   ```

3. **Verify Backend Deployment**

   ```bash
   kubectl get pods -n backend
   kubectl rollout status deployment/backend-service -n backend
   ```

4. **Configure kubectl for Gateway Cluster**

   ```bash
   aws eks update-kubeconfig --region us-west-2 --name sentinel-gateway
   ```

5. **Deploy Gateway Application**

   ```bash
   kubectl apply -f k8s-manifests/gateway/
   ```

6. **Verify Gateway Deployment**

   ```bash
   kubectl get pods -n gateway
   kubectl rollout status deployment/gateway-service -n gateway
   ```

7. **Get Load Balancer URL**

   ```bash
   kubectl get svc gateway-service -n gateway
   ```

## Configuration Customization

### Environment Variables

You can customize the deployment by setting environment variables:

```bash
export AWS_REGION="us-east-1"
export PROJECT_NAME="my-sentinel"
export GATEWAY_VPC_CIDR="172.16.0.0/16"
export BACKEND_VPC_CIDR="172.17.0.0/16"
```

### Terraform Variables

Edit `infrastructure/terraform.tfvars` to customize:

```hcl
# AWS Configuration
aws_region = "us-east-1"
environment = "prod"

# Project Configuration
project_name = "my-sentinel"

# Network Configuration
gateway_vpc_cidr = "172.16.0.0/16"
backend_vpc_cidr = "172.17.0.0/16"

# EKS Configuration
eks_version = "1.29"
node_instance_types = ["t3.large"]

# Cost Optimization
single_nat_gateway = false  # Use multiple NAT gateways for HA
```

## Troubleshooting

### Common Issues

1. **Terraform Backend Initialization Fails**

   ```bash
   # Check AWS credentials
   aws sts get-caller-identity
   
   # Check S3 bucket permissions
   aws s3 ls s3://your-bucket-name
   ```

2. **EKS Cluster Creation Timeout**

   ```bash
   # Check AWS service limits
   aws service-quotas get-service-quota --service-code eks --quota-code L-1194D53C
   
   # Check IAM permissions
   aws iam get-role --role-name sentinel-gateway-cluster-role
   ```

3. **LoadBalancer Not Getting External IP**

   ```bash
   # Check security groups
   kubectl describe svc gateway-service -n gateway
   
   # Check subnet tags
   aws ec2 describe-subnets --filters "Name=tag:kubernetes.io/role/elb,Values=1"
   ```

4. **Cross-VPC Communication Fails**

   ```bash
   # Check VPC peering status
   aws ec2 describe-vpc-peering-connections
   
   # Check route tables
   aws ec2 describe-route-tables
   
   # Test DNS resolution
   kubectl exec -it test-pod -- nslookup backend-service.backend.svc.cluster.local
   ```

### Debugging Commands

```bash
# Check EKS cluster status
aws eks describe-cluster --name sentinel-gateway

# Check node group status
aws eks describe-nodegroup --cluster-name sentinel-gateway --nodegroup-name sentinel-gateway-nodes

# Check pod logs
kubectl logs -f deployment/gateway-service -n gateway

# Check service endpoints
kubectl get endpoints -n gateway

# Check network policies
kubectl describe networkpolicy -n backend

# Check security groups
aws ec2 describe-security-groups --group-names sentinel-gateway-eks
```

## Monitoring Deployment

### CloudWatch Logs

Monitor EKS control plane logs:

```bash
aws logs describe-log-groups --log-group-name-prefix /aws/eks/sentinel
```

### EKS Cluster Health

```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check cluster info
kubectl cluster-info
kubectl get componentstatuses
```

### Application Health

```bash
# Check application status
kubectl get deployments --all-namespaces
kubectl get services --all-namespaces

# Test application endpoints
curl -f http://<alb-dns>/health
curl -f http://<alb-dns>/api/
```

## Scaling Considerations

### Horizontal Scaling

```bash
# Scale application pods
kubectl scale deployment gateway-service --replicas=5 -n gateway
kubectl scale deployment backend-service --replicas=3 -n backend

# Configure Horizontal Pod Autoscaler
kubectl autoscale deployment gateway-service --cpu-percent=70 --min=2 --max=10 -n gateway
```

### Cluster Scaling

```bash
# Update node group capacity
aws eks update-nodegroup-config \
  --cluster-name sentinel-gateway \
  --nodegroup-name sentinel-gateway-nodes \
  --scaling-config minSize=2,maxSize=5,desiredSize=3
```

## Security Validation

### Network Security Testing

```bash
# Test backend isolation (should fail)
curl -m 5 http://backend-pod-ip:80

# Test gateway accessibility (should succeed)
curl -f http://<alb-dns>/health

# Test cross-VPC communication (should succeed)
curl -f http://<alb-dns>/api/
```

### RBAC Testing

```bash
# Test service account permissions
kubectl auth can-i create pods --as=system:serviceaccount:backend:default

# Test network policy enforcement
kubectl exec -it test-pod -n gateway -- nc -zv backend-service.backend.svc.cluster.local 80
```

## Performance Testing

### Load Testing

```bash
# Install Apache Bench
sudo apt-get install apache2-utils

# Test gateway performance
ab -n 1000 -c 10 http://<alb-dns>/health

# Test backend connectivity
ab -n 500 -c 5 http://<alb-dns>/api/
```

### Resource Monitoring

```bash
# Monitor resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Check resource limits
kubectl describe pod <pod-name> -n <namespace>
```

## Cleanup

To destroy all resources:

```bash
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh
```

This will:

- Delete Kubernetes applications
- Destroy Terraform infrastructure
- Clean up local kubectl contexts
- Remove temporary files

**Warning**: This action cannot be undone. Make sure you have backups of any important data.
