variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the EKS cluster"
  type        = list(string)
  default     = []
}

variable "node_group_config" {
  description = "Configuration for the EKS node group"
  type = object({
    instance_types = list(string)
    capacity_type  = string
    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })
  })
  default = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    scaling_config = {
      desired_size = 1
      max_size     = 3
      min_size     = 1
    }
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
