# Sentinel DevSecOps Challenge: Реализация Разделенной Архитектуры

[![Terraform](https://img.shields.io/badge/Terraform-1.6+-623CE4?logo=terraform)](https://terraform.io)
[![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazon-aws)](https://aws.amazon.com/eks/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-326CE5?logo=kubernetes)](https://kubernetes.io)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Готовая к продакшену реализация концепции разделенной архитектуры Rapyd Sentinel с использованием Infrastructure as Code (Terraform), Amazon EKS и GitHub Actions CI/CD. Этот проект демонстрирует корпоративную безопасность, модульность и операционное превосходство.

## 🏗️ Обзор Архитектуры

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

### Ключевые Компоненты

- **Gateway Layer (Публичный)**: Размещает интернет-ориентированные API и прокси в VPC `10.0.0.0/16`
- **Backend Layer (Приватный)**: Запускает внутреннюю обработку и чувствительные сервисы в VPC `10.1.0.0/16`
- **VPC Peering**: Безопасная приватная связь между изолированными средами
- **EKS Clusters**: Управляемые Kubernetes кластеры с авто-масштабируемыми группами узлов
- **Сетевая Безопасность**: Security groups, NACLs и Kubernetes NetworkPolicies

## 🚀 Быстрый Старт

### Предварительные Требования

Убедитесь, что у вас установлены следующие инструменты:

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

### Шаг 1: Клонирование и Настройка

```bash
# Клонировать репозиторий
git clone <repository-url>
cd devsecops-technical-challenge

# Настроить AWS credentials
aws configure
# или
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-west-2"
```

### Шаг 2: Деплой Инфраструктуры

```bash
# Настройка Terraform backend (только первый раз)
chmod +x scripts/setup-backend.sh
./scripts/setup-backend.sh

# Деплой полной инфраструктуры
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

### Шаг 3: Проверка Деплоя

```bash
# Тест связности и безопасности
chmod +x scripts/test-connectivity.sh
./scripts/test-connectivity.sh
```

### Шаг 4: Доступ к Приложению

После деплоя доступ к приложению по предоставленному ALB DNS:

- **Основной Gateway**: `http://<alb-dns>/`
- **Backend Proxy**: `http://<alb-dns>/api/`
- **Health Check**: `http://<alb-dns>/health`

## 📁 Структура Репозитория

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

## 🔒 Модель Безопасности

### Сетевая Безопасность

#### Изоляция VPC

- **Gateway VPC**: `10.0.0.0/16` - Интернет-ориентированные сервисы
- **Backend VPC**: `10.1.0.0/16` - Только внутренние сервисы
- **Нет Прямого Доступа к Интернету**: Backend VPC не имеет прямого подключения к интернету

#### Security Groups (Принцип Минимальных Привилегий)

**Gateway EKS Security Group**:

- ✅ Входящий: HTTP/HTTPS из интернета (0.0.0.0/0:80,443)
- ✅ Входящий: Весь трафик из backend VPC (10.1.0.0/16)
- ✅ Исходящий: Весь трафик (для загрузок, API вызовов)

**Backend EKS Security Group**:

- ✅ Входящий: Весь трафик только из gateway VPC (10.0.0.0/16)
- ✅ Входящий: Внутренняя связь VPC (10.1.0.0/16)
- ❌ Нет прямого входящего доступа из интернета
- ✅ Исходящий: Весь трафик (для загрузок, обновлений)

#### Network Policies (Kubernetes)

**Backend Network Policy**:

```yaml
# Разрешить только входящий трафик из gateway namespace
# Запретить всю другую меж-namespace связь
# Разрешить DNS и исходящий HTTPS
```

**Gateway Network Policy**:

```yaml
# Разрешить входящий трафик из интернета (через ALB)
# Разрешить исходящий трафик к backend VPC
# Разрешить DNS и исходящий HTTPS
```

### IAM Безопасность

- **EKS Cluster Roles**: Минимальные разрешения для управления кластером
- **Node Group Roles**: Только разрешения EC2, ECR и CNI
- **GitHub OIDC**: Нет долгосрочных ключей доступа в CI/CD
- **Принцип Минимальных Привилегий**: Все роли следуют паттернам минимального доступа

## 🌐 Поток Связи

### Анализ Пути Запроса

```
1. Интернет Запрос → ALB (Gateway VPC)
2. ALB → Gateway Pod (Private Subnet)
3. Gateway Pod → VPC Peering → Backend Pod
4. Backend Pod → Ответ → Gateway Pod
5. Gateway Pod → ALB → Интернет
```

### Обнаружение Сервисов

- **Внутренний DNS**: `backend-service.backend.svc.cluster.local`
- **Меж-кластерная Связь**: Через VPC peering и service endpoints
- **Балансировка Нагрузки**: Kubernetes сервисы с множественными репликами подов

### Обработка Ошибок

- **Конфигурация Таймаутов**: 5с подключение, 10с чтение/запись
- **Health Checks**: Liveness и readiness пробы
- **Graceful Degradation**: Nginx upstream failover
- **Circuit Breaking**: Автоматический retry с экспоненциальным backoff

## 🔄 CI/CD Пайплайн

### GitHub Actions Воркфлоу

#### 1. Terraform Plan (Валидация PR)

```yaml
Триггеры: Pull requests в main
Шаги:
  - Terraform format check
  - Terraform validate
  - TFLint static analysis
  - Checkov security scanning
  - Terraform plan с загрузкой артефакта
  - PR комментарий с результатами плана
```

#### 2. Terraform Apply (Main Branch)

```yaml
Триггеры: Push в main branch
Шаги:
  - Terraform init
  - Terraform plan
  - Terraform apply с auto-approval
  - Захват output и сохранение артефактов
  - Уведомление об успехе/неудаче
```

#### 3. Kubernetes Deployment

```yaml
Триггеры: Завершение Terraform или изменения K8s манифестов
Шаги:
  - Валидация манифестов с kubectl
  - Деплой в backend кластер первым
  - Деплой в gateway кластер вторым
  - Тестирование связности
  - Возможность отката
```

### Практики Безопасности

- **GitHub OIDC Federation**: Нет сохраненных AWS credentials
- **Branch Protection**: Требовать PR reviews для изменений инфраструктуры
- **Secret Management**: Все чувствительные значения в GitHub Secrets
- **Signed Commits**: Опционально, но рекомендуется для аудита

### Настройка GitHub Actions

Для включения автоматизированных деплоев нужно настроить AWS OIDC аутентификацию:

1. **Быстрая Настройка** (Рекомендуется):

   ```bash
   chmod +x scripts/setup-github-actions.sh
   ./scripts/setup-github-actions.sh
   ```

2. **Ручная Настройка**: Следуйте детальному руководству в [docs/GITHUB_ACTIONS_SETUP.md](docs/GITHUB_ACTIONS_SETUP.md)

Скрипт настройки создаст:

- AWS IAM OIDC provider
- IAM роль с необходимыми разрешениями
- Предоставит ARN роли для конфигурации GitHub secrets

## 💰 Анализ Стоимости

### Месячная Разбивка Стоимости (us-west-2)

| Компонент | Количество | Стоимость за Единицу | Месячная Стоимость |
|-----------|----------|-----------|--------------|
| **EKS Clusters** | 2 | $0.10/hour | $144.00 |
| **EC2 Instances (t3.medium)** | 2-6 nodes | $0.0416/hour | $60.00-180.00 |
| **NAT Gateways** | 2 | $0.045/hour + data | $65.00 |
| **Application Load Balancer** | 1 | $0.0225/hour | $16.20 |
| **VPC Peering** | 1 | $0.01/GB transferred | $5.00-20.00 |
| **S3 (Terraform State)** | 1 bucket | $0.023/GB | $1.00 |
| **DynamoDB (State Locking)** | 1 table | Pay-per-request | $1.00 |

**Общая Оценка Месячной Стоимости: $292.20 - $432.20**

### Стратегии Оптимизации Стоимости

1. **Single NAT Gateway**: Снижает NAT затраты на 50% (реализовано)
2. **Spot Instances**: Может снизить EC2 затраты на 60-90%
3. **Reserved Instances**: 1-годовое обязательство экономит 30-40%
4. **Auto Scaling**: Масштабирование вниз в нерабочие часы
5. **Cluster Autoscaler**: Автоматическое масштабирование узлов на основе спроса

### Соображения Масштабирования

- **Horizontal Pod Autoscaler**: Масштабирование подов на основе CPU/памяти
- **Vertical Pod Autoscaler**: Правильный размер запросов ресурсов подов
- **Cluster Autoscaler**: Автоматическое добавление/удаление узлов
- **Multi-AZ**: Высокая доступность с автоматическим failover

## 🧪 Тестирование и Валидация

### Автоматизированные Тесты

```bash
# Валидация инфраструктуры
terraform validate
terraform plan
checkov -f infrastructure/

# Тестирование связности
./scripts/test-connectivity.sh

# Валидация безопасности
kubectl get networkpolicy --all-namespaces
kubectl get svc --all-namespaces
```

### Ручная Проверка

1. **Изоляция Backend**: Проверить, что backend сервис недоступен из интернета
2. **Меж-VPC Связь**: Тестировать gateway → backend связность
3. **Health Load Balancer**: Проверить health ALB target group
4. **DNS Resolution**: Проверить service discovery между кластерами
5. **Security Groups**: Валидировать ingress/egress правила

### Тестирование Безопасности

```bash
# Тест доступности backend (должен провалиться)
curl -f http://backend-service-direct-ip/ # Должен timeout/fail

# Тест доступности gateway (должен успешно)
curl -f http://<alb-dns>/health # Должен вернуть "healthy"

# Тест меж-VPC связи (должен успешно)
curl -f http://<alb-dns>/api/ # Должен вернуть backend ответ
```

## 🚨 Оценка Готовности к Продакшену

### Текущая Реализация ✅

- ✅ Infrastructure as Code с Terraform
- ✅ Multi-AZ деплой для высокой доступности
- ✅ Изоляция VPC с безопасным peering
- ✅ EKS кластеры с управляемыми группами узлов
- ✅ Security groups с минимальными привилегиями
- ✅ Network policies для безопасности на уровне подов
- ✅ CI/CD пайплайн с автоматизированной валидацией
- ✅ Комплексная документация

### Отсутствующее для Продакшена 🔄

#### Observability Stack

- **Мониторинг**: Prometheus + Grafana
- **Логирование**: ELK Stack или CloudWatch Logs
- **Трейсинг**: Jaeger или AWS X-Ray
- **Алертинг**: PagerDuty или Slack интеграция

#### Усиление Безопасности

- **TLS/mTLS**: Сквозное шифрование
- **Pod Security Standards**: Принудительные security contexts
- **Сканирование Образов**: Trivy или Clair интеграция
- **Управление Секретами**: AWS Secrets Manager или Vault

#### Операционное Превосходство

- **Стратегия Резервного Копирования**: EBS snapshots, ETCD backups
- **Disaster Recovery**: Multi-region деплой
- **GitOps**: ArgoCD или Flux для деплоя приложений
- **Service Mesh**: Istio или AWS App Mesh

#### Соответствие и Управление

- **Policy as Code**: Open Policy Agent (OPA)
- **Сканирование Соответствия**: AWS Config Rules
- **Аудит Логирование**: CloudTrail интеграция
- **Тегирование Ресурсов**: Комплексная стратегия тегирования

## 🛣️ Следующие Шаги и Roadmap

### Фаза 1: Усиление Безопасности (Неделя 1-2)

- [ ] Реализовать TLS termination на ALB
- [ ] Добавить mTLS между сервисами
- [ ] Интегрировать AWS Secrets Manager
- [ ] Включить Pod Security Standards

### Фаза 2: Observability (Неделя 3-4)

- [ ] Деплой Prometheus monitoring stack
- [ ] Настройка Grafana дашбордов
- [ ] Реализовать централизованное логирование
- [ ] Настроить distributed tracing

### Фаза 3: GitOps и Автоматизация (Неделя 5-6)

- [ ] Реализовать ArgoCD для деплоя приложений
- [ ] Добавить автоматизированное сканирование безопасности
- [ ] Настроить принудительную политику с OPA
- [ ] Реализовать blue-green деплои

### Фаза 4: Мульти-Окружение (Неделя 7-8)

- [ ] Создать staging окружение
- [ ] Реализовать pipeline продвижения окружений
- [ ] Добавить интеграционное тестирование
- [ ] Настроить disaster recovery

## 🤝 Вклад в Проект

1. Форкните репозиторий
2. Создайте feature branch (`git checkout -b feature/amazing-feature`)
3. Зафиксируйте ваши изменения (`git commit -m 'Add amazing feature'`)
4. Отправьте в ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

## 📄 Лицензия

Этот проект лицензирован под MIT License - см. файл [LICENSE](LICENSE) для деталей.

## 🆘 Устранение Проблем

### Частые Проблемы

**Проблема**: Сбой инициализации Terraform backend

```bash
# Решение: Сначала запустите скрипт настройки backend
./scripts/setup-backend.sh
```

**Проблема**: Таймаут создания EKS кластера

```bash
# Решение: Проверьте лимиты AWS сервисов и IAM разрешения
aws eks describe-cluster --name sentinel-gateway
```

**Проблема**: LoadBalancer не получает внешний IP

```bash
# Решение: Проверьте security groups и subnet теги
kubectl describe svc gateway-service -n gateway
```

**Проблема**: Сбой меж-VPC связи

```bash
# Решение: Проверьте VPC peering и route tables
aws ec2 describe-vpc-peering-connections
```

### Поддержка

Для проблем и вопросов:

- 📧 Email: [your-email@company.com]
- 💬 Slack: #devsecops-sentinel
- 📖 Wiki: [Internal Documentation]

---

**Создано с ❤️ командой DevSecOps**

## Author

Copyright (c) 2025 Illia Rizvash  
[LinkedIn](https://www.linkedin.com/in/illia-rizvash/)
