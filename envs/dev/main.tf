terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Project   = "rp-nutrition-cloudship"
      Env       = "dev"
      ManagedBy = "terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name                 = "rp-cloudship-dev"
  vpc_cidr             = "10.20.0.0/16"
  azs                  = ["ap-south-1a", "ap-south-1b"]
  public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24"]
  private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24"]
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

module "ecr" {
  source = "../../modules/ecr"

  name         = "rp-nutrition-app"
  force_delete = true
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

module "secrets" {
  source = "../../modules/secrets"

  secret_names = ["rp-nutrition/dev/jwt-secret"]
}

output "secret_arns" {
  value = module.secrets.secret_arns
}

module "alb" {
  source = "../../modules/alb"

  name              = "rp-cloudship-dev"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

output "alb_dns_name" {
  value = module.alb.alb_dns_name
}

module "ecs" {
  source = "../../modules/ecs"

  name                  = "rp-cloudship-dev"
  region                = "ap-south-1"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.public_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
  image                 = "${module.ecr.repository_url}:v1"

  environment = {
    DATABASE_URL = "postgresql://placeholder:placeholder@localhost:5432/placeholder"
  }

  secrets = {
    JWT_SECRET_KEY = module.secrets.secret_arns["rp-nutrition/dev/jwt-secret"]
  }

  depends_on = [module.alb]
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}
