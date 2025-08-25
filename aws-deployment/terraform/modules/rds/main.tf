resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-citrine-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.environment}-citrine-db-subnet-group"
  })
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.environment}-citrine-rds-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-citrine-rds-sg"
  })
}

resource "aws_db_instance" "main" {
  identifier = "${var.environment}-citrine-db"

  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  backup_retention_period = var.backup_retention_period
  backup_window          = var.backup_window
  maintenance_window     = var.maintenance_window

  deletion_protection = var.deletion_protection
  skip_final_snapshot  = var.skip_final_snapshot

  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval         = var.monitoring_interval

  tags = merge(var.tags, {
    Name = "${var.environment}-citrine-db"
  })
}

resource "aws_db_parameter_group" "main" {
  family = "postgres15"
  name   = "${var.environment}-citrine-db-params"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-citrine-db-params"
  })
}
