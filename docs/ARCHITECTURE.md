# Детальный Обзор Архитектуры Sentinel

## Обзор

Разделенная архитектура Sentinel реализует безопасную, масштабируемую микросервисную платформу используя AWS EKS с двумя изолированными VPC, соединенными через VPC peering. Этот дизайн следует принципам AWS Well-Architected Framework и лучшим практикам корпоративной безопасности.

## Сетевая Архитектура

### Дизайн VPC

#### Gateway VPC (10.0.0.0/16)
- **Назначение**: Интернет-ориентированные сервисы, API gateways, load balancers
- **Публичные Subnets**: 10.0.1.0/24, 10.0.2.0/24 (только NAT Gateways)
- **Приватные Subnets**: 10.0.11.0/24, 10.0.12.0/24 (EKS узлы)
- **Internet Gateway**: Прикреплен для исходящего доступа в интернет
- **NAT Gateway**: Один gateway для оптимизации стоимости

#### Backend VPC (10.1.0.0/16)
- **Назначение**: Внутренние сервисы, базы данных, чувствительная обработка
- **Публичные Subnets**: 10.1.1.0/24, 10.1.2.0/24 (только NAT Gateways)
- **Приватные Subnets**: 10.1.11.0/24, 10.1.12.0/24 (EKS узлы)
- **Internet Gateway**: Прикреплен для исходящего доступа в интернет
- **NAT Gateway**: Один gateway для оптимизации стоимости

### VPC Peering

```
Gateway VPC (10.0.0.0/16) ←→ Backend VPC (10.1.0.0/16)
```

- **Двунаправленная маршрутизация**: Оба VPC могут общаться приватно
- **DNS resolution**: Включено меж-VPC DNS разрешение
- **Безопасность**: Трафик фильтруется security groups и NACLs

## Архитектура EKS Кластеров

### Gateway Кластер
- **Имя**: sentinel-gateway
- **Версия**: Kubernetes 1.28+
- **Node Groups**: Управляемые группы узлов в приватных subnets
- **Типы Инстансов**: t3.medium (оптимизировано по стоимости)
- **Масштабирование**: 1-3 узла с авто-масштабированием
- **Сеть**: AWS VPC CNI с pod networking

### Backend Кластер
- **Имя**: sentinel-backend
- **Версия**: Kubernetes 1.28+
- **Node Groups**: Управляемые группы узлов в приватных subnets
- **Типы Инстансов**: t3.medium (оптимизировано по стоимости)
- **Масштабирование**: 1-3 узла с авто-масштабированием
- **Сеть**: AWS VPC CNI с pod networking

## Архитектура Безопасности

### Защита в Глубину

```
Интернет → ALB → Security Groups → NACLs → Network Policies → Pod Security
```

#### Слой 1: AWS Security Groups
- **Gateway EKS**: Разрешить HTTP/HTTPS из интернета, все из backend VPC
- **Backend EKS**: Разрешить трафик только из gateway VPC
- **ALB**: Разрешить HTTP/HTTPS из интернета

#### Слой 2: Network ACLs
- **Приватные Subnets**: Разрешить трафик внутри VPC CIDR блоков
- **Публичные Subnets**: Разрешить интернет трафик для NAT gateways

#### Слой 3: Kubernetes Network Policies
- **Backend Namespace**: Запретить весь ingress кроме gateway
- **Gateway Namespace**: Разрешить internet ingress, backend egress

#### Слой 4: Pod Security
- **Security Contexts**: Не-root пользователи, read-only файловые системы
- **Resource Limits**: CPU и memory ограничения
- **Health Checks**: Liveness и readiness пробы

### IAM Модель Безопасности

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
- **AmazonEKSWorkerNodePolicy**: Базовые EKS worker разрешения
- **AmazonEKS_CNI_Policy**: VPC CNI networking
- **AmazonEC2ContainerRegistryReadOnly**: ECR image pulls

## Архитектура Приложений

### Gateway Service

#### Компоненты
- **Nginx Reverse Proxy**: Маршрутизирует трафик к backend сервисам
- **Load Balancer**: AWS ALB с health checks
- **Service Discovery**: Kubernetes DNS разрешение

#### Конфигурация
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

#### Компоненты
- **Nginx Web Server**: Сервирует статическое содержимое и API
- **ClusterIP Service**: Экспозиция внутреннего сервиса
- **ConfigMap**: Конфигурация приложения

#### Безопасность
- **Отсутствие внешнего доступа**: Тип сервиса ClusterIP
- **Network Policies**: Ограничения ingress
- **Resource Limits**: CPU и memory ограничения

## Поток Данных

### Обработка Запросов

1. **Интернет Запрос** → ALB (Gateway VPC)
2. **ALB** → Gateway Pod (Приватный Subnet)
3. **Gateway Pod** → DNS Resolution → Backend Service
4. **VPC Peering** → Backend VPC
5. **Backend Pod** → Обработка Запроса
6. **Путь Ответа**: Обратный порядку выше

### Service Discovery

```
backend-service.backend.svc.cluster.local
│
├── backend: Namespace
├── svc: Service
├── cluster.local: Cluster domain
└── Resolution: 10.1.x.x (Backend VPC IP)
```

## Мониторинг и Обеспечение Безопасности

### Сбор Метрик
- **EKS Control Plane Logs**: API server, audit, authenticator
- **Node Metrics**: CPU, memory, disk, network
- **Pod Metrics**: Resource usage, restart counts
- **Application Metrics**: Custom business metrics

### Стратегия Логирования
- **Container Logs**: stdout/stderr в CloudWatch
- **Audit Logs**: EKS API server audit logs
- **VPC Flow Logs**: Анализ сетевого трафика
- **ALB Access Logs**: Patterns запросов и ошибки

### Мониторинг Здоровья
- **Liveness Probes**: Проверки здоровья контейнеров
- **Readiness Probes**: Доступность сервиса
- **ALB Health Checks**: Мониторинг target groups
- **EKS Cluster Health**: Статус control plane

## Восстановление После Отказа

### Стратегия Резервного Копирования
- **EKS Cluster**: Snapshots ETCD (управляется AWS)
- **Application Data**: Snapshots постоянных объемов
- **Configuration**: Резервное копирование репозитория GitOps
- **Terraform State**: S3 versioning и cross-region репликация

### Процедуры Восстановления
1. **Infrastructure**: Terraform apply из состояния резервной копии
2. **Applications**: GitOps deployment из репозитория
3. **Data**: Восстановление из EBS snapshots
4. **Validation**: Автоматизированная конвейер тестирования

## Оптимизация Производительности

### Стратегии Масштабирования
- **Horizontal Pod Autoscaler**: Масштабирование по CPU/memory
- **Vertical Pod Autoscaler**: Правильный размер ресурсов
- **Cluster Autoscaler**: Добавление/удаление узлов автоматически
- **Load Balancer**: Распределение трафика между здоровыми целями

### Управление Ресурсами
- **Resource Requests**: Гарантированный CPU и memory
- **Resource Limits**: Максимальный CPU и memory использование
- **Quality of Service**: Гарантированный, Burstable, BestEffort
- **Node Affinity**: Оптимизация размещения pod

## Оптимизация Стоимости

### Текущие Оптимизации
- **Единый NAT Gateway**: Уменьшение затрат на NAT на 50%
- **t3.medium Instances**: Экономично для разработки
- **Managed Node Groups**: Уменьшение операционных накладных расходов
- **Auto Scaling**: Масштабирование в ночное время

### Будущие Оптимизации
- **Spot Instances**: 60-90% снижение стоимости для некритичных нагрузок
- **Reserved Instances**: 30-40% экономии с 1-летним обязательством
- **Fargate**: Serverless контейнеры для переменных нагрузок
- **Graviton Instances**: ARM-based инстансы для лучшего соотношения цена/производительность

## Соответствие Требованиям и Управление

### Стандарты Безопасности
- **SOC 2 Type II**: Контроли безопасности и мониторинг
- **ISO 27001**: Управление информационной безопасностью
- **PCI DSS**: Соответствие отраслевым стандартам платежных карт
- **GDPR**: Защита данных и конфиденциальность

### Законное Принуждение
- **Open Policy Agent**: Kubernetes admission control
- **AWS Config**: Мониторинг соответствия ресурсов
- **Service Control Policies**: Управление учетными записями AWS
- **Terraform Sentinel**: Инфраструктурная политика как код

## Будущие Улучшения

### Интеграция Service Mesh
- **Istio**: Расширенное управление трафиком и безопасность
- **AWS App Mesh**: Управляемый сервисный mesh
- **mTLS**: Mutual TLS между сервисами
- **Circuit Breaking**: Паттерны отказоустойчивости

### Реализация GitOps
- **ArgoCD**: Декларативное GitOps для Kubernetes
- **Flux**: GitOps toolkit для Kubernetes
- **Helm**: Управление пакетами для Kubernetes
- **Kustomize**: Управление конфигурацией

### Мульти-региональное Развертывание
- **Cross-Region Replication**: Синхронизация данных и конфигурации
- **Global Load Balancer**: Health checks Route 53
- **Disaster Recovery**: Автоматизированные процедуры отработки отказа
- **Data Sovereignty**: Региональная соответствие данных
