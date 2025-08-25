output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database subnet IDs"
  value       = module.vpc.database_subnet_ids
}

output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.db_port
}

output "redis_endpoint" {
  description = "Redis endpoint"
  value       = module.elasticache.redis_endpoint
}

output "redis_port" {
  description = "Redis port"
  value       = module.elasticache.redis_port
}

output "ecs_cluster_id" {
  description = "ECS cluster ID"
  value       = module.ecs.cluster_id
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Application Load Balancer zone ID"
  value       = module.alb.alb_zone_id
}

output "citrine_service_url" {
  description = "Citrine service URL"
  value       = "http://${module.alb.alb_dns_name}"
}

output "directus_admin_url" {
  description = "Directus admin URL"
  value       = "http://${module.alb.alb_dns_name}/admin"
}

output "cloudwatch_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = module.cloudwatch.dashboard_name
}

output "deployment_instructions" {
  description = "Instructions for accessing the deployed application"
  value = <<-EOT
    ========================================
    Citrine with Directus Deployment Complete!
    ========================================

    Your application has been deployed to AWS successfully!

    Access URLs:
    - Citrine Service: http://${module.alb.alb_dns_name}
    - Directus Admin: http://${module.alb.alb_dns_name}/admin

    Infrastructure Details:
    - VPC ID: ${module.vpc.vpc_id}
    - ECS Cluster: ${module.ecs.cluster_name}
    - RDS Endpoint: ${module.rds.db_endpoint}
    - Redis Endpoint: ${module.elasticache.redis_endpoint}

    Next Steps:
    1. Access Directus admin panel to set up your content
    2. Configure charging stations in Citrine
    3. Set up monitoring and alerting in CloudWatch
    4. Configure SSL/TLS certificates for production use

    For more information, see the deployment documentation.
  EOT
}
