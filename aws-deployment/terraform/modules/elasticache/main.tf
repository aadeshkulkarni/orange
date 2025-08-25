resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.environment}-citrine-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.environment}-citrine-redis-subnet-group"
  })
}

resource "aws_security_group" "redis" {
  name_prefix = "${var.environment}-citrine-redis-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
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
    Name = "${var.environment}-citrine-redis-sg"
  })
}

resource "aws_elasticache_parameter_group" "main" {
  family = "redis7"
  name   = "${var.environment}-citrine-redis-params"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-citrine-redis-params"
  })
}

resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${var.environment}-citrine-redis"
  engine               = "redis"
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.main.name
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]

  tags = merge(var.tags, {
    Name = "${var.environment}-citrine-redis"
  })
}
