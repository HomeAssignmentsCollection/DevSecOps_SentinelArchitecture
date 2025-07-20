output "gateway_eks_sg_id" {
  description = "ID of the gateway EKS security group"
  value       = aws_security_group.gateway_eks.id
}

output "backend_eks_sg_id" {
  description = "ID of the backend EKS security group"
  value       = aws_security_group.backend_eks.id
}

output "gateway_alb_sg_id" {
  description = "ID of the gateway ALB security group"
  value       = aws_security_group.gateway_alb.id
}
