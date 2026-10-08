terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

# ---------- Primary region ----------
module "vpc_primary" {
  source    = "./modules/vpc"
  providers = { aws = aws.primary }

  name     = "iaac-primary"
  vpc_cidr = "10.0.0.0/16"
}

module "compute_primary" {
  source    = "./modules/compute"
  providers = { aws = aws.primary }

  name               = "iaac-pri"
  vpc_id             = module.vpc_primary.vpc_id
  public_subnet_ids  = module.vpc_primary.public_subnet_ids
  private_subnet_ids = module.vpc_primary.private_subnet_ids
}

# ---------- Secondary region ----------
module "vpc_secondary" {
  source    = "./modules/vpc"
  providers = { aws = aws.secondary }

  name     = "iaac-secondary"
  vpc_cidr = "10.1.0.0/16"
}

module "compute_secondary" {
  source    = "./modules/compute"
  providers = { aws = aws.secondary }

  name               = "iaac-sec"
  vpc_id             = module.vpc_secondary.vpc_id
  public_subnet_ids  = module.vpc_secondary.public_subnet_ids
  private_subnet_ids = module.vpc_secondary.private_subnet_ids
}
