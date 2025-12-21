# =============================================================================
# VARIABLES - CliXX WordPress
# Author: Simi Talabi
# =============================================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "management_account_id" {
  description = "Management AWS account ID"
  type        = string
  default     = "227764537934"
}

variable "dev_account_id" {
  description = "Dev AWS account ID"
  type        = string
  default     = "289390529512"
}

variable "assume_role_name" {
  description = "IAM role to assume in dev account"
  type        = string
  default     = "Engineer"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "wordpressdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "wordpressuser"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "snapshot_identifier" {
  description = "RDS snapshot ARN to restore from"
  type        = string
  default     = "arn:aws:rds:us-east-1:289390529512:snapshot:clixxwordpressdb"
}

variable "ec2_config" {
  description = "EC2 configuration"
  type        = map(any)
  default = {
    instance_type     = "t3.micro"
    volume_size       = 20
    volume_type       = "gp3"
    key_name          = ""
    enable_monitoring = false
  }
}

variable "asg_config" {
  description = "Auto Scaling Group configuration"
  type        = map(number)
  default = {
    min_size                  = 1
    max_size                  = 3
    desired_capacity          = 2
    health_check_grace_period = 300
  }
}

variable "rds_config" {
  description = "RDS configuration"
  type        = map(any)
  default = {
    instance_class      = "db.t3.micro"
    allocated_storage   = 20
    storage_type        = "gp2"
    engine              = "mysql"
    engine_version      = "8.0"
    multi_az            = false
    skip_final_snapshot = true
    publicly_accessible = false
  }
}

variable "domain_name" {
  description = "Domain name"
  type        = string
  default     = "stack-simi.com"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = "Z069777410G7QIT8P199L"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}
