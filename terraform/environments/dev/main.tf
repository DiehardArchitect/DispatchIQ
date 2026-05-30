terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  backend "s3" {
    bucket         = "terraform-state-975050048256-us-east-1"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
locals {
  project_name = "${var.project_name}-dev"
  common_tags = {
    Project     = var.project_name
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
module "vpc" {
  source             = "../../modules/vpc"
  project_name       = local.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  common_tags        = local.common_tags
}
module "kms" {
  source         = "../../modules/kms"
  environment    = "dev"
  project        = var.project_name
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
  tags           = local.common_tags
}
module "iam" {
  source         = "../../modules/iam"
  environment    = "dev"
  project        = var.project_name
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
  kms_key_arns = [
    module.kms.ebs_key_arn,
    module.kms.rds_key_arn,
    module.kms.s3_key_arn,
    module.kms.secrets_key_arn
  ]
  tags = local.common_tags
}
module "security_groups" {
  source            = "../../modules/security-groups"
  environment       = "dev"
  project           = var.project_name
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = var.vpc_cidr
  use_vpc_endpoints = var.use_vpc_endpoints
  tags              = local.common_tags
}
module "secrets_manager" {
  source      = "../../modules/secrets-manager"
  environment = "dev"
  project     = var.project_name
  kms_key_arn = module.kms.secrets_key_arn
  tags        = local.common_tags
}
module "cloudtrail" {
  source         = "../../modules/cloudtrail"
  environment    = "dev"
  project        = var.project_name
  aws_account_id = var.aws_account_id
  aws_region     = var.aws_region
  kms_key_arn    = module.kms.s3_key_arn
  tags           = local.common_tags
}
module "ecr" {
  source      = "../../modules/ecr"
  environment = "dev"
  project     = var.project_name
  kms_key_arn = module.kms.s3_key_arn
  tags        = local.common_tags
}
module "ecs" {
  source             = "../../modules/ecs"
  environment        = "dev"
  project            = var.project_name
  aws_account_id     = var.aws_account_id
  aws_region         = var.aws_region
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  alb_sg_id          = module.security_groups.alb_sg_id
  app_sg_id          = module.security_groups.app_sg_id
  ecr_repository_url = module.ecr.repository_url
  kms_key_arn        = module.kms.secrets_key_arn
  secrets_arn        = module.secrets_manager.db_credentials_arn
  tags               = local.common_tags
}

module "vpc_endpoints" {
  source                  = "../../modules/vpc-endpoints"
  enabled                 = var.use_vpc_endpoints
  project_name            = var.project_name
  environment             = "dev"
  region                  = var.aws_region
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  private_route_table_ids = module.vpc.private_route_table_ids
  app_security_group_id   = module.security_groups.app_sg_id
}

module "rds" {
  source = "../../modules/rds"
  count  = var.deploy_rds ? 1 : 0

  project            = var.project_name
  environment        = "dev"
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security_groups.rds_sg_id
  kms_key_arn        = module.kms.rds_key_arn

  instance_class      = "db.t4g.micro"
  allocated_storage   = 20
  multi_az            = false
  skip_final_snapshot = true
  deletion_protection = false

  tags = local.common_tags
}
