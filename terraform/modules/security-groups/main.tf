# -------------------------------------------------------
# SECURITY GROUPS — created empty first to break the cycle
# Rules are added separately below
# -------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-alb-sg"
  })
}

resource "aws_security_group" "app" {
  name        = "${var.project}-${var.environment}-app-sg"
  description = "Security group for application instances"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-app-sg"
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-rds-sg"
  })
}

# -------------------------------------------------------
# ALB RULES
# -------------------------------------------------------

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  description       = "HTTP from internet"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  description       = "HTTPS from internet"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress_app" {
  type                     = "egress"
  description              = "To app instances"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.alb.id
}

# -------------------------------------------------------
# APP RULES
# -------------------------------------------------------

resource "aws_security_group_rule" "app_ingress_alb" {
  type                     = "ingress"
  description              = "From ALB"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_egress_rds" {
  type                     = "egress"
  description              = "To RDS"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.rds.id
  security_group_id        = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_egress_https" {
  type              = "egress"
  description       = "HTTPS to AWS services via VPC endpoints"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.use_vpc_endpoints ? [var.vpc_cidr] : ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_egress_dns" {
  type              = "egress"
  description       = "DNS resolution"
  from_port         = 53
  to_port           = 53
  protocol          = "udp"
  cidr_blocks       = var.use_vpc_endpoints ? [var.vpc_cidr] : ["0.0.0.0/0"]
  security_group_id = aws_security_group.app.id
}

# -------------------------------------------------------
# RDS RULES
# -------------------------------------------------------

resource "aws_security_group_rule" "rds_ingress_app" {
  type                     = "ingress"
  description              = "PostgreSQL from app"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.rds.id
}