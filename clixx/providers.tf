terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn     = "arn:aws:iam::${var.dev_account_id}:role/${var.assume_role_name}"
    session_name = "TerraformCLiXXDeployment"
  }

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "CLiXX-WordPress"
      ManagedBy   = "Terraform"
    }
  }
}

provider "aws" {
  alias  = "route53"
  region = var.aws_region
}
