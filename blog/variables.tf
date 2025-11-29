# ============================================================
# VARIABLES - BLOG WordPress Infrastructure
# ============================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Database Variables
variable "db_snapshot_id" {
  description = "RDS snapshot identifier to restore from"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "wordpressdb"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

# EC2 Variables
variable "instance_type" {
  description = "EC2 instance type (ARM)"
  type        = string
  default     = "t4g.micro"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = "blog-wordpress-key"
}

# Auto Scaling Variables
variable "asg_min_size" {
  description = "ASG minimum size"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "ASG maximum size"
  type        = number
  default     = 3
}

variable "asg_desired_capacity" {
  description = "ASG desired capacity"
  type        = number
  default     = 2
}

# Route53 Variables
variable "domain_name" {
  description = "Base domain name"
  type        = string
  default     = "stack-simi.com"
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID"
  type        = string
  default     = "Z069777410G7QJT8P199L"
}


variable "environment" {
  description = "Environment (dev/test/uat/prod)"
  type        = string
  default     = "dev"
}
