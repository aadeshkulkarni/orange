terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# VPC and Networking
module "vpc" {
  source = "./modules/vpc"

  environment = var.environment
  vpc_cidr   = var.vpc_cidr
  azs        = var.availability_zones
}

# ECR Repositories
module "ecr" {
  source = "./modules/ecr"

  environment = var.environment
  repositories = [
    "citrine",
    "directus"
  ]
}

# RDS PostgreSQL
module "rds" {
  source = "./modules/rds"

  environment           = var.environment
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_engine_version    = var.db_engine_version
  allowed_security_group_ids = []  # Will be updated after ECS module is created
}

# ElastiCache Redis
module "elasticache" {
  source = "./modules/elasticache"

  environment         = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  node_type          = var.redis_node_type
  num_cache_nodes    = var.redis_num_cache_nodes
  allowed_security_group_ids = []  # Will be updated after ECS module is created
}

# ECS Cluster
module "ecs" {
  source = "./modules/ecs"

  environment = var.environment
  vpc_id     = module.vpc.vpc_id
  aws_region = var.aws_region

  # Container images (will be populated from ECR)
  citrine_image  = "${module.ecr.repository_urls["citrine"]}:latest"
  directus_image = "${module.ecr.repository_urls["directus"]}:latest"

  # Database configuration
  database_host               = module.rds.db_endpoint
  database_port               = module.rds.db_port
  database_name               = module.rds.db_name
  database_username           = module.rds.db_username
  database_password_secret_arn = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:citrine/db-password"

  # Container resources
  citrine_cpu    = var.citrine_cpu
  citrine_memory = var.citrine_memory
  directus_cpu   = var.directus_cpu
  directus_memory = var.directus_memory

  # ALB security groups
  alb_security_group_ids = [module.alb.alb_security_group_id]

  # Tags
  tags = var.tags
}

# Application Load Balancer
module "alb" {
  source = "./modules/alb"

  environment        = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  domain_name       = var.domain_name
  certificate_arn   = var.certificate_arn
}

# ECS Services
module "citrine_service" {
  source = "./modules/ecs-service"

  environment           = var.environment
  service_name          = "citrine"
  cluster_id            = module.ecs.cluster_id
  task_definition_arn   = module.ecs.citrine_task_definition_arn
  target_group_arn      = module.alb.citrine_target_group_arn
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  security_group_ids    = [module.ecs.service_security_group_id]
  container_port        = 8080
  min_capacity          = var.min_capacity
  max_capacity          = var.max_capacity
  tags                  = var.tags
}

module "directus_service" {
  source = "./modules/ecs-service"

  environment           = var.environment
  service_name          = "directus"
  cluster_id            = module.ecs.cluster_id
  task_definition_arn   = module.ecs.directus_task_definition_arn
  target_group_arn      = module.alb.directus_target_group_arn
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  security_group_ids    = [module.ecs.service_security_group_id]
  container_port        = 8055
  min_capacity          = var.min_capacity
  max_capacity          = var.max_capacity
  tags                  = var.tags
}

# CloudWatch Logs
module "cloudwatch" {
  source = "./modules/cloudwatch"

  environment = var.environment
  aws_region = var.aws_region
  services   = ["citrine", "directus"]
  alarm_actions = []  # Can be configured later with SNS topics
  tags = var.tags
}

# IAM Roles and Policies
module "iam" {
  source = "./modules/iam"

  environment = var.environment
  aws_region = var.aws_region
  aws_account_id = data.aws_caller_identity.current.account_id
  citrine_task_role_arn = module.ecs.citrine_task_role_arn
  directus_task_role_arn = module.ecs.directus_task_role_arn
  citrine_task_role_name = module.ecs.citrine_task_role_name
  directus_task_role_name = module.ecs.directus_task_role_name
  database_password_secret_arn = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:citrine/db-password"
  s3_bucket_arn = "arn:aws:s3:::${var.environment}-citrine-files"
  s3_bucket_id = "${var.environment}-citrine-files"
  tags = var.tags
}
