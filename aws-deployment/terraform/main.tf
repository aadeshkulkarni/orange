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

# RDS Database
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
}

# ElastiCache Redis
module "elasticache" {
  source = "./modules/elasticache"

  environment         = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  node_type          = var.redis_node_type
  num_cache_nodes    = var.redis_num_cache_nodes
}

# ECS Cluster
module "ecs" {
  source = "./modules/ecs"

  environment = var.environment
  vpc_id     = module.vpc.vpc_id
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
}

# CloudWatch Logs
module "cloudwatch" {
  source = "./modules/cloudwatch"

  environment = var.environment
  services   = ["citrine", "directus"]
}

# IAM Roles and Policies
module "iam" {
  source = "./modules/iam"

  environment = var.environment
  ecs_role_arn = module.ecs.ecs_role_arn
}
