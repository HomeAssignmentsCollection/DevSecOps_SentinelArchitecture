# Gateway EKS Security Group
resource "aws_security_group" "gateway_eks" {
  name_prefix = "${var.project_name}-gateway-eks-"
  vpc_id      = var.gateway_vpc_id
  description = "Security group for Gateway EKS cluster"

  # Allow inbound HTTPS from internet (for ALB)
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound HTTP from internet (for ALB)
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow specific ports from backend VPC for service communication
  ingress {
    description = "Backend service communication"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.backend_vpc_cidr]
  }

  # EKS control plane communication
  ingress {
    description = "EKS control plane"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.gateway_vpc_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-gateway-eks-sg"
    Type = "Gateway"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Backend EKS Security Group
resource "aws_security_group" "backend_eks" {
  name_prefix = "${var.project_name}-backend-eks-"
  vpc_id      = var.backend_vpc_id
  description = "Security group for Backend EKS cluster"

  # Allow specific ports from gateway VPC only
  ingress {
    description = "HTTP from gateway VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.gateway_vpc_cidr]
  }

  ingress {
    description = "HTTPS from gateway VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.gateway_vpc_cidr]
  }

  # Allow specific ports within backend VPC for internal communication
  ingress {
    description = "HTTP within backend VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.backend_vpc_cidr]
  }

  # EKS control plane communication
  ingress {
    description = "EKS control plane"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.backend_vpc_cidr]
  }

  # Allow all outbound traffic (for downloading images, etc.)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-backend-eks-sg"
    Type = "Backend"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Security Group for Gateway
resource "aws_security_group" "gateway_alb" {
  name_prefix = "${var.project_name}-gateway-alb-"
  vpc_id      = var.gateway_vpc_id
  description = "Security group for Gateway ALB"

  # Allow inbound HTTPS from internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound HTTP from internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound to gateway VPC (for health checks)
  egress {
    description = "Health checks to gateway VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.gateway_vpc_cidr]
  }

  tags = {
    Name = "${var.project_name}-gateway-alb-sg"
    Type = "Gateway-ALB"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Additional security group rules for EKS node-to-node communication
resource "aws_security_group_rule" "gateway_eks_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gateway_eks.id
  security_group_id        = aws_security_group.gateway_eks.id
  description              = "Allow kubelet communication within gateway security group"
}

resource "aws_security_group_rule" "gateway_eks_node_ports" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.gateway_eks.id
  security_group_id        = aws_security_group.gateway_eks.id
  description              = "Allow NodePort services within gateway security group"
}

resource "aws_security_group_rule" "backend_eks_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend_eks.id
  security_group_id        = aws_security_group.backend_eks.id
  description              = "Allow kubelet communication within backend security group"
}

resource "aws_security_group_rule" "backend_eks_node_ports" {
  type                     = "ingress"
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.backend_eks.id
  security_group_id        = aws_security_group.backend_eks.id
  description              = "Allow NodePort services within backend security group"
}
