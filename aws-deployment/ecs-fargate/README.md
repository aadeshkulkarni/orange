# ECS Fargate Deployment Guide

This guide covers deploying Citrine with Directus on AWS ECS Fargate, which is the recommended approach for production environments.

## Architecture

```
Internet → ALB → ECS Fargate → Containers
                ↓
        VPC with Private Subnets
                ↓
        RDS PostgreSQL + ElastiCache Redis
```

## Prerequisites

1. **AWS CLI configured**
2. **Terraform installed**
3. **Docker images built and pushed to ECR**

## Step 1: Build and Push Docker Images

```bash
# Build Citrine image
docker build -t citrine:latest -f Server/deploy.Dockerfile .

# Build Directus image
docker build -t directus:latest -f DirectusExtensions/directus.Dockerfile .

# Tag and push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

docker tag citrine:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/citrine:latest
docker tag directus:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/directus:latest

docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/citrine:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/directus:latest
```

## Step 2: Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Step 3: Deploy Application

```bash
# Update ECS service with new image
aws ecs update-service --cluster citrine-cluster --service citrine-service --force-new-deployment
```

## Configuration

### Environment Variables

Key environment variables for Citrine:

- `AWS_REGION`: AWS region
- `BOOTSTRAP_CITRINEOS_DATABASE_HOST`: RDS endpoint
- `BOOTSTRAP_CITRINEOS_DATABASE_PASSWORD`: Database password
- `BOOTSTRAP_CITRINEOS_FILE_FILE_ACCESS_DIRECTUS_HOST`: Directus service URL

### Secrets Management

Use AWS Secrets Manager for sensitive data:

- Database credentials
- API keys
- JWT secrets

## Monitoring and Logging

- **CloudWatch Logs**: Container logs
- **CloudWatch Metrics**: ECS service metrics
- **X-Ray**: Distributed tracing
- **CloudWatch Alarms**: Service health monitoring

## Scaling

Configure auto-scaling based on:

- CPU utilization
- Memory utilization
- Custom metrics
- Scheduled scaling

## Security

- VPC with private subnets
- Security groups limiting access
- IAM roles with least privilege
- WAF for web application protection
- SSL/TLS termination at ALB

## Cost Optimization

- Use Spot instances for non-critical workloads
- Right-size container resources
- Enable auto-scaling
- Monitor and optimize resource usage
