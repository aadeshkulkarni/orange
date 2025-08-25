resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-citrine-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-citrine-cluster"
  })
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-citrine-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-citrine-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Security Group for ECS Services
resource "aws_security_group" "ecs_services" {
  name_prefix = "${var.environment}-citrine-ecs-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8080
    to_port         = 8085
    protocol        = "tcp"
    security_groups = var.alb_security_group_ids
  }

  ingress {
    from_port       = 8443
    to_port         = 8444
    protocol        = "tcp"
    security_groups = var.alb_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-citrine-ecs-sg"
  })
}

# CloudWatch Log Group for Citrine
resource "aws_cloudwatch_log_group" "citrine" {
  name              = "/ecs/${var.environment}-citrine"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.environment}-citrine-logs"
  })
}

# CloudWatch Log Group for Directus
resource "aws_cloudwatch_log_group" "directus" {
  name              = "/ecs/${var.environment}-directus"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name = "${var.environment}-directus-logs"
  })
}

# ECS Task Definition for Citrine
resource "aws_ecs_task_definition" "citrine" {
  family                   = "${var.environment}-citrine"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.citrine_cpu
  memory                   = var.citrine_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "citrine"
      image = var.citrine_image

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        },
        {
          containerPort = 8081
          protocol      = "tcp"
        },
        {
          containerPort = 8082
          protocol      = "tcp"
        },
        {
          containerPort = 8085
          protocol      = "tcp"
        },
        {
          containerPort = 8443
          protocol      = "tcp"
        },
        {
          containerPort = 8444
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "APP_NAME"
          value = "all"
        },
        {
          name  = "APP_ENV"
          value = "aws"
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]

      secrets = [
        {
          name      = "BOOTSTRAP_CITRINEOS_DATABASE_PASSWORD"
          valueFrom = var.database_password_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.citrine.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.environment}-citrine-task-def"
  })
}

# ECS Task Definition for Directus
resource "aws_ecs_task_definition" "directus" {
  family                   = "${var.environment}-directus"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.directus_cpu
  memory                   = var.directus_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "directus"
      image = var.directus_image

      portMappings = [
        {
          containerPort = 8055
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "APP_NAME"
          value = "all"
        },
        {
          name  = "KEY"
          value = var.directus_key
        },
        {
          name  = "SECRET"
          value = var.directus_secret
        },
        {
          name  = "ADMIN_EMAIL"
          value = var.directus_admin_email
        },
        {
          name  = "ADMIN_PASSWORD"
          value = var.directus_admin_password
        },
        {
          name  = "DB_CLIENT"
          value = "pg"
        },
        {
          name  = "DB_HOST"
          value = var.database_host
        },
        {
          name  = "DB_PORT"
          value = tostring(var.database_port)
        },
        {
          name  = "DB_DATABASE"
          value = var.database_name
        },
        {
          name  = "DB_USER"
          value = var.database_username
        },
        {
          name  = "WEBSOCKETS_ENABLED"
          value = "true"
        }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = var.database_password_secret_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.directus.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = merge(var.tags, {
    Name = "${var.environment}-directus-task-def"
  })
}
