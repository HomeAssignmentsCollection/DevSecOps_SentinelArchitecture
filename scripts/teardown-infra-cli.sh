#!/bin/bash

# This script tears down AWS infrastructure created by deploy-infra-cli.sh using AWS CLI commands.
# All resources are deleted in the us-east-2 region.
# Make sure AWS CLI is configured with the correct credentials before running.
# NOTE: This script assumes no other resources depend on these objects.

set -euo pipefail

REGION="us-east-2"
VPC_NAME="sentinel-vpc"
SUBNET_NAME_A="sentinel-subnet-a"
SUBNET_NAME_B="sentinel-subnet-b"
IGW_NAME="sentinel-igw"
ROUTE_TABLE_NAME="sentinel-rt"
SG_NAME="sentinel-sg"

# Find resource IDs by tags
VPC_ID=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values="$VPC_NAME" --region "$REGION" --query 'Vpcs[0].VpcId' --output text)
SUBNET_ID_A=$(aws ec2 describe-subnets --filters Name=tag:Name,Values="$SUBNET_NAME_A" --region "$REGION" --query 'Subnets[0].SubnetId' --output text)
SUBNET_ID_B=$(aws ec2 describe-subnets --filters Name=tag:Name,Values="$SUBNET_NAME_B" --region "$REGION" --query 'Subnets[0].SubnetId' --output text)
IGW_ID=$(aws ec2 describe-internet-gateways --filters Name=tag:Name,Values="$IGW_NAME" --region "$REGION" --query 'InternetGateways[0].InternetGatewayId' --output text)
RT_ID=$(aws ec2 describe-route-tables --filters Name=tag:Name,Values="$ROUTE_TABLE_NAME" --region "$REGION" --query 'RouteTables[0].RouteTableId' --output text)
SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values="$SG_NAME" --region "$REGION" --query 'SecurityGroups[0].GroupId' --output text)

# Terminate all EC2 instances in the VPC
INSTANCE_IDS=$(aws ec2 describe-instances --filters Name=vpc-id,Values="$VPC_ID" --region "$REGION" --query 'Reservations[].Instances[].InstanceId' --output text)
if [ -n "$INSTANCE_IDS" ]; then
  echo "Terminating EC2 instances: $INSTANCE_IDS"
  aws ec2 terminate-instances --instance-ids "$INSTANCE_IDS" --region "$REGION"
  aws ec2 wait instance-terminated --instance-ids "$INSTANCE_IDS" --region "$REGION"
  echo "All EC2 instances terminated."
else
  echo "No EC2 instances found in VPC."
fi

# Delete Security Group
if [ "$SG_ID" != "None" ]; then
  echo "Deleting Security Group: $SG_ID"
  aws ec2 delete-security-group --group-id "$SG_ID" --region "$REGION" || echo "Security Group already deleted or in use."
else
  echo "Security Group not found."
fi

# Disassociate and delete Route Table
ASSOC_IDS=$(aws ec2 describe-route-tables --route-table-ids "$RT_ID" --region "$REGION" --query 'RouteTables[0].Associations[].RouteTableAssociationId' --output text)
for ASSOC_ID in $ASSOC_IDS; do
  if [ "$ASSOC_ID" != "None" ]; then
    echo "Disassociating Route Table Association: $ASSOC_ID"
    aws ec2 disassociate-route-table --association-id "$ASSOC_ID" --region "$REGION" || echo "Association already removed."
  fi
done

# Delete route to IGW
aws ec2 delete-route --route-table-id "$RT_ID" --destination-cidr-block 0.0.0.0/0 --region "$REGION" || echo "Route already deleted."

# Delete Route Table
if [ "$RT_ID" != "None" ]; then
  echo "Deleting Route Table: $RT_ID"
  aws ec2 delete-route-table --route-table-id "$RT_ID" --region "$REGION" || echo "Route Table already deleted."
else
  echo "Route Table not found."
fi

# Detach and delete Internet Gateway
if [ "$IGW_ID" != "None" ]; then
  echo "Detaching IGW: $IGW_ID from VPC: $VPC_ID"
  aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$REGION" || echo "IGW already detached."
  echo "Deleting Internet Gateway: $IGW_ID"
  aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --region "$REGION" || echo "IGW already deleted."
else
  echo "Internet Gateway not found."
fi

# Delete Subnets
for SUBNET_ID in $SUBNET_ID_A $SUBNET_ID_B; do
  if [ "$SUBNET_ID" != "None" ]; then
    echo "Deleting Subnet: $SUBNET_ID"
    aws ec2 delete-subnet --subnet-id "$SUBNET_ID" --region "$REGION" || echo "Subnet already deleted."
  else
    echo "Subnet not found."
  fi
done

# Delete VPC
if [ "$VPC_ID" != "None" ]; then
  echo "Deleting VPC: $VPC_ID"
  aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$REGION" || echo "VPC already deleted."
else
  echo "VPC not found."
fi

echo "Infrastructure teardown complete." 