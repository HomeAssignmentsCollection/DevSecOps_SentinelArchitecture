# Architecture Diagrams and Technical Specifications

## High-Level Architecture

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                    Load Balancer                           │
│                 (Public-facing)                            │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                    Gateway VPC                             │
│  ┌─────────────────┐    ┌─────────────────┐              │
│  │   EKS Gateway   │    │   Proxy Service │              │
│  │     Cluster     │    │   (NGINX/Node)  │              │
│  └─────────────────┘    └─────────────────┘              │
│           │                       │                       │
│           └───────────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
    │
    ▼ (VPC Peering)
┌─────────────────────────────────────────────────────────────┐
│                    Backend VPC                             │
│  ┌─────────────────┐    ┌─────────────────┐              │
│  │   EKS Backend   │    │  Backend Service│              │
│  │     Cluster     │    │  (Web Server)   │              │
│  └─────────────────┘    └─────────────────┘              │
│           │                       │                       │
│           └───────────────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

## Network Architecture

### VPC Configuration

```
Gateway VPC (10.0.0.0/16)
├── Public Subnet A (10.0.1.0/24) - us-east-2a
│   ├── EKS Gateway Cluster
│   └── Load Balancer
└── Public Subnet B (10.0.2.0/24) - us-east-2b
    ├── EKS Gateway Cluster
    └── Load Balancer

Backend VPC (10.1.0.0/16)
├── Private Subnet A (10.1.1.0/24) - us-east-2a
│   └── EKS Backend Cluster
└── Private Subnet B (10.1.2.0/24) - us-east-2b
    └── EKS Backend Cluster
```

### Security Architecture

```
Security Groups Configuration:

Gateway VPC Security Group:
├── Inbound Rules:
│   ├── Port 80 (HTTP) - 0.0.0.0/0
│   ├── Port 443 (HTTPS) - 0.0.0.0/0
│   └── Port 22 (SSH) - 0.0.0.0/0 (for admin)
└── Outbound Rules:
    └── All traffic - 0.0.0.0/0

Backend VPC Security Group:
├── Inbound Rules:
│   ├── Port 80 (HTTP) - Gateway VPC CIDR only
│   └── Port 443 (HTTPS) - Gateway VPC CIDR only
└── Outbound Rules:
    └── All traffic - 0.0.0.0/0
```

## CI/CD Pipeline Architecture

```
GitHub Repository
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                 GitHub Actions Workflows                    │
│  ┌─────────────────┐    ┌─────────────────┐              │
│  │ Terraform Plan  │    │ Terraform Apply │              │
│  │   (PR Trigger)  │    │ (Main Trigger)  │              │
│  └─────────────────┘    └─────────────────┘              │
│           │                       │                       │
│           └───────────────────────┘                       │
│                           │                               │
│                           ▼                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │           Kubernetes Deployment                    │   │
│  │         (Manifest Validation & Apply)             │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                    AWS Infrastructure                      │
│  ┌─────────────────┐    ┌─────────────────┐              │
│  │   VPC Gateway   │◄──►│   VPC Backend   │              │
│  │   (Public)      │    │   (Private)     │              │
│  └─────────────────┘    └─────────────────┘              │
│           │                       │                       │
│           ▼                       ▼                       │
│  ┌─────────────────┐    ┌─────────────────┐              │
│  │  EKS Gateway    │    │  EKS Backend    │              │
│  │    Cluster      │    │    Cluster      │              │
│  └─────────────────┘    └─────────────────┘              │
└─────────────────────────────────────────────────────────────┘
```

## Application Flow

### Request Flow

```
1. Client Request
   │
   ▼
2. Load Balancer (Gateway VPC)
   │
   ▼
3. Proxy Service (EKS Gateway)
   │
   ▼
4. VPC Peering Connection
   │
   ▼
5. Backend Service (EKS Backend)
   │
   ▼
6. Response Flow (Reverse)
```

### Data Flow Security

```
Internet Traffic
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                 Security Layers                            │
│  ┌─────────────────┐    ┌─────────────────┐              │
│  │   Load Balancer │    │   Security      │              │
│  │   (HTTPS/TLS)   │    │   Groups        │              │
│  └─────────────────┘    └─────────────────┘              │
│           │                       │                       │
│           ▼                       ▼                       │
│  ┌─────────────────┐    ┌─────────────────┐              │
│  │   Network       │    │   Kubernetes    │              │
│  │   Policies      │    │   NetworkPolicy │              │
│  └─────────────────┘    └─────────────────┘              │
│           │                       │                       │
│           ▼                       ▼                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Application Security                   │   │
│  │         (Pod-to-Pod Communication)                 │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Infrastructure Components

### Terraform Modules Structure

```
modules/
├── vpc/
│   ├── main.tf          # VPC, subnets, route tables
│   ├── variables.tf     # Input variables
│   └── outputs.tf       # Output values
├── eks/
│   ├── main.tf          # EKS cluster configuration
│   ├── variables.tf     # Input variables
│   └── outputs.tf       # Output values
├── networking/
│   ├── main.tf          # VPC peering, security groups
│   ├── variables.tf     # Input variables
│   └── outputs.tf       # Output values
└── security/
    ├── main.tf          # IAM roles, policies
    ├── variables.tf     # Input variables
    └── outputs.tf       # Output values
```

### Kubernetes Manifests Structure

```
k8s-manifests/
├── gateway/
│   ├── namespace.yaml    # Gateway namespace
│   ├── deployment.yaml   # Proxy service deployment
│   ├── service.yaml      # Load balancer service
│   └── network-policy.yaml # Network policies
└── backend/
    ├── namespace.yaml    # Backend namespace
    ├── deployment.yaml   # Backend service deployment
    ├── service.yaml      # Cluster IP service
    └── network-policy.yaml # Network policies
```

## Security Model

### Defense in Depth

```
Layer 1: Network Security
├── VPC isolation
├── Security groups
├── Network ACLs
└── VPC peering controls

Layer 2: Container Security
├── Kubernetes NetworkPolicy
├── Pod security policies
├── RBAC (Role-Based Access Control)
└── Service accounts

Layer 3: Application Security
├── TLS/SSL encryption
├── Authentication/Authorization
├── Input validation
└── Secure coding practices

Layer 4: Infrastructure Security
├── IAM roles and policies
├── OIDC federation
├── Audit logging
└── Monitoring and alerting
```

### Compliance Considerations

```
Security Standards:
├── CIS AWS Foundations Benchmark
├── Kubernetes CIS Benchmark
├── NIST Cybersecurity Framework
└── SOC 2 Type II

Compliance Features:
├── Infrastructure as Code (audit trail)
├── Automated security scanning
├── Immutable infrastructure
├── Secret management
└── Backup and disaster recovery
```

## Scalability Considerations

### Horizontal Scaling

```
Application Scaling:
├── EKS cluster auto-scaling
├── Pod horizontal auto-scaling (HPA)
├── Load balancer distribution
└── Database read replicas

Infrastructure Scaling:
├── Multi-AZ deployment
├── Auto-scaling groups
├── Elastic IP management
└── Storage auto-scaling
```

### Performance Optimization

```
Network Optimization:
├── VPC peering for low latency
├── Load balancer health checks
├── Connection pooling
└── CDN integration

Resource Optimization:
├── Right-sizing instances
├── Spot instances for cost savings
├── Resource quotas
└── Monitoring and alerting
``` 