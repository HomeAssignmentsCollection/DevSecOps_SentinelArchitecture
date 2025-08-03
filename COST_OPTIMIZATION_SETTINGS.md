# 🎯 Оптимизация затрат для AWS развертывания

## 📊 Изменения для минимизации затрат

### 1. **Kubernetes Deployments**

#### Gateway Service (`k8s-manifests/gateway/deployment.yaml`)
- ✅ **Replicas**: `2` → `1` (экономия 50%)
- ✅ **HPA minReplicas**: `2` → `1`
- ✅ **HPA maxReplicas**: `10` → `3`

#### Backend Service (`k8s-manifests/backend/deployment.yaml`)
- ✅ **Replicas**: `2` → `1` (экономия 50%)
- ✅ **HPA minReplicas**: `2` → `1`
- ✅ **HPA maxReplicas**: `8` → `3`

### 2. **EKS Node Groups**

#### Gateway EKS Cluster
- ✅ **desired_size**: `1` (минимальное количество узлов)
- ✅ **min_size**: `1` (минимальное масштабирование)
- ✅ **max_size**: `3` (ограниченное масштабирование)

#### Backend EKS Cluster
- ✅ **desired_size**: `1` (минимальное количество узлов)
- ✅ **min_size**: `1` (минимальное масштабирование)
- ✅ **max_size**: `3` (ограниченное масштабирование)

### 3. **Instance Types**
- ✅ **node_instance_types**: `["t3.medium"]` (оптимальный баланс цена/производительность)
- ✅ **capacity_type**: `"ON_DEMAND"` (для тестирования)

### 4. **NAT Gateway Optimization**
- ✅ **single_nat_gateway**: `true` (экономия ~$45/месяц на NAT Gateway)
- ✅ **enable_nat_gateway**: `true` (необходимо для приватных подсетей)

## 💰 Расчетная экономия

### Ежемесячная экономия:
1. **Kubernetes Pods**: 2 реплики → 1 реплика = экономия 50%
2. **EKS Nodes**: Минимальное количество узлов = экономия ~$70/месяц
3. **NAT Gateway**: Single vs Multiple = экономия ~$45/месяц
4. **Instance Types**: t3.medium оптимален для тестирования

### Общая экономия: ~$150-200/месяц

## ⚠️ Важные замечания

### Для Production:
- ❌ **НЕ РЕКОМЕНДУЕТСЯ** использовать 1 реплику в production
- ❌ **НЕ РЕКОМЕНДУЕТСЯ** использовать single NAT Gateway для high availability
- ❌ **НЕ РЕКОМЕНДУЕТСЯ** использовать минимальные ресурсы для критических сервисов

### Для Development/Testing:
- ✅ **РЕКОМЕНДУЕТСЯ** для тестирования и разработки
- ✅ **РЕКОМЕНДУЕТСЯ** для демонстрации архитектуры
- ✅ **РЕКОМЕНДУЕТСЯ** для обучения и экспериментов

## 🔄 Восстановление Production настроек

Для production среды необходимо вернуть:

```yaml
# Kubernetes Deployments
replicas: 2
minReplicas: 2
maxReplicas: 10

# EKS Node Groups
desired_size: 2
min_size: 2
max_size: 5

# NAT Gateway
single_nat_gateway: false
```

## 📋 Команды для применения изменений

```bash
# Применить изменения в Kubernetes
kubectl apply -f k8s-manifests/

# Проверить статус
kubectl get pods -A
kubectl get hpa -A
```

## 🎯 Результат

Все настройки оптимизированы для минимизации затрат при развертывании в AWS для тестирования и демонстрации архитектуры Rapyd Sentinel. 