#!/bin/bash

# Этот скрипт создает основную AWS инфраструктуру используя AWS CLI команды.
# Все ресурсы создаются в регионе us-east-2.
# Убедитесь, что AWS CLI настроен с правильными credentials перед запуском.
# ПРИМЕЧАНИЕ: Этот скрипт для демонстрации и может потребовать корректировки для продакшена.

set -euo pipefail

REGION="us-east-2"
VPC_CIDR="10.0.0.0/16"
SUBNET_CIDR_A="10.0.1.0/24"
SUBNET_CIDR_B="10.0.2.0/24"
AZ_A="us-east-2a"
AZ_B="us-east-2b"
VPC_NAME="sentinel-vpc"
SUBNET_NAME_A="sentinel-subnet-a"
SUBNET_NAME_B="sentinel-subnet-b"
IGW_NAME="sentinel-igw"
ROUTE_TABLE_NAME="sentinel-rt"
SG_NAME="sentinel-sg"

# Создать VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block "$VPC_CIDR" --region "$REGION" --output text --query 'Vpc.VpcId')
echo "Created VPC: $VPC_ID"

# Тегировать VPC
aws ec2 create-tags --resources "$VPC_ID" --tags Key=Name,Value="$VPC_NAME" --region "$REGION"
echo "Tagged VPC with Name: $VPC_NAME"

# Создать Subnets
SUBNET_ID_A=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block "$SUBNET_CIDR_A" --availability-zone "$AZ_A" --region "$REGION" --output text --query 'Subnet.SubnetId')
echo "Created Subnet A: $SUBNET_ID_A ($AZ_A)"
aws ec2 create-tags --resources "$SUBNET_ID_A" --tags Key=Name,Value="$SUBNET_NAME_A" --region "$REGION"

SUBNET_ID_B=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block "$SUBNET_CIDR_B" --availability-zone "$AZ_B" --region "$REGION" --output text --query 'Subnet.SubnetId')
echo "Created Subnet B: $SUBNET_ID_B ($AZ_B)"
aws ec2 create-tags --resources "$SUBNET_ID_B" --tags Key=Name,Value="$SUBNET_NAME_B" --region "$REGION"

# Создать Internet Gateway
IGW_ID=$(aws ec2 create-internet-gateway --region "$REGION" --output text --query 'InternetGateway.InternetGatewayId')
echo "Created Internet Gateway: $IGW_ID"
aws ec2 attach-internet-gateway --vpc-id "$VPC_ID" --internet-gateway-id "$IGW_ID" --region "$REGION"
echo "Attached IGW to VPC"
aws ec2 create-tags --resources "$IGW_ID" --tags Key=Name,Value="$IGW_NAME" --region "$REGION"

# Создать Route Table
RT_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --region "$REGION" --output text --query 'RouteTable.RouteTableId')
echo "Created Route Table: $RT_ID"
aws ec2 create-tags --resources "$RT_ID" --tags Key=Name,Value="$ROUTE_TABLE_NAME" --region "$REGION"

# Создать маршрут к IGW
aws ec2 create-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID" --region "$REGION"
echo "Added default route to IGW"

# Связать subnets с route table
aws ec2 associate-route-table --subnet-id "$SUBNET_ID_A" --route-table-id "$RT_ID" --region "$REGION"
echo "Associated Subnet A with Route Table"
aws ec2 associate-route-table --subnet-id "$SUBNET_ID_B" --route-table-id "$RT_ID" --region "$REGION"
echo "Associated Subnet B with Route Table"

# Создать Security Group
SG_ID=$(aws ec2 create-security-group --group-name "$SG_NAME" --description "Sentinel SG" --vpc-id "$VPC_ID" --region "$REGION" --output text)
echo "Created Security Group: $SG_ID"

# Разрешить входящий SSH, HTTP и HTTPS
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0 --region "$REGION"
echo "Allowed SSH access"
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "$REGION"
echo "Allowed HTTP access"
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 443 --cidr 0.0.0.0/0 --region "$REGION"
echo "Allowed HTTPS access"

# Вывести ID ресурсов
cat <<EOF
VPC_ID=$VPC_ID
SUBNET_ID_A=$SUBNET_ID_A
SUBNET_ID_B=$SUBNET_ID_B
IGW_ID=$IGW_ID
RT_ID=$RT_ID
SG_ID=$SG_ID
EOF

echo "Создание инфраструктуры завершено." 