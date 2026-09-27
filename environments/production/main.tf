terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket       = "terraform-state-176777036414-us-east-1"
    key          = "production/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = local.common_tags
  }
}

locals {
  environment = "production"
  name_prefix = "ecommerce-${local.environment}"
  common_tags = {
    Environment = local.environment
    Project     = "ecommerce"
    ManagedBy   = "terraform"
  }
}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix        = local.name_prefix
  vpc_cidr           = "10.2.0.0/16"
  public_subnet_cidrs = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  private_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  enable_nat_gateway = false
  tags               = local.common_tags
}

module "jumphost" {
  source = "../../modules/ec2_jumphost"

  name_prefix   = local.name_prefix
  vpc_id        = module.vpc.vpc_id
  subnet_id     = module.vpc.public_subnet_ids[0]
  ami_id        = "ami-0332d564d76dbd8d6"  # Amazon Linux 2023
  instance_type = "c7i-flex.large"
  key_name      = "pc"
  user_data     = templatefile("../../modules/ec2_jumphost/templates/user_data.sh.tpl", {})
  tags          = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  name_prefix        = local.name_prefix
  kubernetes_version = "1.35"
  subnet_ids         = module.vpc.public_subnet_ids
  node_subnet_ids    = module.vpc.public_subnet_ids
  node_instance_type = "c7i-flex.large"
  node_desired_size  = 3
  node_min_size      = 2
  node_max_size      = 6
  tags               = local.common_tags
}

module "dockerhub" {
  source = "../../modules/dockerhub"

  dockerhub_username = "ravibhadarge"
  environment        = local.environment
  service_names = [
    "frontend",
    "catalog-service",
    "cart-service",
    "order-service",
    "payment-service",
    "user-service",
    "notification-service",
    "admin-dashboard"
  ]
}

module "s3" {
  source = "../../modules/s3"

  name_prefix = local.name_prefix
  tags        = local.common_tags
}
