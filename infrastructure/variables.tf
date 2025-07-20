variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-west-2"
  
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format: us-west-2, eu-west-1, etc."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "sentinel"
  
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "Project name must start with a letter, contain only lowercase letters, numbers, and hyphens, and end with a letter or number."
  }
}

variable "gateway_vpc_cidr" {
  description = "CIDR block for the gateway VPC"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.gateway_vpc_cidr, 0))
    error_message = "Gateway VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "backend_vpc_cidr" {
  description = "CIDR block for the backend VPC"
  type        = string
  default     = "10.1.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.backend_vpc_cidr, 0))
    error_message = "Backend VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "eks_version" {
  description = "Kubernetes version for EKS clusters"
  type        = string
  default     = "1.28"
  
  validation {
    condition     = can(regex("^1\\.(2[8-9]|[3-9][0-9])$", var.eks_version))
    error_message = "EKS version must be 1.28 or higher."
  }
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS node groups"
  type        = list(string)
  default     = ["t3.medium"]
  
  validation {
    condition     = length(var.node_instance_types) > 0
    error_message = "At least one instance type must be specified."
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway for cost optimization"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in VPC"
  type        = bool
  default     = true
}

variable "map_public_ip_on_launch" {
  description = "Map public IP on launch for public subnets"
  type        = bool
  default     = true
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Sentinel"
    ManagedBy   = "Terraform"
    Owner       = "DevSecOps-Team"
  }
}
