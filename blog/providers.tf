# ============================================================
# PROVIDERS - BLOG WordPress Infrastructure
# ============================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "tls"
      version = "~> 4.0"
    }
    local = {
      source  = "local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
