output "repository_urls" {
  description = "ECR repository URLs"
  value = {
    for name, repo in aws_ecr_repository.main : name => repo.repository_url
  }
}

output "repository_names" {
  description = "ECR repository names"
  value = {
    for name, repo in aws_ecr_repository.main : name => repo.name
  }
}
