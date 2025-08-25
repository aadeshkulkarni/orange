variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
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

variable "citrine_image" {
  description = "Citrine Docker image URI"
  type        = string
}

variable "directus_image" {
  description = "Directus Docker image URI"
  type        = string
}

variable "database_host" {
  description = "Database host"
  type        = string
}

variable "database_port" {
  description = "Database port"
  type        = number
}

variable "database_name" {
  description = "Database name"
  type        = string
}

variable "database_username" {
  description = "Database username"
  type        = string
}

variable "database_password_secret_arn" {
  description = "Database password secret ARN"
  type        = string
}

variable "directus_key" {
  description = "Directus key"
  type        = string
  default     = "1234567890"
}

variable "directus_secret" {
  description = "Directus secret"
  type        = string
  default     = "0987654321"
}

variable "directus_admin_email" {
  description = "Directus admin email"
  type        = string
  default     = "admin@citrineos.com"
}

variable "directus_admin_password" {
  description = "Directus admin password"
  type        = string
  default     = "CitrineOS!"
}

variable "alb_security_group_ids" {
  description = "ALB security group IDs"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
