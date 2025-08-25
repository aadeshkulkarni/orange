# ECS Task Role Policy for Citrine
resource "aws_iam_policy" "citrine_task_policy" {
  name        = "${var.environment}-citrine-task-policy"
  description = "Policy for Citrine ECS task role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = [
          var.database_password_secret_arn,
          "arn:aws:kms:${var.aws_region}:${var.aws_account_id}:key/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${var.s3_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = [
          var.sqs_queue_arn
        ]
      }
    ]
  })
}

# ECS Task Role Policy for Directus
resource "aws_iam_policy" "directus_task_policy" {
  name        = "${var.environment}-directus-task-policy"
  description = "Policy for Directus ECS task role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = [
          var.database_password_secret_arn,
          "arn:aws:kms:${var.aws_region}:${var.aws_account_id}:key/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Attach policies to ECS task roles
resource "aws_iam_role_policy_attachment" "citrine_task_policy" {
  role       = var.citrine_task_role_name
  policy_arn = aws_iam_policy.citrine_task_policy.arn
}

resource "aws_iam_role_policy_attachment" "directus_task_policy" {
  role       = var.directus_task_role_name
  policy_arn = aws_iam_policy.directus_task_policy.arn
}

# S3 Bucket Policy for file storage
resource "aws_s3_bucket_policy" "main" {
  bucket = var.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowECSTasksAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            var.citrine_task_role_arn,
            var.directus_task_role_arn
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}
