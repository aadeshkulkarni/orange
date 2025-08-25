variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "citrine"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "citrine"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.14"
}

variable "redis_node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_cache_nodes" {
  description = "Number of ElastiCache nodes"
  type        = number
  default     = 1
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

variable "citrine_cpu" {
  description = "CPU units for Citrine container"
  type        = number
  default     = 512
}

variable "citrine_memory" {
  description = "Memory for Citrine container in MiB"
  type        = number
  default     = 1024
}

variable "directus_cpu" {
  description = "CPU units for Directus container"
  type        = number
  default     = 256
}

variable "directus_memory" {
  description = "Memory for Directus container in MiB"
  type        = number
  default     = 512
}

variable "min_capacity" {
  description = "Minimum number of tasks for ECS services"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks for ECS services"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "CitrineOS"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
