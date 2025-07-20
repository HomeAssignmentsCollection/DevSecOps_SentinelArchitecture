variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "gateway_vpc_id" {
  description = "ID of the gateway VPC"
  type        = string
}

variable "backend_vpc_id" {
  description = "ID of the backend VPC"
  type        = string
}

variable "gateway_vpc_cidr" {
  description = "CIDR block of the gateway VPC"
  type        = string
}

variable "backend_vpc_cidr" {
  description = "CIDR block of the backend VPC"
  type        = string
}
