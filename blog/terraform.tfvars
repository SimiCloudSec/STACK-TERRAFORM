aws_region  = "us-east-1"
environment = "dev"
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
ec2_config = { instance_type = "t3.micro", volume_size = 30, volume_type = "gp3", key_name = "blog-wordpress-key", enable_monitoring = false }
asg_config = { min_size = 1, max_size = 3, desired_capacity = 2, health_check_grace_period = 300 }
rds_config = { identifier = "blog-dev-db", instance_class = "db.t3.micro", db_name = "wordpress_db", db_username = "admin", db_password = "Alienpython123", snapshot_arn = "arn:aws:rds:us-east-1:227764537934:snapshot:wordpressinstance2-shared", multi_az = false, skip_final_snapshot = true, publicly_accessible = false }
efs_config = { encrypted = true, throughput_mode = "bursting", performance_mode = "generalPurpose" }
domain_name    = "stack-simi.com"
hosted_zone_id = "Z069777410G7QIT8P199L"
