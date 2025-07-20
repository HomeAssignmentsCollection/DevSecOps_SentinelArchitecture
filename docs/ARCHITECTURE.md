# Sentinel Architecture Deep Dive

## Overview

The Sentinel split architecture implements a secure, scalable microservices platform using AWS EKS with two isolated VPCs connected via VPC peering. This design follows AWS Well-Architected Framework principles and enterprise security best practices.

## Network Architecture

### VPC Design

#### Gateway VPC (10.0.0.0/16)
- **Purpose**: Internet-facing services, API gateways, load balancers
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (NAT Gateways only)
- **Private Subnets**: 10.0.11.0/24, 10.0.12.0/24 (EKS nodes)
- **Internet Gateway**: Attached for outbound internet access
- **NAT Gateway**: Single gateway for cost optimization

#### Backend VPC (10.1.0.0/16)
- **Purpose**: Internal services, databases, sensitive processing
- **Public Subnets**: 10.1.1.0/24, 10.1.2.0/24 (NAT Gateways only)
- **Private Subnets**: 10.1.11.0/24, 10.1.12.0/24 (EKS nodes)
- **Internet Gateway**: Attached for outbound internet access
- **NAT Gateway**: Single gateway for cost optimization

### VPC Peering

```
Gateway VPC (10.0.0.0/16) ←→ Backend VPC (10.1.0.0/16)
```

- **Bidirectional routing**: Both VPCs can communicate privately
- **DNS resolution**: Cross-VPC DNS resolution enabled
- **Security**: Traffic filtered by security groups and NACLs

## EKS Cluster Architecture

### Gateway Cluster
- **Name**: sentinel-gateway
- **Version**: Kubernetes 1.28+
- **Node Groups**: Managed node groups in private subnets
- **Instance Types**: t3.medium (cost-optimized)
- **Scaling**: 1-3 nodes with auto-scaling
- **Networking**: AWS VPC CNI with pod networking

### Backend Cluster
- **Name**: sentinel-backend
- **Version**: Kubernetes 1.28+
- **Node Groups**: Managed node groups in private subnets
- **Instance Types**: t3.medium (cost-optimized)
- **Scaling**: 1-3 nodes with auto-scaling
- **Networking**: AWS VPC CNI with pod networking

## Security Architecture

### Defense in Depth

```
Internet → ALB → Security Groups → NACLs → Network Policies → Pod Security
```

#### Layer 1: AWS Security Groups
- **Gateway EKS**: Allow HTTP/HTTPS from internet, all from backend VPC
- **Backend EKS**: Allow traffic only from gateway VPC
- **ALB**: Allow HTTP/HTTPS from internet

#### Layer 2: Network ACLs
- **Private Subnets**: Allow traffic within VPC CIDR blocks
- **Public Subnets**: Allow internet traffic for NAT gateways

#### Layer 3: Kubernetes Network Policies
- **Backend Namespace**: Deny all ingress except from gateway
- **Gateway Namespace**: Allow internet ingress, backend egress

#### Layer 4: Pod Security
- **Security Contexts**: Non-root users, read-only filesystems
- **Resource Limits**: CPU and memory constraints
- **Health Checks**: Liveness and readiness probes

### IAM Security Model

#### EKS Cluster Roles
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

#### Node Group Roles
- **AmazonEKSWorkerNodePolicy**: Basic EKS worker permissions
- **AmazonEKS_CNI_Policy**: VPC CNI networking
- **AmazonEC2ContainerRegistryReadOnly**: ECR image pulls

## Application Architecture

### Gateway Service

#### Components
- **Nginx Reverse Proxy**: Routes traffic to backend services
- **Load Balancer**: AWS ALB with health checks
- **Service Discovery**: Kubernetes DNS resolution

#### Configuration
```nginx
upstream backend {
    server backend-service.backend.svc.cluster.local:80;
}

server {
    listen 80;
    location /api/ {
        proxy_pass http://backend/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Backend Service

#### Components
- **Nginx Web Server**: Serves static content and APIs
- **ClusterIP Service**: Internal-only service exposure
- **ConfigMap**: Application configuration

#### Security Features
- **No External Access**: ClusterIP service type
- **Network Policies**: Ingress restrictions
- **Resource Limits**: CPU and memory constraints

## Data Flow

### Request Processing

1. **Internet Request** → ALB (Gateway VPC)
2. **ALB** → Gateway Pod (Private Subnet)
3. **Gateway Pod** → DNS Resolution → Backend Service
4. **VPC Peering** → Backend VPC
5. **Backend Pod** → Process Request
6. **Response Path**: Reverse of above

### Service Discovery

```
backend-service.backend.svc.cluster.local
│
├── backend: Namespace
├── svc: Service
├── cluster.local: Cluster domain
└── Resolution: 10.1.x.x (Backend VPC IP)
```

## Monitoring and Observability

### Metrics Collection
- **EKS Control Plane Logs**: API server, audit, authenticator
- **Node Metrics**: CPU, memory, disk, network
- **Pod Metrics**: Resource usage, restart counts
- **Application Metrics**: Custom business metrics

### Logging Strategy
- **Container Logs**: stdout/stderr to CloudWatch
- **Audit Logs**: EKS API server audit logs
- **VPC Flow Logs**: Network traffic analysis
- **ALB Access Logs**: Request patterns and errors

### Health Monitoring
- **Liveness Probes**: Container health checks
- **Readiness Probes**: Service availability
- **ALB Health Checks**: Target group monitoring
- **EKS Cluster Health**: Control plane status

## Disaster Recovery

### Backup Strategy
- **EKS Cluster**: ETCD snapshots (managed by AWS)
- **Application Data**: Persistent volume snapshots
- **Configuration**: GitOps repository backup
- **Terraform State**: S3 versioning and cross-region replication

### Recovery Procedures
1. **Infrastructure**: Terraform apply from backup state
2. **Applications**: GitOps deployment from repository
3. **Data**: Restore from EBS snapshots
4. **Validation**: Automated testing pipeline

## Performance Optimization

### Scaling Strategies
- **Horizontal Pod Autoscaler**: Scale pods based on CPU/memory
- **Vertical Pod Autoscaler**: Right-size resource requests
- **Cluster Autoscaler**: Add/remove nodes automatically
- **Load Balancer**: Distribute traffic across healthy targets

### Resource Management
- **Resource Requests**: Guaranteed CPU and memory
- **Resource Limits**: Maximum CPU and memory usage
- **Quality of Service**: Guaranteed, Burstable, BestEffort
- **Node Affinity**: Optimize pod placement

## Cost Optimization

### Current Optimizations
- **Single NAT Gateway**: Reduce NAT costs by 50%
- **t3.medium Instances**: Cost-effective for development
- **Managed Node Groups**: Reduce operational overhead
- **Auto Scaling**: Scale down during off-hours

### Future Optimizations
- **Spot Instances**: 60-90% cost reduction for non-critical workloads
- **Reserved Instances**: 30-40% savings with 1-year commitment
- **Fargate**: Serverless containers for variable workloads
- **Graviton Instances**: ARM-based instances for better price/performance

## Compliance and Governance

### Security Standards
- **SOC 2 Type II**: Security controls and monitoring
- **ISO 27001**: Information security management
- **PCI DSS**: Payment card industry compliance
- **GDPR**: Data protection and privacy

### Policy Enforcement
- **Open Policy Agent**: Kubernetes admission control
- **AWS Config**: Resource compliance monitoring
- **Service Control Policies**: AWS account governance
- **Terraform Sentinel**: Infrastructure policy as code

## Future Enhancements

### Service Mesh Integration
- **Istio**: Advanced traffic management and security
- **AWS App Mesh**: Managed service mesh
- **mTLS**: Mutual TLS between services
- **Circuit Breaking**: Fault tolerance patterns

### GitOps Implementation
- **ArgoCD**: Declarative GitOps for Kubernetes
- **Flux**: GitOps toolkit for Kubernetes
- **Helm**: Package management for Kubernetes
- **Kustomize**: Configuration management

### Multi-Region Deployment
- **Cross-Region Replication**: Data and configuration sync
- **Global Load Balancer**: Route 53 health checks
- **Disaster Recovery**: Automated failover procedures
- **Data Sovereignty**: Regional data compliance
