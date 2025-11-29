variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "management_account_id" {
  type    = string
  default = "227764537934"
}

variable "dev_account_id" {
  type    = string
  default = "195524911187"
}

variable "assume_role_name" {
  type    = string
  default = "Engineer"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "ec2_config" {
  type = map(any)
  default = {
    instance_type     = "t3.micro"
    volume_size       = 20
    volume_type       = "gp3"
    key_name          = ""
    enable_monitoring = false
  }
}

variable "asg_config" {
  type = map(number)
  default = {
    min_size                  = 1
    max_size                  = 3
    desired_capacity          = 2
    health_check_grace_period = 300
  }
}

variable "rds_config" {
  type = map(any)
  default = {
    instance_class      = "db.t3.micro"
    allocated_storage   = 20
    storage_type        = "gp2"
    engine              = "mysql"
    engine_version      = "8.0"
    db_name             = "wordpressdb"
    db_username         = "wordpressuser"
    multi_az            = false
    skip_final_snapshot = true
    publicly_accessible = false
  }
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "snapshot_identifier" {
  type    = string
  default = ""
}

variable "sg_alb_config" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = {
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
}

variable "sg_ec2_config" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = {
    ssh = {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

variable "sg_rds_config" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
  }))
  default = {
    mysql = {
      description = "MySQL from EC2"
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
    }
  }
}

variable "sg_efs_config" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
  }))
  default = {
    nfs = {
      description = "NFS from EC2"
      from_port   = 2049
      to_port     = 2049
      protocol    = "tcp"
    }
  }
}

variable "efs_config" {
  type = map(any)
  default = {
    encrypted       = true
    throughput_mode = "bursting"
  }
}

variable "ssm_parameters" {
  type = map(string)
  default = {
    db_name = "/clixx/DB_NAME"
    db_user = "/clixx/DB_USER"
    db_pass = "/clixx/DB_PASS"
    db_host = "/clixx/DB_HOST"
  }
}

variable "domain_name" {
  type    = string
  default = "stack-simi.com"
}

variable "hosted_zone_id" {
  type    = string
  default = "Z069777410G7QIT8P199L"
}
