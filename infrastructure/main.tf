terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }

  # Backend configuration will be set up after initial deployment
  # backend "s3" {
  #   bucket         = "sentinel-terraform-state-bucket"
  #   key            = "sentinel/terraform.tfstate"
  #   region         = "us-west-2"
  #   dynamodb_table = "sentinel-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Sentinel"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "DevSecOps-Team"
    }
  }
}

# NOTE: The following block is commented out due to IAM restrictions in the test environment.
# In production, use dynamic availability zones for portability and fault tolerance.
# data "aws_availability_zones" "available" {
#   state = "available"
# }

# Gateway VPC
module "vpc_gateway" {
  source = "../modules/vpc"

  name               = "${var.project_name}-gateway"
  cidr_block         = var.gateway_vpc_cidr
  # NOTE: Hardcoded AZs for test assignment due to lack of ec2:DescribeAvailabilityZones permission.
  # TODO: Restore dynamic AZ selection when proper IAM permissions are available.
  availability_zones = ["us-east-2a", "us-east-2b"]

  tags = {
    Name = "${var.project_name}-gateway-vpc"
    Type = "Gateway"
  }
}

# Backend VPC
module "vpc_backend" {
  source = "../modules/vpc"

  name               = "${var.project_name}-backend"
  cidr_block         = var.backend_vpc_cidr
  # NOTE: Hardcoded AZs for test assignment due to lack of ec2:DescribeAvailabilityZones permission.
  # TODO: Restore dynamic AZ selection when proper IAM permissions are available.
  availability_zones = ["us-east-2a", "us-east-2b"]

  tags = {
    Name = "${var.project_name}-backend-vpc"
    Type = "Backend"
  }
}

# VPC Peering
module "vpc_peering" {
  source = "../modules/networking"

  gateway_vpc_id = module.vpc_gateway.vpc_id
  backend_vpc_id = module.vpc_backend.vpc_id

  gateway_vpc_cidr = var.gateway_vpc_cidr
  backend_vpc_cidr = var.backend_vpc_cidr

  gateway_route_table_ids = module.vpc_gateway.private_route_table_ids
  backend_route_table_ids = module.vpc_backend.private_route_table_ids

  tags = {
    Name = "${var.project_name}-vpc-peering"
  }
}

# Security Groups
module "security_groups" {
  source = "../modules/security"

  project_name     = var.project_name
  gateway_vpc_id   = module.vpc_gateway.vpc_id
  backend_vpc_id   = module.vpc_backend.vpc_id
  gateway_vpc_cidr = var.gateway_vpc_cidr
  backend_vpc_cidr = var.backend_vpc_cidr
}

# Gateway EKS Cluster
module "eks_gateway" {
  source = "../modules/eks"

  cluster_name    = "${var.project_name}-gateway"
  cluster_version = var.eks_version

  vpc_id             = module.vpc_gateway.vpc_id
  subnet_ids         = module.vpc_gateway.private_subnet_ids
  security_group_ids = [module.security_groups.gateway_eks_sg_id]

  node_group_config = {
    instance_types = var.node_instance_types
    capacity_type  = "ON_DEMAND"
    scaling_config = {
      desired_size = 1
      max_size     = 3
      min_size     = 1
    }
  }

  tags = {
    Name = "${var.project_name}-gateway-eks"
    Type = "Gateway"
  }
}

# Backend EKS Cluster
module "eks_backend" {
  source = "../modules/eks"

  cluster_name    = "${var.project_name}-backend"
  cluster_version = var.eks_version

  vpc_id             = module.vpc_backend.vpc_id
  subnet_ids         = module.vpc_backend.private_subnet_ids
  security_group_ids = [module.security_groups.backend_eks_sg_id]

  node_group_config = {
    instance_types = var.node_instance_types
    capacity_type  = "ON_DEMAND"
    scaling_config = {
      desired_size = 1
      max_size     = 3
      min_size     = 1
    }
  }

  tags = {
    Name = "${var.project_name}-backend-eks"
    Type = "Backend"
  }
}
