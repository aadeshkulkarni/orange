# Citrine with Directus AWS Deployment Guide

This comprehensive guide will walk you through deploying Citrine (OCPP charging station management system) with Directus (CMS) on AWS from scratch.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Quick Start](#quick-start)
4. [Detailed Deployment Steps](#detailed-deployment-steps)
5. [Configuration](#configuration)
6. [Monitoring and Logging](#monitoring-and-logging)
7. [Security Considerations](#security-considerations)
8. [Troubleshooting](#troubleshooting)
9. [Cost Optimization](#cost-optimization)
10. [Maintenance and Updates](#maintenance-and-updates)

## Prerequisites

### Required Tools

- **AWS CLI** (v2.x) - [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- **Docker** (v20.x+) - [Installation Guide](https://docs.docker.com/get-docker/)
- **Docker Compose** (v2.x+) - [Installation Guide](https://docs.docker.com/compose/install/)
- **Terraform** (v1.0+) - [Installation Guide](https://developer.hashicorp.com/terraform/downloads)
- **Git** - [Installation Guide](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

### AWS Account Requirements

- AWS account with appropriate permissions
- IAM user with programmatic access
- Access to the following AWS services:
  - ECS (Elastic Container Service)
  - ECR (Elastic Container Registry)
  - RDS (Relational Database Service)
  - ElastiCache
  - VPC and networking
  - Application Load Balancer
  - CloudWatch
  - S3
  - IAM

### System Requirements

- **Minimum**: 4GB RAM, 2 CPU cores
- **Recommended**: 8GB RAM, 4 CPU cores
- **Storage**: At least 20GB free space
- **OS**: Linux, macOS, or Windows with WSL2

## Architecture Overview

```
Internet → Route 53 → CloudFront → ALB → ECS Fargate → Containers
                                    ↓
                            VPC with Private Subnets
                                    ↓
                            RDS PostgreSQL + ElastiCache Redis
```

### Components

- **Frontend**: Application Load Balancer with SSL termination
- **Application Layer**: ECS Fargate running Citrine and Directus
- **Data Layer**: RDS PostgreSQL with PostGIS extensions
- **Cache Layer**: ElastiCache Redis for session and data caching
- **Storage**: S3 for file storage and backups
- **Monitoring**: CloudWatch for metrics, logs, and alarms
- **Security**: VPC with private subnets, security groups, and IAM roles

## Quick Start

### 1. Clone and Setup

```bash
# Clone the repository
git clone <your-repo-url>
cd citrineos-core

# Navigate to AWS deployment directory
cd aws-deployment

# Make scripts executable
chmod +x scripts/*.sh
```

### 2. Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 3. Deploy Everything

```bash
# Run the main deployment script
./scripts/deploy.sh -e prod -r us-east-1
```

## Detailed Deployment Steps

### Step 1: Build Docker Images

```bash
# Build images locally
./scripts/build-images.sh -t v1.0.0

# Or build and push to ECR
./scripts/build-images.sh -t v1.0.0 --push --registry ecr
```

### Step 2: Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Create terraform.tfvars file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values

# Plan deployment
terraform plan

# Apply deployment
terraform apply
```

### Step 3: Deploy Application

```bash
# Update ECS services with new images
aws ecs update-service \
  --cluster prod-citrine-cluster \
  --service prod-citrine-service \
  --force-new-deployment

aws ecs update-service \
  --cluster prod-citrine-cluster \
  --service prod-directus-service \
  --force-new-deployment
```

### Step 4: Verify Deployment

```bash
# Check ECS services
aws ecs describe-services \
  --cluster prod-citrine-cluster \
  --services prod-citrine-service prod-directus-service

# Check ALB health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

## Configuration

### Environment Variables

#### Citrine Service

```bash
# Core Configuration
APP_NAME=all
APP_ENV=aws
NODE_ENV=production

# Database
BOOTSTRAP_CITRINEOS_DATABASE_HOST=<rds-endpoint>
BOOTSTRAP_CITRINEOS_DATABASE_PASSWORD=<db-password>

# AWS
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=<access-key>
AWS_SECRET_ACCESS_KEY=<secret-key>

# File Storage
BOOTSTRAP_CITRINEOS_FILE_FILE_ACCESS_TYPE=s3
BOOTSTRAP_CITRINEOS_FILE_FILE_ACCESS_S3_BUCKET=<s3-bucket>
```

#### Directus Service

```bash
# Core Configuration
KEY=<directus-key>
SECRET=<directus-secret>
ADMIN_EMAIL=<admin-email>
ADMIN_PASSWORD=<admin-password>

# Database
DB_CLIENT=pg
DB_HOST=<rds-endpoint>
DB_PASSWORD=<db-password>

# File Storage
STORAGE_LOCATIONS=s3
STORAGE_S3_DRIVER=s3
STORAGE_S3_KEY=<aws-access-key>
STORAGE_S3_SECRET=<aws-secret-key>
STORAGE_S3_BUCKET=<s3-bucket>
```

### Terraform Variables

Create a `terraform.tfvars` file:

```hcl
# AWS Configuration
aws_region = "us-east-1"
environment = "prod"

# Database
db_password = "your-secure-password"
db_instance_class = "db.t3.small"

# Container Resources
citrine_cpu = 1024
citrine_memory = 2048
directus_cpu = 512
directus_memory = 1024

# Scaling
min_capacity = 2
max_capacity = 5
```

## Monitoring and Logging

### CloudWatch Dashboard

- **ECS Metrics**: CPU, memory, and network utilization
- **RDS Metrics**: Database performance and connections
- **ALB Metrics**: Request count, response time, and error rates
- **ElastiCache Metrics**: Cache hit rates and memory usage

### CloudWatch Alarms

- **High CPU Usage**: Alert when ECS services exceed 80% CPU
- **High Memory Usage**: Alert when ECS services exceed 85% memory
- **Database Issues**: Alert on high RDS CPU or connection count
- **Application Errors**: Alert on high ALB 5XX error rates

### Log Management

```bash
# View Citrine logs
aws logs tail /ecs/prod-citrine --follow

# View Directus logs
aws logs tail /ecs/prod-directus --follow

# Export logs to S3
aws logs export-task \
  --task-name prod-citrine-logs \
  --from 1640995200000 \
  --to 1641081600000 \
  --destination-bucket-name <s3-bucket>
```

## Security Considerations

### Network Security

- **VPC**: Private subnets for application and database layers
- **Security Groups**: Restrict access to necessary ports only
- **NACLs**: Additional network-level access control
- **WAF**: Web Application Firewall for ALB protection

### Data Security

- **Encryption at Rest**: RDS and S3 encryption enabled
- **Encryption in Transit**: TLS 1.2+ for all connections
- **IAM Roles**: Least privilege access for ECS tasks
- **Secrets Management**: Use AWS Secrets Manager for sensitive data

### Access Control

- **IAM Users**: Individual accounts with MFA enabled
- **IAM Policies**: Role-based access control
- **VPC Endpoints**: Private access to AWS services
- **CloudTrail**: Audit logging for all API calls

## Troubleshooting

### Common Issues

#### ECS Service Won't Start

```bash
# Check service events
aws ecs describe-services \
  --cluster prod-citrine-cluster \
  --services prod-citrine-service

# Check task definition
aws ecs describe-task-definition \
  --task-definition prod-citrine

# Check CloudWatch logs
aws logs describe-log-groups --log-group-name-prefix /ecs/prod-citrine
```

#### Database Connection Issues

```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier prod-citrine-db

# Test connectivity from ECS
aws ecs run-task \
  --cluster prod-citrine-cluster \
  --task-definition prod-citrine \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-12345],securityGroups=[sg-12345]}"
```

#### ALB Health Check Failures

```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>

# Check security group rules
aws ec2 describe-security-groups --group-ids <security-group-id>
```

### Debug Commands

```bash
# SSH into ECS tasks (if using EC2 launch type)
aws ecs execute-command \
  --cluster prod-citrine-cluster \
  --task <task-id> \
  --container citrine \
  --command "/bin/bash" \
  --interactive

# Check container logs
aws logs filter-log-events \
  --log-group-name /ecs/prod-citrine \
  --filter-pattern "ERROR"
```

## Cost Optimization

### Resource Sizing

- **Start Small**: Begin with t3.micro instances and scale up
- **Right-size Containers**: Monitor actual usage and adjust CPU/memory
- **Use Spot Instances**: For non-critical workloads (EC2 launch type)

### Storage Optimization

- **RDS**: Use gp3 storage for better performance/cost ratio
- **S3**: Implement lifecycle policies for old data
- **Backups**: Configure appropriate retention periods

### Monitoring Costs

```bash
# Check current costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost

# Set up cost alerts
aws cloudwatch put-metric-alarm \
  --alarm-name "MonthlyCostAlert" \
  --alarm-description "Alert when monthly cost exceeds $100" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 100
```

## Maintenance and Updates

### Regular Maintenance

- **Security Updates**: Monthly OS and dependency updates
- **Backup Verification**: Weekly backup restoration tests
- **Performance Monitoring**: Daily review of CloudWatch metrics
- **Cost Review**: Monthly cost analysis and optimization

### Update Procedures

#### Application Updates

```bash
# Build new images
./scripts/build-images.sh -t v1.1.0

# Push to ECR
./scripts/build-images.sh -t v1.1.0 --push --registry ecr

# Update ECS services
aws ecs update-service \
  --cluster prod-citrine-cluster \
  --service prod-citrine-service \
  --force-new-deployment
```

#### Infrastructure Updates

```bash
cd terraform

# Plan changes
terraform plan

# Apply updates
terraform apply

# Verify changes
terraform show
```

### Backup and Recovery

#### Database Backups

```bash
# Create manual snapshot
aws rds create-db-snapshot \
  --db-instance-identifier prod-citrine-db \
  --db-snapshot-identifier prod-citrine-backup-$(date +%Y%m%d)

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier prod-citrine-db-restored \
  --db-snapshot-identifier prod-citrine-backup-20240101
```

#### Application Data

```bash
# Backup S3 bucket
aws s3 sync s3://prod-citrine-files s3://prod-citrine-backups/$(date +%Y%m%d)

# Backup ECS task definitions
aws ecs describe-task-definition --task-definition prod-citrine > backup-task-def.json
```

## Support and Resources

### Documentation

- [Citrine Documentation](https://docs.citrineos.org/)
- [Directus Documentation](https://docs.directus.io/)
- [AWS Documentation](https://docs.aws.amazon.com/)
- [Terraform Documentation](https://www.terraform.io/docs)

### Community

- [Citrine GitHub](https://github.com/citrineos)
- [Directus Discord](https://discord.gg/directus)
- [AWS Community](https://aws.amazon.com/community/)

### Professional Support

- AWS Support Plans
- Terraform Enterprise
- Directus Enterprise

---

## Quick Reference Commands

```bash
# Check deployment status
terraform show

# View ECS services
aws ecs list-services --cluster prod-citrine-cluster

# Check ALB health
aws elbv2 describe-target-health --target-group-arn <arn>

# View logs
aws logs tail /ecs/prod-citrine --follow

# Scale services
aws ecs update-service \
  --cluster prod-citrine-cluster \
  --service prod-citrine-service \
  --desired-count 3

# Update images
aws ecs update-service \
  --cluster prod-citrine-cluster \
  --service prod-citrine-service \
  --force-new-deployment
```

This guide covers the essential aspects of deploying Citrine with Directus on AWS. For specific issues or advanced configurations, refer to the individual service documentation or seek professional assistance.
