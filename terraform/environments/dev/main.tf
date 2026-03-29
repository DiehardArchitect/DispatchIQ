terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
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