# -------------------------------------------------------
# ECR REPOSITORY
# Private Docker image registry for the application.
# ECS pulls images from here at container launch.
# -------------------------------------------------------
resource "aws_ecr_repository" "app" {
  name                 = "${var.project}-${var.environment}-app"
  image_tag_mutability = "IMMUTABLE" # Tags cannot be overwritten — enforces versioning

  # Scan images for vulnerabilities on every push
  image_scanning_configuration {
    scan_on_push = true
  }

  # Encrypt images at rest with KMS
  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = merge(var.tags, {
    Name    = "${var.project}-${var.environment}-app"
    Purpose = "container-registry"
  })
}

# -------------------------------------------------------
# LIFECYCLE POLICY
# Automatically clean up old images to control storage costs.
# Keeps last 10 tagged images, deletes untagged immediately.
# -------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images immediately"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}