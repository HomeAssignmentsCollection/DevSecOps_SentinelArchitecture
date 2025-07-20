# Sentinel Security Model

## Security Overview

The Sentinel architecture implements a comprehensive security model based on defense-in-depth principles, zero-trust networking, and least-privilege access controls. This document details the security measures implemented at each layer of the infrastructure.

## Network Security

### VPC Isolation

#### Gateway VPC Security
- **CIDR Block**: 10.0.0.0/16 (65,536 IP addresses)
- **Internet Access**: Direct via Internet Gateway
- **Outbound Traffic**: Via NAT Gateway for private subnets
- **Inbound Traffic**: Only through Application Load Balancer

#### Backend VPC Security
- **CIDR Block**: 10.1.0.0/16 (65,536 IP addresses)
- **Internet Access**: Outbound only via NAT Gateway
- **Inbound Traffic**: Only from Gateway VPC via peering
- **No Direct Internet**: Zero direct internet connectivity

### VPC Peering Security

```
Gateway VPC ←→ Backend VPC
10.0.0.0/16     10.1.0.0/16
```

- **Encrypted Transit**: All traffic encrypted in transit
- **Route Table Control**: Specific CIDR routing only
- **DNS Resolution**: Cross-VPC DNS enabled securely
- **No Transitive Routing**: Isolated communication path

### Security Groups (Stateful Firewall)

#### Gateway EKS Security Group
```yaml
Ingress Rules:
  - Port 80 (HTTP): 0.0.0.0/0 (ALB health checks)
  - Port 443 (HTTPS): 0.0.0.0/0 (ALB health checks)
  - All Ports: 10.1.0.0/16 (Backend VPC communication)
  - All Ports: Self (Node-to-node communication)

Egress Rules:
  - All Ports: 0.0.0.0/0 (Internet access for updates)
```

#### Backend EKS Security Group
```yaml
Ingress Rules:
  - All Ports: 10.0.0.0/16 (Gateway VPC only)
  - All Ports: 10.1.0.0/16 (Internal VPC communication)
  - All Ports: Self (Node-to-node communication)

Egress Rules:
  - All Ports: 0.0.0.0/0 (Internet access for updates)
```

#### ALB Security Group
```yaml
Ingress Rules:
  - Port 80 (HTTP): 0.0.0.0/0 (Public access)
  - Port 443 (HTTPS): 0.0.0.0/0 (Public access)

Egress Rules:
  - All Ports: 10.0.0.0/16 (Gateway VPC targets)
```

### Network ACLs (Stateless Firewall)

#### Private Subnet NACLs
```yaml
Inbound Rules:
  - Rule 100: Allow all from VPC CIDR
  - Rule 32767: Deny all (default)

Outbound Rules:
  - Rule 100: Allow all to 0.0.0.0/0
  - Rule 32767: Deny all (default)
```

## Kubernetes Security

### Network Policies

#### Backend Network Policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-network-policy
  namespace: backend
spec:
  podSelector:
    matchLabels:
      app: backend-service
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Allow from gateway VPC only
  - from: []
    ports:
    - protocol: TCP
      port: 80
  egress:
  # Allow DNS and HTTPS only
  - to: []
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 443
```

#### Gateway Network Policy
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: gateway-network-policy
  namespace: gateway
spec:
  podSelector:
    matchLabels:
      app: gateway-service
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Allow from internet via ALB
  - from: []
    ports:
    - protocol: TCP
      port: 80
  egress:
  # Allow to backend and internet
  - to: []
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
```

### Pod Security Standards

#### Security Contexts
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
```

#### Resource Limits
```yaml
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 100m
    memory: 128Mi
```

## IAM Security

### EKS Cluster IAM Roles

#### Cluster Service Role
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

**Attached Policies**:
- `AmazonEKSClusterPolicy`

#### Node Group IAM Role
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Attached Policies**:
- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`

### GitHub Actions OIDC

#### Trust Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:ORG/REPO:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

## Data Security

### Encryption at Rest

#### EKS Secrets Encryption
- **Provider**: AWS KMS
- **Key**: Customer-managed KMS key
- **Scope**: Kubernetes secrets, ConfigMaps
- **Rotation**: Automatic key rotation enabled

#### EBS Volume Encryption
- **Provider**: AWS KMS
- **Key**: AWS-managed or customer-managed
- **Scope**: All EKS node group volumes
- **Performance**: No performance impact

#### S3 State Encryption
- **Provider**: AES-256
- **Scope**: Terraform state files
- **Versioning**: Enabled with encryption
- **Access**: Restricted to CI/CD roles only

### Encryption in Transit

#### VPC Traffic
- **Internal**: Encrypted by default (AWS backbone)
- **Cross-VPC**: Encrypted via VPC peering
- **Internet**: TLS 1.2+ for all external communication

#### Application Layer
- **ALB to Pods**: HTTP (internal network)
- **Pod to Pod**: HTTP (internal network)
- **External APIs**: HTTPS/TLS 1.2+

## Access Control

### Kubernetes RBAC

#### Service Accounts
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend-service-account
  namespace: backend
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/backend-service-role
```

#### Role Bindings
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: backend-role-binding
  namespace: backend
subjects:
- kind: ServiceAccount
  name: backend-service-account
  namespace: backend
roleRef:
  kind: Role
  name: backend-role
  apiGroup: rbac.authorization.k8s.io
```

### AWS IAM Integration

#### EKS Auth ConfigMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: arn:aws:iam::ACCOUNT:role/NodeInstanceRole
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
```

## Monitoring and Auditing

### EKS Audit Logging

#### Enabled Log Types
- **API Server**: All API requests and responses
- **Audit**: Detailed audit trail of all actions
- **Authenticator**: Authentication attempts
- **Controller Manager**: Control plane component logs
- **Scheduler**: Pod scheduling decisions

#### Log Retention
- **CloudWatch**: 30 days retention
- **S3 Archive**: Long-term storage
- **Analysis**: CloudWatch Insights queries

### Security Monitoring

#### CloudTrail Integration
- **API Calls**: All AWS API calls logged
- **Data Events**: S3 and Lambda data events
- **Insights**: Automated anomaly detection
- **Alerts**: Real-time security notifications

#### VPC Flow Logs
- **Traffic Analysis**: All network traffic logged
- **Anomaly Detection**: Unusual traffic patterns
- **Compliance**: Network access auditing
- **Troubleshooting**: Network connectivity issues

## Incident Response

### Security Incident Workflow

1. **Detection**: Automated monitoring alerts
2. **Assessment**: Severity and impact analysis
3. **Containment**: Isolate affected resources
4. **Eradication**: Remove security threats
5. **Recovery**: Restore normal operations
6. **Lessons Learned**: Post-incident review

### Automated Response

#### Security Group Isolation
```bash
# Automatically isolate compromised instances
aws ec2 modify-instance-attribute \
  --instance-id i-1234567890abcdef0 \
  --groups sg-isolation-group
```

#### Pod Quarantine
```bash
# Isolate suspicious pods
kubectl label pod suspicious-pod quarantine=true
kubectl apply -f quarantine-network-policy.yaml
```

## Compliance

### Security Standards

#### SOC 2 Type II
- **Security**: Access controls and monitoring
- **Availability**: High availability and disaster recovery
- **Processing Integrity**: Data processing accuracy
- **Confidentiality**: Data protection measures
- **Privacy**: Personal data handling

#### ISO 27001
- **Information Security Management**: Systematic approach
- **Risk Assessment**: Regular security risk evaluation
- **Controls**: Technical and organizational measures
- **Continuous Improvement**: Regular security reviews

### Audit Requirements

#### Evidence Collection
- **Configuration**: Infrastructure as Code
- **Access Logs**: All system access logged
- **Change Management**: Git-based change tracking
- **Monitoring**: Continuous security monitoring

#### Reporting
- **Monthly**: Security posture reports
- **Quarterly**: Compliance assessment
- **Annual**: Third-party security audit
- **Ad-hoc**: Incident response reports

## Security Testing

### Automated Security Scanning

#### Infrastructure Scanning
```bash
# Terraform security scanning
checkov -f infrastructure/ --framework terraform

# Container image scanning
trivy image nginx:1.25-alpine

# Kubernetes manifest scanning
kube-score k8s-manifests/
```

#### Penetration Testing
- **External**: Quarterly third-party testing
- **Internal**: Monthly automated scanning
- **Application**: Continuous SAST/DAST
- **Infrastructure**: Regular vulnerability assessment

### Security Validation

#### Network Segmentation Testing
```bash
# Verify backend isolation
curl -f http://backend-service-ip/ # Should fail

# Verify gateway accessibility
curl -f http://alb-dns/health # Should succeed

# Verify cross-VPC communication
curl -f http://alb-dns/api/ # Should succeed
```

#### Access Control Testing
```bash
# Test RBAC permissions
kubectl auth can-i create pods --as=system:serviceaccount:backend:default

# Test network policies
kubectl exec -it test-pod -- nc -zv backend-service 80
```

## Security Recommendations

### Immediate Improvements
1. **TLS Termination**: Implement HTTPS at ALB
2. **mTLS**: Service-to-service encryption
3. **Secrets Management**: AWS Secrets Manager integration
4. **Image Scanning**: Automated vulnerability scanning

### Long-term Enhancements
1. **Service Mesh**: Istio for advanced security
2. **Zero Trust**: Implement zero-trust networking
3. **SIEM Integration**: Security information and event management
4. **Threat Intelligence**: Automated threat detection
