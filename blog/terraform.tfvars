# TERRAFORM VARIABLES - BLOG WordPress Infrastructure

aws_region  = "us-east-1"
environment = "dev"

# EC2 Configuration
ec2_config = {
  instance_type     = "t3.micro"
  volume_size       = 30
  volume_type       = "gp3"
  key_name          = "blog-wordpress-key"
  enable_monitoring = false
}

# Auto Scaling Configuration
asg_config = {
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 2
  health_check_grace_period = 300
}

# RDS Configuration - ALL DB INFO HERE
rds_config = {
  identifier          = "blog-dev-db"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  storage_type        = "gp2"
  engine              = "mysql"
  engine_version      = "8.0"
  db_name             = "wordpress_db"
  db_username         = "admin"
  db_password         = "Alienpython123"
  snapshot_identifier = "wordpressinstance2"
  snapshot_arn        = "arn:aws:rds:us-east-1:227764537934:snapshot:wordpressinstance2"
  multi_az            = false
  skip_final_snapshot = true
  publicly_accessible = false
  storage_encrypted   = true
}

# EFS Configuration
efs_config = {
  encrypted        = true
  throughput_mode  = "bursting"
  performance_mode = "generalPurpose"
}

# Security Group Configurations
sg_alb_config = {
  http = {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  https = {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

sg_ec2_config = {
  ssh = {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

sg_rds_config = {
  mysql = {
    description = "MySQL from EC2"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  }
}

sg_efs_config = {
  nfs = {
    description = "NFS from EC2"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
  }
}

# Route53
domain_name    = "stack-simi.com"
hosted_zone_id = "Z069777410G7QIT8P199L"

# =============================================================================
# VPC CONFIGURATION
# =============================================================================
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
