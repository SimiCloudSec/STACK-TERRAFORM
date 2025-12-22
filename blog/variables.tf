variable "aws_region" { default = "us-east-1" }
variable "environment" { default = "dev" }
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "public_subnet_cidrs" { default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"] }
variable "private_subnet_cidrs" { default = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"] }
variable "availability_zones" { default = ["us-east-1a", "us-east-1b", "us-east-1c"] }
variable "ec2_config" {
  type = object({ instance_type = string, volume_size = number, volume_type = string, key_name = string, enable_monitoring = bool })
  default = { instance_type = "t3.micro", volume_size = 30, volume_type = "gp3", key_name = "blog-wordpress-key", enable_monitoring = false }
}
variable "asg_config" {
  type = object({ min_size = number, max_size = number, desired_capacity = number, health_check_grace_period = number })
  default = { min_size = 1, max_size = 3, desired_capacity = 2, health_check_grace_period = 300 }
}
variable "rds_config" {
  type = object({ identifier = string, instance_class = string, db_name = string, db_username = string, db_password = string, snapshot_arn = string, multi_az = bool, skip_final_snapshot = bool, publicly_accessible = bool })
  default = { identifier = "blog-dev-db", instance_class = "db.t3.micro", db_name = "wordpress_db", db_username = "admin", db_password = "Alienpython123", snapshot_arn = "arn:aws:rds:us-east-1:227764537934:snapshot:wordpressinstance2", multi_az = false, skip_final_snapshot = true, publicly_accessible = false }
}
variable "efs_config" {
  type = object({ encrypted = bool, throughput_mode = string, performance_mode = string })
  default = { encrypted = true, throughput_mode = "bursting", performance_mode = "generalPurpose" }
}
variable "domain_name" { type = string }
variable "hosted_zone_id" { type = string }
