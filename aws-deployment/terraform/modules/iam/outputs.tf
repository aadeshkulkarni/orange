output "citrine_task_policy_arn" {
  description = "Citrine task policy ARN"
  value       = aws_iam_policy.citrine_task_policy.arn
}

output "directus_task_policy_arn" {
  description = "Directus task policy ARN"
  value       = aws_iam_policy.directus_task_policy.arn
}

output "s3_bucket_policy_id" {
  description = "S3 bucket policy ID"
  value       = aws_s3_bucket_policy.main.id
}

output "s3_bucket_id" {
  description = "S3 bucket ID"
  value       = aws_s3_bucket.main.id
}
