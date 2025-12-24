terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Main provider - deploy to Automation account
provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn     = "arn:aws:iam::289390529512:role/Engineer"
    session_name = "TerraformCLIXX"
  }
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "CLiXX-WordPress"
      ManagedBy   = "Terraform"
    }
  }
}

# Route53 provider - no assume role, already in Management account
provider "aws" {
  alias  = "route53"
  region = var.aws_region
}
