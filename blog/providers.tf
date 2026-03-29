terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# Main provider - Management account
provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn     = "arn:aws:iam::227764537934:role/JenkinsDeployRole"
    session_name = "TerraformBlog"
  }
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "BLOG-WordPress"
      ManagedBy   = "Terraform"
    }
  }
}

# Route53 - same Management account
provider "aws" {
  alias  = "route53"
  region = var.aws_region
  assume_role {
    role_arn     = "arn:aws:iam::227764537934:role/JenkinsDeployRole"
    session_name = "TerraformBlogRoute53"
  }
}
