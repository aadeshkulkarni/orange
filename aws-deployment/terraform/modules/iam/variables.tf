variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "citrine_task_role_arn" {
  description = "Citrine ECS task role ARN"
  type        = string
}

variable "directus_task_role_arn" {
  description = "Directus ECS task role ARN"
  type        = string
}

variable "citrine_task_role_name" {
  description = "Citrine ECS task role name"
  type        = string
}

variable "directus_task_role_name" {
  description = "Directus ECS task role name"
  type        = string
}

variable "database_password_secret_arn" {
  description = "Database password secret ARN"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "s3_bucket_id" {
  description = "S3 bucket ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
