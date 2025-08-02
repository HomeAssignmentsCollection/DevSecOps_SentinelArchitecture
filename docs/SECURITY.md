# Модель Безопасности Sentinel

## Обзор Безопасности

Архитектура Sentinel реализует комплексную модель безопасности, основанную на принципах защиты в глубину, zero-trust сети и контроле доступа с минимальными привилегиями. Этот документ детализирует меры безопасности, реализованные на каждом слое инфраструктуры.

## Сетевая Безопасность

### Изоляция VPC

#### Безопасность Gateway VPC
- **CIDR Block**: 10.0.0.0/16 (65,536 IP адресов)
- **Доступ в Интернет**: Прямой через Internet Gateway
- **Исходящий Трафик**: Через NAT Gateway для приватных subnets
- **Входящий Трафик**: Только через Application Load Balancer

#### Безопасность Backend VPC
- **CIDR Block**: 10.1.0.0/16 (65,536 IP адресов)
- **Доступ в Интернет**: Только исходящий через NAT Gateway
- **Входящий Трафик**: Только из Gateway VPC через peering
- **Нет Прямого Интернета**: Нулевое прямое подключение к интернету

### Безопасность VPC Peering

```
Gateway VPC ←→ Backend VPC
10.0.0.0/16     10.1.0.0/16
```

- **Шифрованный Транзит**: Весь трафик шифруется в транзите
- **Контроль Route Table**: Только специфичная CIDR маршрутизация
- **DNS Resolution**: Меж-VPC DNS включен безопасно
- **Нет Транзитивной Маршрутизации**: Изолированный путь связи

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

## Kubernetes Безопасность

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
```
