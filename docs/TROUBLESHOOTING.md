# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with the Sentinel DevSecOps infrastructure.

## Common Issues and Solutions

### 1. Terraform Issues

#### Issue: Backend Initialization Fails
```
Error: Failed to get existing workspaces: S3 bucket does not exist
```

**Diagnosis:**
```bash
# Check if bucket exists
aws s3 ls s3://sentinel-terraform-state-bucket-*

# Check AWS credentials
aws sts get-caller-identity
```

**Solution:**
```bash
# Run backend setup script
./scripts/setup-backend.sh

# Or manually create backend resources
cd infrastructure
terraform init
terraform apply -target=aws_s3_bucket.terraform_state
```

#### Issue: State Lock Timeout
```
Error: Error acquiring the state lock: ConditionalCheckFailedException
```

**Diagnosis:**
```bash
# Check DynamoDB table
aws dynamodb scan --table-name sentinel-terraform-locks
```

**Solution:**
```bash
# Force unlock (use with caution)
terraform force-unlock <lock-id>

# Or delete the lock item from DynamoDB
aws dynamodb delete-item \
  --table-name sentinel-terraform-locks \
  --key '{"LockID":{"S":"<lock-id>"}}'
```

#### Issue: Resource Already Exists
```
Error: resource already exists
```

**Solution:**
```bash
# Import existing resource
terraform import aws_vpc.main vpc-12345678

# Or remove from state and recreate
terraform state rm aws_vpc.main
terraform apply
```

### 2. EKS Cluster Issues

#### Issue: Cluster Creation Timeout
```
Error: timeout while waiting for state to become 'ACTIVE'
```

**Diagnosis:**
```bash
# Check cluster status
aws eks describe-cluster --name sentinel-gateway

# Check CloudTrail for errors
aws logs filter-log-events \
  --log-group-name CloudTrail/EKSCluster \
  --start-time $(date -d '1 hour ago' +%s)000
```

**Solution:**
```bash
# Check service limits
aws service-quotas get-service-quota \
  --service-code eks \
  --quota-code L-1194D53C

# Verify IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::ACCOUNT:role/eks-cluster-role \
  --action-names eks:CreateCluster
```

#### Issue: Node Group Not Ready
```
Error: nodes are not ready
```

**Diagnosis:**
```bash
# Check node group status
aws eks describe-nodegroup \
  --cluster-name sentinel-gateway \
  --nodegroup-name sentinel-gateway-nodes

# Check node status
kubectl get nodes -o wide
kubectl describe node <node-name>
```

**Solution:**
```bash
# Check security groups
aws ec2 describe-security-groups \
  --group-ids sg-12345678

# Verify subnet configuration
aws ec2 describe-subnets \
  --subnet-ids subnet-12345678

# Check IAM role permissions
aws iam get-role --role-name NodeInstanceRole
```

### 3. Networking Issues

#### Issue: LoadBalancer Not Getting External IP
```
Service "gateway-service" has no external IP
```

**Diagnosis:**
```bash
# Check service status
kubectl describe svc gateway-service -n gateway

# Check AWS Load Balancer Controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

**Solution:**
```bash
# Install AWS Load Balancer Controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=sentinel-gateway

# Check subnet tags
aws ec2 describe-subnets \
  --filters "Name=tag:kubernetes.io/role/elb,Values=1"

# Verify security groups
kubectl get svc gateway-service -n gateway -o yaml
```

#### Issue: Cross-VPC Communication Fails
```
Error: connection timeout to backend service
```

**Diagnosis:**
```bash
# Check VPC peering status
aws ec2 describe-vpc-peering-connections

# Check route tables
aws ec2 describe-route-tables

# Test DNS resolution
kubectl exec -it test-pod -- nslookup backend-service.backend.svc.cluster.local
```

**Solution:**
```bash
# Verify peering connection is active
aws ec2 accept-vpc-peering-connection \
  --vpc-peering-connection-id pcx-12345678

# Check route table entries
aws ec2 create-route \
  --route-table-id rtb-12345678 \
  --destination-cidr-block 10.1.0.0/16 \
  --vpc-peering-connection-id pcx-12345678

# Test connectivity
kubectl run test-pod --image=busybox --rm -it -- /bin/sh
# Inside pod: nc -zv backend-service.backend.svc.cluster.local 80
```

### 4. Application Issues

#### Issue: Pods Stuck in Pending State
```
Pod "backend-service-xxx" is in Pending state
```

**Diagnosis:**
```bash
# Check pod events
kubectl describe pod backend-service-xxx -n backend

# Check node resources
kubectl top nodes
kubectl describe nodes
```

**Solution:**
```bash
# Check resource requests vs available
kubectl get pods -n backend -o yaml | grep -A 5 resources

# Scale cluster if needed
aws eks update-nodegroup-config \
  --cluster-name sentinel-backend \
  --nodegroup-name sentinel-backend-nodes \
  --scaling-config minSize=2,maxSize=5,desiredSize=3
```

#### Issue: Pods CrashLoopBackOff
```
Pod "gateway-service-xxx" is in CrashLoopBackOff
```

**Diagnosis:**
```bash
# Check pod logs
kubectl logs gateway-service-xxx -n gateway --previous

# Check liveness/readiness probes
kubectl describe pod gateway-service-xxx -n gateway
```

**Solution:**
```bash
# Adjust probe settings
kubectl patch deployment gateway-service -n gateway -p '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "gateway",
          "livenessProbe": {
            "initialDelaySeconds": 60
          }
        }]
      }
    }
  }
}'
```

### 5. Security Issues

#### Issue: Network Policy Blocking Traffic
```
Error: connection refused from gateway to backend
```

**Diagnosis:**
```bash
# Check network policies
kubectl get networkpolicy -n backend -o yaml

# Test without network policy
kubectl delete networkpolicy backend-network-policy -n backend
```

**Solution:**
```bash
# Update network policy to allow traffic
kubectl apply -f - <<EOF
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
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: gateway
    ports:
    - protocol: TCP
      port: 80
EOF
```

#### Issue: Security Group Rules Too Restrictive
```
Error: connection timeout
```

**Diagnosis:**
```bash
# Check security group rules
aws ec2 describe-security-groups \
  --group-ids sg-12345678

# Test connectivity
telnet <target-ip> <port>
```

**Solution:**
```bash
# Add temporary rule for debugging
aws ec2 authorize-security-group-ingress \
  --group-id sg-12345678 \
  --protocol tcp \
  --port 80 \
  --source-group sg-87654321

# Remove after debugging
aws ec2 revoke-security-group-ingress \
  --group-id sg-12345678 \
  --protocol tcp \
  --port 80 \
  --source-group sg-87654321
```

## Debugging Commands

### Infrastructure Debugging

```bash
# Terraform debugging
export TF_LOG=DEBUG
terraform plan

# AWS CLI debugging
aws --debug eks describe-cluster --name sentinel-gateway

# Check resource limits
aws service-quotas list-service-quotas --service-code eks
```

### Kubernetes Debugging

```bash
# Cluster information
kubectl cluster-info
kubectl get componentstatuses

# Node debugging
kubectl get nodes -o wide
kubectl describe node <node-name>
kubectl top nodes

# Pod debugging
kubectl get pods --all-namespaces -o wide
kubectl describe pod <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous

# Service debugging
kubectl get svc --all-namespaces
kubectl describe svc <service-name> -n <namespace>
kubectl get endpoints <service-name> -n <namespace>

# Network debugging
kubectl get networkpolicy --all-namespaces
kubectl describe networkpolicy <policy-name> -n <namespace>
```

### Application Debugging

```bash
# Test connectivity
kubectl run debug-pod --image=busybox --rm -it -- /bin/sh

# Inside debug pod:
nslookup backend-service.backend.svc.cluster.local
nc -zv backend-service.backend.svc.cluster.local 80
wget -qO- http://backend-service.backend.svc.cluster.local/

# Test from outside cluster
curl -v http://<alb-dns>/health
curl -v http://<alb-dns>/api/
```

## Monitoring and Alerting

### CloudWatch Logs

```bash
# EKS control plane logs
aws logs describe-log-groups --log-group-name-prefix /aws/eks

# Application logs
aws logs filter-log-events \
  --log-group-name /aws/eks/sentinel-gateway/cluster \
  --filter-pattern "ERROR"
```

### Metrics and Monitoring

```bash
# Node metrics
kubectl top nodes

# Pod metrics
kubectl top pods --all-namespaces

# Custom metrics (if Prometheus is installed)
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Access http://localhost:9090
```

## Performance Issues

### High CPU Usage

```bash
# Check pod CPU usage
kubectl top pods --all-namespaces --sort-by=cpu

# Check node CPU usage
kubectl top nodes

# Scale horizontally
kubectl scale deployment gateway-service --replicas=5 -n gateway

# Configure HPA
kubectl autoscale deployment gateway-service \
  --cpu-percent=70 --min=2 --max=10 -n gateway
```

### High Memory Usage

```bash
# Check memory usage
kubectl top pods --all-namespaces --sort-by=memory

# Check for memory leaks
kubectl describe pod <pod-name> -n <namespace>

# Adjust memory limits
kubectl patch deployment gateway-service -n gateway -p '
{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "gateway",
          "resources": {
            "limits": {
              "memory": "256Mi"
            }
          }
        }]
      }
    }
  }
}'
```

### Storage Issues

```bash
# Check disk usage
kubectl exec -it <pod-name> -n <namespace> -- df -h

# Check PV/PVC status
kubectl get pv,pvc --all-namespaces

# Resize volume if needed
kubectl patch pvc <pvc-name> -n <namespace> -p '
{
  "spec": {
    "resources": {
      "requests": {
        "storage": "100Gi"
      }
    }
  }
}'
```

## Recovery Procedures

### Cluster Recovery

```bash
# Recreate failed nodes
aws eks update-nodegroup-config \
  --cluster-name sentinel-gateway \
  --nodegroup-name sentinel-gateway-nodes \
  --scaling-config minSize=0,maxSize=5,desiredSize=0

# Wait for nodes to terminate, then scale back up
aws eks update-nodegroup-config \
  --cluster-name sentinel-gateway \
  --nodegroup-name sentinel-gateway-nodes \
  --scaling-config minSize=1,maxSize=5,desiredSize=2
```

### Application Recovery

```bash
# Restart deployment
kubectl rollout restart deployment/gateway-service -n gateway

# Rollback to previous version
kubectl rollout undo deployment/gateway-service -n gateway

# Check rollout status
kubectl rollout status deployment/gateway-service -n gateway
```

### Infrastructure Recovery

```bash
# Recreate infrastructure from Terraform
terraform destroy -target=<resource>
terraform apply -target=<resource>

# Restore from backup
aws s3 cp s3://backup-bucket/terraform.tfstate ./terraform.tfstate
terraform apply
```

## Getting Help

### Log Collection

```bash
# Collect all relevant logs
mkdir -p debug-logs

# Terraform logs
terraform show > debug-logs/terraform-state.txt

# Kubernetes logs
kubectl get all --all-namespaces > debug-logs/k8s-resources.txt
kubectl describe nodes > debug-logs/nodes.txt

# AWS resources
aws eks describe-cluster --name sentinel-gateway > debug-logs/eks-gateway.json
aws eks describe-cluster --name sentinel-backend > debug-logs/eks-backend.json
```

### Support Channels

- **Internal Documentation**: Check the docs/ directory
- **AWS Support**: For AWS-specific issues
- **Kubernetes Community**: For K8s-related problems
- **Terraform Community**: For infrastructure issues

### Escalation Process

1. **Level 1**: Check this troubleshooting guide
2. **Level 2**: Review logs and metrics
3. **Level 3**: Contact team lead or senior engineer
4. **Level 4**: Engage AWS support or vendor support
