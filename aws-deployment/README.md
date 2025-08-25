# Citrine with Directus AWS Deployment Guide

This guide will help you deploy Citrine (OCPP charging station management system) with Directus (CMS) on AWS from scratch.

## Architecture Overview

The deployment consists of:

- **Citrine Core**: OCPP charging station management system
- **Directus**: Content management system with custom extensions
- **PostgreSQL**: Primary database with PostGIS extensions
- **RabbitMQ**: Message broker for async processing
- **Hasura**: GraphQL engine for data access
- **Load Balancer**: Application Load Balancer for traffic distribution
- **ECS Fargate**: Container orchestration
- **RDS**: Managed PostgreSQL database (optional)
- **ElastiCache**: Redis for caching (optional)

## Prerequisites

- AWS CLI configured with appropriate permissions
- Docker and Docker Compose installed locally
- Terraform installed (for infrastructure as code)
- Domain name for your application (optional)

## Deployment Options

### Option 1: ECS Fargate (Recommended for Production)

- Fully managed container orchestration
- Auto-scaling capabilities
- Integrated with AWS services
- Cost-effective for production workloads

### Option 2: EKS (Kubernetes)

- More control over infrastructure
- Advanced orchestration features
- Requires more operational overhead

### Option 3: EC2 with Docker Compose

- Simple deployment
- Full control over the environment
- Requires manual management

## Quick Start

1. **Clone and prepare the repository**
2. **Configure AWS credentials**
3. **Deploy infrastructure with Terraform**
4. **Deploy application containers**
5. **Configure DNS and SSL**

## Directory Structure

```
aws-deployment/
├── terraform/           # Infrastructure as Code
├── docker/             # Production Docker configurations
├── scripts/            # Deployment and management scripts
├── config/             # Environment-specific configurations
└── monitoring/         # CloudWatch and monitoring setup
```

## Next Steps

Choose your deployment option and follow the specific guide:

- [ECS Fargate Deployment](./ecs-fargate/README.md)
- [EKS Deployment](./eks/README.md)
- [EC2 Deployment](./ec2/README.md)
