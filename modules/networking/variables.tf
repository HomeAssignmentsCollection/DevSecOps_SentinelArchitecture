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

variable "gateway_route_table_ids" {
  description = "List of route table IDs in the gateway VPC"
  type        = list(string)
}

variable "backend_route_table_ids" {
  description = "List of route table IDs in the backend VPC"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
