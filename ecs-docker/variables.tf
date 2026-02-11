# ============================================================
# variables.tf - Variable Declarations
# ============================================================

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "Your existing VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of your PUBLIC subnet IDs (for ECS instances and NLB)"
  type        = list(string)
}

variable "key_pair_name" {
  description = "Name of your EC2 key pair for SSH access"
  type        = string
  default     = "jenkins-key-2"
}

variable "ecr_repo_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = "clixx-repository"
}

variable "docker_image_tag" {
  description = "Tag of the Docker image in ECR"
  type        = string
  default     = "clixx-img-1.0"
}

variable "db_host" {
  description = "RDS endpoint for WordPress database"
  type        = string
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "wordpressuser"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "wordpressdb"
}

# ---------------------------
# ROUTE 53 VARIABLES
# ---------------------------
variable "hosted_zone_id" {
  description = "Route 53 Hosted Zone ID (in management account)"
  type        = string
  default     = "Z069777410G7QIT8P199L"
}

variable "domain_name" {
  description = "The subdomain to create for ECS (e.g. ecs.stack-simi.com)"
  type        = string
  default     = "ecs.stack-simi.com"
}

variable "management_account_role_arn" {
  description = "IAM role ARN in management account for Route 53 access"
  type        = string
}
