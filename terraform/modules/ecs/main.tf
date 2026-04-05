# -------------------------------------------------------
# CLOUDWATCH LOG GROUP
# Container logs go here — stdout/stderr from your app
# -------------------------------------------------------
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project}-${var.environment}"
  retention_in_days = 30

  tags = merge(var.tags, {
    Name    = "${var.project}-${var.environment}-ecs-logs"
    Purpose = "ecs-container-logs"
  })
}

# -------------------------------------------------------
# ECS TASK EXECUTION ROLE
# Used by ECS control plane to:
# - Pull images from ECR
# - Write logs to CloudWatch
# - Fetch secrets from Secrets Manager
# Different from the task role (which is used by your app code)
# -------------------------------------------------------
resource "aws_iam_role" "ecs_execution" {
  name = "${var.project}-${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "ECSAssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-ecs-execution-role"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow execution role to fetch secrets from Secrets Manager
resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${var.project}-${var.environment}-ecs-execution-secrets"
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GetSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = [
          var.secrets_arn,
          var.kms_key_arn
        ]
      }
    ]
  })
}

# -------------------------------------------------------
# ECS TASK ROLE
# Used by your application code running inside the container
# to call other AWS services
# -------------------------------------------------------
resource "aws_iam_role" "ecs_task" {
  name = "${var.project}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "ECSTaskAssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-ecs-task-role"
  })
}

# -------------------------------------------------------
# ECS CLUSTER
# Logical grouping for your Fargate tasks
# -------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-cluster"
  })
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}

# -------------------------------------------------------
# ECS TASK DEFINITION
# Blueprint for your container — CPU, memory, image, ports
# environment variables, log config, secrets
# -------------------------------------------------------
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project}-${var.environment}-app"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "app"
    image     = "${var.ecr_repository_url}:latest"
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "app"
      }
    }

    secrets = [{
      name      = "DB_CREDENTIALS"
      valueFrom = var.secrets_arn
    }]

    environment = [
      {
        name  = "ENVIRONMENT"
        value = var.environment
      },
      {
        name  = "PORT"
        value = tostring(var.container_port)
      }
    ]
  }])

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-app-task"
  })
}

# -------------------------------------------------------
# APPLICATION LOAD BALANCER
# Public-facing, routes internet traffic to ECS tasks
# -------------------------------------------------------
resource "aws_lb" "main" {
  name               = "${var.project}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false # Dev only — set true in production

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-alb"
  })
}

resource "aws_lb_target_group" "app" {
  name        = "${var.project}-${var.environment}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # Required for Fargate — tasks get IPs not instance IDs

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    matcher             = "200"
  }

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-tg"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Redirect HTTP to HTTPS in production
  # Using forward for dev since we have no SSL cert yet
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# -------------------------------------------------------
# ECS SERVICE
# Keeps desired_count tasks running, registers them
# with the ALB target group automatically
# -------------------------------------------------------
resource "aws_ecs_service" "app" {
  name            = "${var.project}-${var.environment}-app-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.app_sg_id]
    assign_public_ip = false # Private subnets — NAT Gateway handles outbound
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-app-service"
  })
}