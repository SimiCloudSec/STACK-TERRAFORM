terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Main provider - your dev account (simi_automation)
provider "aws" {
  region = var.aws_region
}

# Route 53 provider - management account (227764537934)
provider "aws" {
  alias   = "route53"
  region  = var.aws_region
  profile = "stack_simi_admin"
}
