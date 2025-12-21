# =============================================================================
# TERRAFORM VARIABLES - CliXX WordPress
# Author: Simi Talabi
# =============================================================================

aws_region            = "us-east-1"
management_account_id = "227764537934"
dev_account_id        = "289390529512"
assume_role_name      = "Engineer"
environment           = "dev"

db_name             = "wordpressdb"
db_username         = "wordpressuser"
db_password         = "W3lcome123"
snapshot_identifier = "arn:aws:rds:us-east-1:289390529512:snapshot:clixxwordpressdb"

ec2_config = {
  instance_type     = "t3.micro"
  volume_size       = 20
  volume_type       = "gp3"
  key_name          = ""
  enable_monitoring = false
}

asg_config = {
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 2
  health_check_grace_period = 300
}

rds_config = {
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  storage_type        = "gp2"
  engine              = "mysql"
  engine_version      = "8.0"
  multi_az            = false
  skip_final_snapshot = true
  publicly_accessible = false
}

domain_name    = "stack-simi.com"
hosted_zone_id = "Z069777410G7QIT8P199L"
