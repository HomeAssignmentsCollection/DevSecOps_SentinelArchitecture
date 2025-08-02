# Руководство по Деплою

Это руководство предоставляет детальные инструкции для деплоя инфраструктуры и приложений Sentinel DevSecOps.

## Предварительные Требования

### Необходимые Инструменты

1. **AWS CLI v2**

   ```bash
   # Установить AWS CLI
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Проверить установку
   aws --version
   ```

2. **Terraform >= 1.6.0**

   ```bash
   # Установить Terraform
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   
   # Проверить установку
   terraform --version
   ```

3. **kubectl >= 1.28.0**

   ```bash
   # Установить kubectl
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/
   
   # Проверить установку
   kubectl version --client
   ```

### AWS Конфигурация

1. **Настроить AWS Credentials**

   ```bash
   aws configure
   # Введите ваш AWS Access Key ID
   # Введите ваш AWS Secret Access Key
   # Введите ваш default region (us-west-2)
   # Введите ваш default output format (json)
   ```

2. **Проверить AWS Доступ**

   ```bash
   aws sts get-caller-identity
   ```

3. **Необходимые AWS Разрешения**
   Ваш AWS пользователь/роль нуждается в следующих разрешениях:
   - EC2 (VPC, Security Groups, Subnets)
   - EKS (Clusters, Node Groups)
   - IAM (Roles, Policies)
   - S3 (Buckets, Objects)
   - DynamoDB (Tables)
   - CloudWatch (Logs)

## Шаги Деплоя

### Шаг 1: Клонировать Репозиторий

```bash
git clone <repository-url>
cd devsecops-technical-challenge
```

### Шаг 2: Настроить Terraform Backend

Первый деплой создает S3 bucket и DynamoDB таблицу для управления состоянием Terraform:

```bash
chmod +x scripts/setup-backend.sh
./scripts/setup-backend.sh
```

Этот скрипт:

- Создаст S3 bucket для Terraform state
- Создаст DynamoDB таблицу для блокировки state
- Настроит Terraform для использования удаленного backend
- Мигрирует локальный state в S3

### Шаг 3: Деплой Инфраструктуры

```bash
chmod +x scripts/deploy.sh
```

### Шаг 4: Проверить Деплой

```bash
chmod +x scripts/test-connectivity.sh
./scripts/test-connectivity.sh
```

Этот скрипт:

- Проверит статус EKS кластера
- Проверит развертывание приложений
- Проверит меж-VPC связь
- Проверит конфигурацию безопасности
- Предоставит URL доступа

## Ручное Деплой (Пошагово)

Если вы предпочитаете деплой вручную или вам нужно отладить:

### Инфраструктурное Деплой

1. **Инициализировать Terraform**

   ```bash
   cd infrastructure
   terraform init
   ```

2. **Планировать Деплой**

   ```bash
   terraform plan -out=tfplan
   ```

3. **Применить Инфраструктуру**

   ```bash
   terraform apply tfplan
   ```

4. **Получить Выходы**

   ```bash
   terraform output
   ```

### Прикладное Деплой

1. **Настроить kubectl для Backend Cluster**

   ```bash
   aws eks update-kubeconfig --region us-west-2 --name sentinel-backend
   ```

2. **Деплой Backend Приложения**

   ```bash
   kubectl apply -f k8s-manifests/backend/
   ```

3. **Проверить Backend Деплой**

   ```bash
   kubectl get pods -n backend
   kubectl rollout status deployment/backend-service -n backend
   ```

4. **Настроить kubectl для Gateway Cluster**

   ```bash
   aws eks update-kubeconfig --region us-west-2 --name sentinel-gateway
   ```

5. **Деплой Gateway Приложения**

   ```bash
   kubectl apply -f k8s-manifests/gateway/
   ```

6. **Проверить Gateway Деплой**

   ```bash
   kubectl get pods -n gateway
   kubectl rollout status deployment/gateway-service -n gateway
   ```

7. **Получить URL Load Balancer**

   ```bash
   kubectl get svc gateway-service -n gateway
   ```

## Настройка Пользовательских Параметров

### Переменные Окружения

Вы можете настроить деплой, установив переменные окружения:

```bash
export AWS_REGION="us-east-1"
export PROJECT_NAME="my-sentinel"
export GATEWAY_VPC_CIDR="172.16.0.0/16"
export BACKEND_VPC_CIDR="172.17.0.0/16"
```

### Terraform Переменные

Редактируйте `infrastructure/terraform.tfvars` для настройки:

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

## Устранение Неисправностей

### Общие Проблемы

1. **Инициализация Terraform Backend Не удалась**

   ```bash
   # Проверить AWS Credentials
   aws sts get-caller-identity
   
   # Проверить разрешения S3 bucket
   aws s3 ls s3://your-bucket-name
   ```

2. **Создание EKS Кластера Таймаут**

   ```bash
   # Проверить лимиты AWS сервисов
   aws service-quotas get-service-quota --service-code eks --quota-code L-1194D53C
   
   # Проверить разрешения IAM
   aws iam get-role --role-name sentinel-gateway-cluster-role
   ```

3. **LoadBalancer Не получает внешний IP**

   ```bash
   # Проверить security groups
   kubectl describe svc gateway-service -n gateway
   
   # Проверить теги подсетей
   aws ec2 describe-subnets --filters "Name=tag:kubernetes.io/role/elb,Values=1"
   ```

4. **Меж-VPC Связь Не работает**

   ```bash
   # Проверить статус VPC Peering
   aws ec2 describe-vpc-peering-connections
   
   # Проверить таблицы маршрутов
   aws ec2 describe-route-tables
   
   # Проверить разрешение DNS
   kubectl exec -it test-pod -- nslookup backend-service.backend.svc.cluster.local
   ```

### Команды Отладки

```bash
# Проверить статус EKS кластера
aws eks describe-cluster --name sentinel-gateway

# Проверить статус node group
aws eks describe-nodegroup --cluster-name sentinel-gateway --nodegroup-name sentinel-gateway-nodes

# Проверить логи pod
kubectl logs -f deployment/gateway-service -n gateway

# Проверить конечные точки сервиса
kubectl get endpoints -n gateway

# Проверить политики сети
kubectl describe networkpolicy -n backend

# Проверить security groups
aws ec2 describe-security-groups --group-names sentinel-gateway-eks
```

## Мониторинг Деплоя

### CloudWatch Логи

Мониторинг логов EKS контрольной панели:

```bash
aws logs describe-log-groups --log-group-name-prefix /aws/eks/sentinel
```

### EKS Cluster Health

```bash
# Проверить статус кластера
kubectl get nodes
kubectl get pods --all-namespaces

# Проверить информацию кластера
kubectl cluster-info
kubectl get componentstatuses
```

### Прикладное Здоровье

```bash
# Проверить статус приложения
kubectl get deployments --all-namespaces
kubectl get services --all-namespaces

# Проверить конечные точки приложения
curl -f http://<alb-dns>/health
curl -f http://<alb-dns>/api/
```

## Учетные Записи Масштабирования

### Горизонтальное Масштабирование

```bash
# Масштабировать pod приложения
kubectl scale deployment gateway-service --replicas=5 -n gateway
kubectl scale deployment backend-service --replicas=3 -n backend

# Настроить Horizontal Pod Autoscaler
kubectl autoscale deployment gateway-service --cpu-percent=70 --min=2 --max=10 -n gateway
```

### Cluster Scaling

```bash
# Обновить конфигурацию node group
aws eks update-nodegroup-config \
  --cluster-name sentinel-gateway \
  --nodegroup-name sentinel-gateway-nodes \
  --scaling-config minSize=2,maxSize=5,desiredSize=3
```

## Безопасность Проверка

### Тестирование Сетевой Безопасности

```bash
# Тестировать изоляцию backend (должно не работать)
curl -m 5 http://backend-pod-ip:80

# Тестировать доступность gateway (должно работать)
curl -f http://<alb-dns>/health

# Тестировать меж-VPC связь (должно работать)
curl -f http://<alb-dns>/api/
```

### RBAC Тестирование

```bash
# Тестировать разрешения учетной записи сервиса
kubectl auth can-i create pods --as=system:serviceaccount:backend:default

# Тестировать соблюдение политик сети
kubectl exec -it test-pod -n gateway -- nc -zv backend-service.backend.svc.cluster.local 80
```

## Тестирование Производительности

### Нагрузочное Тестирование

```bash
# Установить Apache Bench
sudo apt-get install apache2-utils

# Тестировать производительность gateway
ab -n 1000 -c 10 http://<alb-dns>/health

# Тестировать подключение backend
ab -n 500 -c 5 http://<alb-dns>/api/
```

### Мониторинг Ресурсов

```bash
# Мониторить использование ресурсов
kubectl top nodes
kubectl top pods --all-namespaces

# Проверить лимиты ресурсов
kubectl describe pod <pod-name> -n <namespace>
```

## Очистка

Чтобы уничтожить все ресурсы:

```bash
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh
```

Это:

- Удалит Kubernetes приложения
- Уничтожит Terraform инфраструктуру
- Очистит локальные контексты kubectl
- Удалит временные файлы

**Предупреждение**: Это действие нельзя отменить. Убедитесь, что у вас есть резервные копии важных данных.
