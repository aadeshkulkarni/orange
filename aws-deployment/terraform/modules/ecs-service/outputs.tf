output "service_id" {
  description = "ECS service ID"
  value       = aws_ecs_service.main.id
}

output "service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.main.name
}

output "service_arn" {
  description = "ECS service ARN"
  value       = aws_ecs_service.main.id  # ECS service ID serves as ARN
}

output "scaling_target_id" {
  description = "Auto scaling target ID"
  value       = aws_appautoscaling_target.main.resource_id
}
