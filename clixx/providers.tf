terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Main provider - Automation account (Jenkins is already here)
provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn     = "arn:aws:iam::289390529512:role/Engineer"
    session_name = "TerraformCLiXX"
  }
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "CLiXX-WordPress"
      ManagedBy   = "Terraform"
    }
  }
}

# Route53 provider - Management account
provider "aws" {
  alias  = "route53"
  region = var.aws_region
  assume_role {
    role_arn     = "arn:aws:iam::227764537934:role/JenkinsDeployRole"
    session_name = "TerraformCLiXXRoute53"
  }
}
