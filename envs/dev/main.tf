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
