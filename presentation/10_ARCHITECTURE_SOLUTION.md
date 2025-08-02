# Архитектура Решения: Rapyd Sentinel DevSecOps

## Обзор Архитектуры

### Принципы Дизайна
- **Разделение ответственности**: Gateway и Backend в отдельных VPC
- **Безопасность в глубину**: Многоуровневая защита
- **Масштабируемость**: Горизонтальное масштабирование
- **Надежность**: Multi-AZ deployment
- **Операционное превосходство**: Автоматизация и мониторинг

## Сетевая Архитектура

### VPC Дизайн

```
┌─────────────────────────────────────────────────────────────────┐
│                        Internet                                 │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Application Load Balancer                    │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Gateway VPC (10.0.0.0/16)                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Public AZ-A   │  │   Public AZ-B   │  │                 │ │
│  │   10.0.1.0/24   │  │   10.0.2.0/24   │  │   NAT Gateway   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │  Private AZ-A   │  │  Private AZ-B   │     ┌─────────────┐ │
│  │  10.0.11.0/24   │  │  10.0.12.0/24   │     │ Gateway EKS │ │
│  │                 │  │                 │     │   Cluster   │ │
│  │  Gateway Pods   │  │  Gateway Pods   │     └─────────────┘ │
│  └─────────────────┘  └─────────────────┘                      │
└─────────────────────┬───────────────────────────────────────────┘
                      │ VPC Peering
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Backend VPC (10.1.0.0/16)                   │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │   Public AZ-A   │  │   Public AZ-B   │  │                 │ │
│  │   10.1.1.0/24   │  │   10.1.2.0/24   │  │   NAT Gateway   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│  ┌─────────────────┐  ┌─────────────────┐                      │
│  │  Private AZ-A   │  │  Private AZ-B   │     ┌─────────────┐ │
│  │  10.1.11.0/24   │  │  10.1.12.0/24   │     │ Backend EKS │ │
│  │                 │  │                 │     │   Cluster   │ │
│  │  Backend Pods   │  │  Backend Pods   │     └─────────────┘ │
│  └─────────────────┘  └─────────────────┘                      │
└─────────────────────────────────────────────────────────────────┘
```

### Компоненты Сети

#### Gateway VPC (10.0.0.0/16)
- **Назначение**: Интернет-ориентированные сервисы
- **Публичные Subnets**: NAT Gateways для исходящего трафика
- **Приватные Subnets**: EKS узлы и приложения
- **Internet Gateway**: Прямой доступ в интернет
- **Load Balancer**: AWS ALB для входящего трафика

#### Backend VPC (10.1.0.0/16)
- **Назначение**: Внутренние сервисы и обработка данных
- **Публичные Subnets**: Только NAT Gateways
- **Приватные Subnets**: EKS узлы и backend приложения
- **Изоляция**: Нет прямого доступа из интернета
- **Связь**: Только через VPC peering

#### VPC Peering
- **Тип**: VPC Peering Connection
- **Маршрутизация**: Двунаправленная связь
- **DNS**: Cross-VPC DNS resolution
- **Безопасность**: Фильтрация через security groups

## Kubernetes Архитектура

### EKS Кластеры

#### Gateway Cluster
```yaml
Cluster Configuration:
  Name: sentinel-gateway
  Version: Kubernetes 1.28+
  Region: us-west-2
  VPC: 10.0.0.0/16
  
Node Groups:
  - Name: gateway-nodes
    Instance Type: t3.medium
    Min Size: 1
    Max Size: 3
    Desired Size: 2
    Subnets: Private subnets in AZ-A and AZ-B
    
Networking:
  CNI: AWS VPC CNI
  Pod CIDR: 10.0.0.0/16
  Service CIDR: 10.0.0.0/16
```

#### Backend Cluster
```yaml
Cluster Configuration:
  Name: sentinel-backend
  Version: Kubernetes 1.28+
  Region: us-west-2
  VPC: 10.1.0.0/16
  
Node Groups:
  - Name: backend-nodes
    Instance Type: t3.medium
    Min Size: 1
    Max Size: 3
    Desired Size: 2
    Subnets: Private subnets in AZ-A and AZ-B
    
Networking:
  CNI: AWS VPC CNI
  Pod CIDR: 10.1.0.0/16
  Service CIDR: 10.1.0.0/16
```

### Приложения

#### Gateway Service
```yaml
Components:
  - Nginx Reverse Proxy
  - Load Balancer Service (LoadBalancer type)
  - ConfigMap for nginx configuration
  - Network Policy for ingress control
  
Configuration:
  Replicas: 2
  Resource Limits: CPU 100m, Memory 128Mi
  Health Checks: Liveness and readiness probes
  External Access: ALB with health checks
```

#### Backend Service
```yaml
Components:
  - Nginx Web Server
  - ClusterIP Service (internal only)
  - ConfigMap for application configuration
  - Network Policy for isolation
  
Configuration:
  Replicas: 2
  Resource Limits: CPU 100m, Memory 128Mi
  Health Checks: Liveness and readiness probes
  External Access: None (isolated)
```

## Безопасность

### Многоуровневая Защита

```
Internet → ALB → Security Groups → NACLs → Network Policies → Pod Security
```

#### Уровень 1: AWS Security Groups
```yaml
Gateway EKS Security Group:
  Ingress:
    - Port 80/443: 0.0.0.0/0 (ALB health checks)
    - All Ports: 10.1.0.0/16 (Backend VPC)
  Egress:
    - All Ports: 0.0.0.0/0 (Internet access)

Backend EKS Security Group:
  Ingress:
    - All Ports: 10.0.0.0/16 (Gateway VPC only)
    - All Ports: 10.1.0.0/16 (Internal VPC)
  Egress:
    - All Ports: 0.0.0.0/0 (Internet access)
```

#### Уровень 2: Network ACLs
```yaml
Private Subnet NACLs:
  Inbound Rules:
    - Rule 100: Allow all from VPC CIDR
    - Rule 32767: Deny all (default)
  Outbound Rules:
    - Rule 100: Allow all to 0.0.0.0/0
    - Rule 32767: Deny all (default)
```

#### Уровень 3: Kubernetes Network Policies
```yaml
Backend Network Policy:
  Pod Selector: app=backend-service
  Ingress:
    - From: Gateway namespace only
  Egress:
    - To: DNS and HTTPS only

Gateway Network Policy:
  Pod Selector: app=gateway-service
  Ingress:
    - From: Internet via ALB
  Egress:
    - To: Backend VPC and Internet
```

#### Уровень 4: Pod Security
```yaml
Security Context:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
```

## CI/CD Архитектура

### GitHub Actions Workflows

#### 1. Terraform Validation (PR)
```yaml
Triggers: Pull requests to main
Steps:
  - Checkout code
  - Setup Terraform
  - Terraform fmt check
  - Terraform validate
  - TFLint static analysis
  - Checkov security scanning
  - Terraform plan
  - Upload artifacts
  - Comment on PR
```

#### 2. Infrastructure Deployment (Main)
```yaml
Triggers: Push to main branch
Steps:
  - Checkout code
  - Setup AWS credentials (OIDC)
  - Setup Terraform
  - Terraform init
  - Terraform plan
  - Terraform apply
  - Capture outputs
  - Store artifacts
```

#### 3. Application Deployment
```yaml
Triggers: Infrastructure completion
Steps:
  - Setup kubectl
  - Validate manifests
  - Deploy backend first
  - Deploy gateway second
  - Run connectivity tests
  - Health checks
```

### Безопасность CI/CD

#### GitHub OIDC Federation
```yaml
AWS IAM Trust Policy:
  Principal: GitHub Actions
  Conditions:
    - Repository: ORG/REPO
    - Branch: main
    - Audience: sts.amazonaws.com

Permissions:
  - EKS cluster access
  - S3 bucket access
  - IAM role assumption
  - No long-lived credentials
```

## Мониторинг и Логирование

### CloudWatch Интеграция

#### EKS Логи
```yaml
Enabled Log Types:
  - API Server: All API requests
  - Audit: Detailed audit trail
  - Authenticator: Authentication attempts
  - Controller Manager: Control plane logs
  - Scheduler: Pod scheduling decisions

Retention:
  - CloudWatch: 30 days
  - S3 Archive: Long-term storage
```

#### Прикладные Логи
```yaml
Container Logs:
  - stdout/stderr to CloudWatch
  - Structured logging (JSON)
  - Log levels: INFO, WARN, ERROR
  - Correlation IDs for tracing
```

### Метрики

#### EKS Метрики
```yaml
Cluster Metrics:
  - CPU utilization
  - Memory usage
  - Network I/O
  - Disk I/O

Pod Metrics:
  - Resource usage
  - Restart counts
  - Health status
  - Custom business metrics
```

## Масштабирование

### Горизонтальное Масштабирование

#### Pod Autoscaling
```yaml
Horizontal Pod Autoscaler:
  Target: CPU utilization 70%
  Min Replicas: 2
  Max Replicas: 10
  Scale Up: 2 minutes
  Scale Down: 5 minutes
```

#### Cluster Autoscaling
```yaml
Cluster Autoscaler:
  Scale Up: When pods are pending
  Scale Down: When nodes are underutilized
  Node Groups: Managed node groups
  Instance Types: t3.medium
```

### Вертикальное Масштабирование

#### Vertical Pod Autoscaler
```yaml
VPA Configuration:
  Mode: Auto
  Update Policy: Auto
  Resource Limits: CPU and Memory
  Recommendations: Based on usage patterns
```

## Оптимизация Стоимости

### Текущие Оптимизации
- **Single NAT Gateway**: 50% снижение затрат
- **t3.medium Instances**: Экономичные для разработки
- **Managed Node Groups**: Снижение операционных затрат
- **Auto Scaling**: Масштабирование в нерабочие часы

### Будущие Оптимизации
- **Spot Instances**: 60-90% экономия для некритичных нагрузок
- **Reserved Instances**: 30-40% экономия с долгосрочными обязательствами
- **Fargate**: Serverless контейнеры для переменных нагрузок
- **Graviton Instances**: ARM-based инстансы для лучшего соотношения цена/производительность

## Disaster Recovery

### Стратегия Резервного Копирования
```yaml
Backup Components:
  - EKS Cluster: ETCD snapshots (managed by AWS)
  - Application Data: Persistent volume snapshots
  - Configuration: GitOps repository backup
  - Terraform State: S3 versioning and cross-region replication

Recovery Procedures:
  1. Infrastructure: Terraform apply from backup state
  2. Applications: GitOps deployment from repository
  3. Data: Restore from EBS snapshots
  4. Validation: Automated testing pipeline
```

## Соответствие Требованиям

### Стандарты Безопасности
- **SOC 2 Type II**: Контроли безопасности и мониторинг
- **ISO 27001**: Управление информационной безопасностью
- **PCI DSS**: Соответствие отраслевым стандартам
- **GDPR**: Защита данных и конфиденциальность

### Политики Соответствия
- **Open Policy Agent**: Kubernetes admission control
- **AWS Config**: Мониторинг соответствия ресурсов
- **Service Control Policies**: Управление учетными записями AWS
- **Terraform Sentinel**: Инфраструктурная политика как код

## Заключение

Предложенная архитектура обеспечивает:
- **Безопасность**: Многоуровневая защита и изоляция
- **Масштабируемость**: Горизонтальное и вертикальное масштабирование
- **Надежность**: Multi-AZ deployment и автоматическое восстановление
- **Операционное превосходство**: Автоматизация и мониторинг
- **Соответствие**: Стандарты безопасности и политики соответствия

Архитектура готова к продакшену и может быть расширена для поддержки дополнительных требований и функциональности. 