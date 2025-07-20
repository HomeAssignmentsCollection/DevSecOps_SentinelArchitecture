output "gateway_vpc_id" {
  description = "ID of the gateway VPC"
  value       = module.vpc_gateway.vpc_id
}

output "backend_vpc_id" {
  description = "ID of the backend VPC"
  value       = module.vpc_backend.vpc_id
}

output "gateway_vpc_cidr" {
  description = "CIDR block of the gateway VPC"
  value       = module.vpc_gateway.vpc_cidr_block
}

output "backend_vpc_cidr" {
  description = "CIDR block of the backend VPC"
  value       = module.vpc_backend.vpc_cidr_block
}

output "gateway_private_subnet_ids" {
  description = "IDs of the gateway VPC private subnets"
  value       = module.vpc_gateway.private_subnet_ids
}

output "backend_private_subnet_ids" {
  description = "IDs of the backend VPC private subnets"
  value       = module.vpc_backend.private_subnet_ids
}

output "gateway_public_subnet_ids" {
  description = "IDs of the gateway VPC public subnets"
  value       = module.vpc_gateway.public_subnet_ids
}

output "backend_public_subnet_ids" {
  description = "IDs of the backend VPC public subnets"
  value       = module.vpc_backend.public_subnet_ids
}

output "vpc_peering_connection_id" {
  description = "ID of the VPC peering connection"
  value       = module.vpc_peering.peering_connection_id
}

output "gateway_cluster_name" {
  description = "Name of the gateway EKS cluster"
  value       = module.eks_gateway.cluster_name
}

output "backend_cluster_name" {
  description = "Name of the backend EKS cluster"
  value       = module.eks_backend.cluster_name
}

output "gateway_cluster_endpoint" {
  description = "Endpoint for the gateway EKS cluster"
  value       = module.eks_gateway.cluster_endpoint
  sensitive   = true
}

output "backend_cluster_endpoint" {
  description = "Endpoint for the backend EKS cluster"
  value       = module.eks_backend.cluster_endpoint
  sensitive   = true
}

output "gateway_cluster_security_group_id" {
  description = "Security group ID attached to the gateway EKS cluster"
  value       = module.eks_gateway.cluster_security_group_id
}

output "backend_cluster_security_group_id" {
  description = "Security group ID attached to the backend EKS cluster"
  value       = module.eks_backend.cluster_security_group_id
}

output "gateway_node_group_arn" {
  description = "ARN of the gateway EKS node group"
  value       = module.eks_gateway.node_group_arn
}

output "backend_node_group_arn" {
  description = "ARN of the backend EKS node group"
  value       = module.eks_backend.node_group_arn
}

output "gateway_alb_dns" {
  description = "DNS name of the gateway ALB (will be available after K8s deployment)"
  value       = "To be populated after Kubernetes service deployment"
}

output "terraform_state_bucket_name" {
  description = "Name of the S3 bucket storing Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "terraform_locks_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}
