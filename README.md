# Sentinel DevSecOps Challenge: Split Architecture Implementation

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-623CE4?logo=terraform)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes)](https://kubernetes.io)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A production-ready proof-of-concept implementation of Rapyd Sentinel's split architecture using Infrastructure as Code (Terraform), Amazon EKS, and GitHub Actions CI/CD. This project demonstrates enterprise-grade security, modularity, and operational excellence.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                  Internet                                        │
└─────────────────────────┬───────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Application Load Balancer                                │
└─────────────────────────┬───────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                     Gateway VPC (10.0.0.0/16)                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                 │
│  │   Public AZ-A   │  │   Public AZ-B   │  │                 │                 │
│  │   10.0.1.0/24   │  │   10.0.2.0/24   │  │   NAT Gateway   │                 │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                 │
│  ┌─────────────────┐  ┌─────────────────┐                                      │
│  │  Private AZ-A   │  │  Private AZ-B   │     ┌─────────────────┐              │
│  │  10.0.11.0/24   │  │  10.0.12.0/24   │     │  Gateway EKS    │              │
│  │                 │  │                 │     │    Cluster      │              │
│  │  Gateway Pods   │  │  Gateway Pods   │     └─────────────────┘              │
│  └─────────────────┘  └─────────────────┘                                      │
└─────────────────────────┬───────────────────────────────────────────────────────┘
                          │ VPC Peering
                          ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                     Backend VPC (10.1.0.0/16)                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐                 │
│  │   Public AZ-A   │  │   Public AZ-B   │  │                 │                 │
│  │   10.1.1.0/24   │  │   10.1.2.0/24   │  │   NAT Gateway   │                 │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘                 │
│  ┌─────────────────┐  ┌─────────────────┐                                      │
│  │  Private AZ-A   │  │  Private AZ-B   │     ┌─────────────────┐              │
│  │  10.1.11.0/24   │  │  10.1.12.0/24   │     │  Backend EKS    │              │
│  │                 │  │                 │     │    Cluster      │              │
│  │  Backend Pods   │  │  Backend Pods   │     └─────────────────┘              │
│  └─────────────────┘  └─────────────────┘                                      │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### Key Components

- **Gateway Layer (Public)**: Hosts internet-facing APIs and proxies in VPC `10.0.0.0/16`
- **Backend Layer (Private)**: Runs internal processing and sensitive services in VPC `10.1.0.0/16`
- **VPC Peering**: Secure private communication between isolated environments
- **EKS Clusters**: Managed Kubernetes clusters with auto-scaling node groups
- **Network Security**: Security groups, NACLs, and Kubernetes NetworkPolicies

## 🚀 Quick Start Guide

### Prerequisites

Ensure you have the following tools installed:

```bash
# AWS CLI v2
aws --version

# Terraform >= 1.6.0
terraform --version

# kubectl >= 1.28.0
kubectl version --client

# Git
git --version
```

### Step 1: Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd devsecops-technical-challenge

# Configure AWS credentials
aws configure
# or
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

### Step 2: Deploy Infrastructure

```bash
# Setup Terraform backend (first time only)
chmod +x scripts/setup-backend.sh
./scripts/setup-backend.sh

# Deploy complete infrastructure
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### Step 3: Verify Deployment

```bash
# Test connectivity and security
chmod +x scripts/test-connectivity.sh
./scripts/test-connectivity.sh
```

### Step 4: Access Application

After deployment, access your application at the provided ALB DNS:

- **Main Gateway**: `http://<alb-dns>/`
- **Backend Proxy**: `http://<alb-dns>/api/`
- **Health Check**: `http://<alb-dns>/health`

## 📁 Repository Structure

```
├── .github/workflows/          # GitHub Actions CI/CD pipelines
│   ├── terraform-plan.yml      # PR validation workflow
│   ├── terraform-apply.yml     # Main branch deployment
│   └── k8s-deploy.yml         # Application deployment
├── infrastructure/            # Terraform root module
│   ├── main.tf               # Main infrastructure configuration
│   ├── variables.tf          # Input variables
│   ├── outputs.tf            # Output values
│   ├── backend.tf            # S3 backend setup
│   └── terraform.tfvars      # Variable values
├── modules/                  # Reusable Terraform modules
│   ├── vpc/                 # VPC, subnets, routing
│   ├── eks/                 # EKS clusters and node groups
│   ├── security/            # Security groups and NACLs
│   └── networking/          # VPC peering and routing
├── k8s-manifests/           # Kubernetes application manifests
│   ├── backend/             # Backend service (private)
│   └── gateway/             # Gateway service (public)
├── scripts/                 # Deployment and utility scripts
│   ├── deploy.sh           # Complete deployment script
│   ├── test-connectivity.sh # Connectivity testing
│   ├── setup-backend.sh    # Terraform backend setup
│   └── cleanup.sh          # Infrastructure cleanup
└── docs/                   # Additional documentation
```

## 🔒 Security Model

### Network Security

#### VPC Isolation

- **Gateway VPC**: `10.0.0.0/16` - Internet-facing services
- **Backend VPC**: `10.1.0.0/16` - Internal services only
- **No Direct Internet Access**: Backend VPC has no direct internet connectivity

#### Security Groups (Least Privilege)

**Gateway EKS Security Group**:

- ✅ Inbound: HTTP/HTTPS from internet (0.0.0.0/0:80,443)
- ✅ Inbound: All traffic from backend VPC (10.1.0.0/16)
- ✅ Outbound: All traffic (for downloads, API calls)

**Backend EKS Security Group**:

- ✅ Inbound: All traffic from gateway VPC only (10.0.0.0/16)
- ✅ Inbound: Internal VPC communication (10.1.0.0/16)
- ❌ No direct internet inbound access
- ✅ Outbound: All traffic (for downloads, updates)

#### Network Policies (Kubernetes)

**Backend Network Policy**:

```yaml
# Only allow ingress from gateway namespace
# Deny all other cross-namespace communication
# Allow DNS and outbound HTTPS
```

**Gateway Network Policy**:

```yaml
# Allow ingress from internet (via ALB)
# Allow egress to backend VPC
# Allow DNS and outbound HTTPS
```

### IAM Security

- **EKS Cluster Roles**: Minimal permissions for cluster management
- **Node Group Roles**: EC2, ECR, and CNI permissions only
- **GitHub OIDC**: No long-lived access keys in CI/CD
- **Principle of Least Privilege**: All roles follow minimal access patterns

## 🌐 Communication Flow

### Request Path Analysis

```
1. Internet Request → ALB (Gateway VPC)
2. ALB → Gateway Pod (Private Subnet)
3. Gateway Pod → VPC Peering → Backend Pod
4. Backend Pod → Response → Gateway Pod
5. Gateway Pod → ALB → Internet
```

### Service Discovery

- **Internal DNS**: `backend-service.backend.svc.cluster.local`
- **Cross-Cluster Communication**: Via VPC peering and service endpoints
- **Load Balancing**: Kubernetes services with multiple pod replicas

### Error Handling

- **Timeout Configuration**: 5s connect, 10s read/write
- **Health Checks**: Liveness and readiness probes
- **Graceful Degradation**: Nginx upstream failover
- **Circuit Breaking**: Automatic retry with exponential backoff

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

#### 1. Terraform Plan (PR Validation)

```yaml
Triggers: Pull requests to main
Steps:
  - Terraform format check
  - Terraform validate
  - TFLint static analysis
  - Checkov security scanning
  - Terraform plan with artifact upload
  - PR comment with plan results
```

#### 2. Terraform Apply (Main Branch)

```yaml
Triggers: Push to main branch
Steps:
  - Terraform init
  - Terraform plan
  - Terraform apply with auto-approval
  - Output capture and artifact storage
  - Notification on success/failure
```

#### 3. Kubernetes Deployment

```yaml
Triggers: Terraform completion or K8s manifest changes
Steps:
  - Manifest validation with kubectl
  - Deploy to backend cluster first
  - Deploy to gateway cluster second
  - Connectivity testing
  - Rollback capability
```

### Security Practices

- **GitHub OIDC Federation**: No stored AWS credentials
- **Branch Protection**: Require PR reviews for infrastructure changes
- **Secret Management**: All sensitive values in GitHub Secrets
- **Signed Commits**: Optional but recommended for audit trail

### GitHub Actions Setup

To enable automated deployments, you need to configure AWS OIDC authentication:

1. **Quick Setup** (Recommended):

   ```bash
   chmod +x scripts/setup-github-actions.sh
   ./scripts/setup-github-actions.sh
   ```

2. **Manual Setup**: Follow the detailed guide in [docs/GITHUB_ACTIONS_SETUP.md](docs/GITHUB_ACTIONS_SETUP.md)

The setup script will:

- Create AWS IAM OIDC provider
- Create IAM role with necessary permissions
- Provide the role ARN for GitHub secrets configuration

## 💰 Cost Analysis

### Monthly Cost Breakdown (us-west-2)

| Component | Quantity | Unit Cost | Monthly Cost |
|-----------|----------|-----------|--------------|
| **EKS Clusters** | 2 | $0.10/hour | $144.00 |
| **EC2 Instances (t3.medium)** | 2-6 nodes | $0.0416/hour | $60.00-180.00 |
| **NAT Gateways** | 2 | $0.045/hour + data | $65.00 |
| **Application Load Balancer** | 1 | $0.0225/hour | $16.20 |
| **VPC Peering** | 1 | $0.01/GB transferred | $5.00-20.00 |
| **S3 (Terraform State)** | 1 bucket | $0.023/GB | $1.00 |
| **DynamoDB (State Locking)** | 1 table | Pay-per-request | $1.00 |

**Total Estimated Monthly Cost: $292.20 - $432.20**

### Cost Optimization Strategies

1. **Single NAT Gateway**: Reduces NAT costs by 50% (implemented)
2. **Spot Instances**: Can reduce EC2 costs by 60-90%
3. **Reserved Instances**: 1-year commitment saves 30-40%
4. **Auto Scaling**: Scale down during off-hours
5. **Cluster Autoscaler**: Automatic node scaling based on demand

### Scaling Considerations

- **Horizontal Pod Autoscaler**: Scale pods based on CPU/memory
- **Vertical Pod Autoscaler**: Right-size pod resource requests
- **Cluster Autoscaler**: Add/remove nodes automatically
- **Multi-AZ**: High availability with automatic failover

## 🧪 Testing and Validation

### Automated Tests

```bash
# Infrastructure validation
terraform validate
terraform plan
checkov -f infrastructure/

# Connectivity testing
./scripts/test-connectivity.sh

# Security validation
kubectl get networkpolicy --all-namespaces
kubectl get svc --all-namespaces
```

### Manual Verification

1. **Backend Isolation**: Verify backend service is not accessible from internet
2. **Cross-VPC Communication**: Test gateway → backend connectivity
3. **Load Balancer Health**: Check ALB target group health
4. **DNS Resolution**: Verify service discovery across clusters
5. **Security Groups**: Validate ingress/egress rules

### Security Testing

```bash
# Test backend accessibility (should fail)
curl -f http://backend-service-direct-ip/ # Should timeout/fail

# Test gateway accessibility (should succeed)
curl -f http://<alb-dns>/health # Should return "healthy"

# Test cross-VPC communication (should succeed)
curl -f http://<alb-dns>/api/ # Should return backend response
```

## 🚨 Production Readiness Assessment

### Current Implementation ✅

- ✅ Infrastructure as Code with Terraform
- ✅ Multi-AZ deployment for high availability
- ✅ VPC isolation with secure peering
- ✅ EKS clusters with managed node groups
- ✅ Security groups with least privilege
- ✅ Network policies for pod-level security
- ✅ CI/CD pipeline with automated validation
- ✅ Comprehensive documentation

### Missing for Production 🔄

#### Observability Stack

- **Monitoring**: Prometheus + Grafana
- **Logging**: ELK Stack or CloudWatch Logs
- **Tracing**: Jaeger or AWS X-Ray
- **Alerting**: PagerDuty or Slack integration

#### Security Hardening

- **TLS/mTLS**: End-to-end encryption
- **Pod Security Standards**: Enforce security contexts
- **Image Scanning**: Trivy or Clair integration
- **Secrets Management**: AWS Secrets Manager or Vault

#### Operational Excellence

- **Backup Strategy**: EBS snapshots, ETCD backups
- **Disaster Recovery**: Multi-region deployment
- **GitOps**: ArgoCD or Flux for application deployment
- **Service Mesh**: Istio or AWS App Mesh

#### Compliance & Governance

- **Policy as Code**: Open Policy Agent (OPA)
- **Compliance Scanning**: AWS Config Rules
- **Audit Logging**: CloudTrail integration
- **Resource Tagging**: Comprehensive tagging strategy

## 🛣️ Next Steps & Roadmap

### Phase 1: Security Enhancement (Week 1-2)

- [ ] Implement TLS termination at ALB
- [ ] Add mTLS between services
- [ ] Integrate AWS Secrets Manager
- [ ] Enable Pod Security Standards

### Phase 2: Observability (Week 3-4)

- [ ] Deploy Prometheus monitoring stack
- [ ] Configure Grafana dashboards
- [ ] Implement centralized logging
- [ ] Set up distributed tracing

### Phase 3: GitOps & Automation (Week 5-6)

- [ ] Implement ArgoCD for application deployment
- [ ] Add automated security scanning
- [ ] Configure policy enforcement with OPA
- [ ] Implement blue-green deployments

### Phase 4: Multi-Environment (Week 7-8)

- [ ] Create staging environment
- [ ] Implement environment promotion pipeline
- [ ] Add integration testing
- [ ] Configure disaster recovery

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Troubleshooting

### Common Issues

**Issue**: Terraform backend initialization fails

```bash
# Solution: Run backend setup script first
./scripts/setup-backend.sh
```

**Issue**: EKS cluster creation timeout

```bash
# Solution: Check AWS service limits and IAM permissions
aws eks describe-cluster --name sentinel-gateway
```

**Issue**: LoadBalancer not getting external IP

```bash
# Solution: Check security groups and subnet tags
kubectl describe svc gateway-service -n gateway
```

**Issue**: Cross-VPC communication fails

```bash
# Solution: Verify VPC peering and route tables
aws ec2 describe-vpc-peering-connections
```

### Support

For issues and questions:

- 📧 Email: [your-email@company.com]
- 💬 Slack: #devsecops-sentinel
- 📖 Wiki: [Internal Documentation]

---

**Built with ❤️ by the DevSecOps Team**
