output "cluster_id" {
  description = "ECS cluster ID"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "citrine_task_definition_arn" {
  description = "Citrine task definition ARN"
  value       = aws_ecs_task_definition.citrine.arn
}

output "directus_task_definition_arn" {
  description = "Directus task definition ARN"
  value       = aws_ecs_task_definition.directus.arn
}

output "ecs_role_arn" {
  description = "ECS task execution role ARN"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "service_security_group_id" {
  description = "ECS service security group ID"
  value       = aws_security_group.ecs_services.id
}

output "citrine_log_group_name" {
  description = "Citrine CloudWatch log group name"
  value       = aws_cloudwatch_log_group.citrine.name
}

output "directus_log_group_name" {
  description = "Directus CloudWatch log group name"
  value       = aws_cloudwatch_log_group.directus.name
}

output "citrine_task_role_arn" {
  description = "Citrine ECS task role ARN"
  value       = aws_iam_role.ecs_task_role.arn
}

output "directus_task_role_arn" {
  description = "Directus ECS task role ARN"
  value       = aws_iam_role.ecs_task_role.arn
}

output "citrine_task_role_name" {
  description = "Citrine ECS task role name"
  value       = aws_iam_role.ecs_task_role.name
}

output "directus_task_role_name" {
  description = "Directus ECS task role name"
  value       = aws_iam_role.ecs_task_role.name
}
