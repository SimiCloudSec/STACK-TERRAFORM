#!/bin/bash
###############################################################################
# SETUP_PROJECT.SH - Complete CLiXX Terraform Project Builder (FIXED)
###############################################################################
# - Restores from snapshot: clixxwordpressdb
# - Correct DB credentials for CLiXX
# - MySQL client installed for debugging
# - All instructor requirements included
###############################################################################

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   CLiXX WordPress Terraform - FIXED Project Setup             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================
# CREATE DIRECTORY STRUCTURE
# ============================================================
mkdir -p modules/{alb,asg,efs,lt,rds,route53,sg,sg_alb,sg_ec2,sg_rds,ssm,tg}
mkdir -p scripts
echo "✓ Directories created"

# ============================================================
# PROVIDERS.TF
# ============================================================
cat > providers.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn     = "arn:aws:iam::${var.dev_account_id}:role/${var.assume_role_name}"
    session_name = "TerraformCLiXXDeployment"
  }

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "CLiXX-WordPress"
      ManagedBy   = "Terraform"
    }
  }
}

provider "aws" {
  alias  = "route53"
  region = var.aws_region
}
EOF
echo "✓ providers.tf"

# ============================================================
# VARIABLES.TF
# ============================================================
cat > variables.tf << 'EOF'
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
EOF
echo "✓ variables.tf"

# ============================================================
# TERRAFORM.TFVARS - WITH CORRECT VALUES
# ============================================================
cat > terraform.tfvars << 'EOF'
aws_region            = "us-east-1"
management_account_id = "227764537934"
dev_account_id        = "195524911187"
assume_role_name      = "Engineer"
environment           = "dev"

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
  db_name             = "wordpressdb"
  db_username         = "wordpressuser"
  multi_az            = false
  skip_final_snapshot = true
  publicly_accessible = false
}

# CORRECT PASSWORD - must match RDS
db_password = "Alienpython1_"

# RESTORE FROM SNAPSHOT
snapshot_identifier = "clixxwordpressdb"

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

efs_config = {
  encrypted       = true
  throughput_mode = "bursting"
}

ssm_parameters = {
  db_name = "/clixx/DB_NAME"
  db_user = "/clixx/DB_USER"
  db_pass = "/clixx/DB_PASS"
  db_host = "/clixx/DB_HOST"
}

domain_name    = "stack-simi.com"
hosted_zone_id = "Z069777410G7QIT8P199L"
EOF
echo "✓ terraform.tfvars"

# ============================================================
# DATASOURCES.TF
# ============================================================
cat > datasources.tf << 'EOF'
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
EOF
echo "✓ datasources.tf"

# ============================================================
# OUTPUTS.TF
# ============================================================
cat > outputs.tf << 'EOF'
output "wordpress_url" {
  value = "http://${module.route53.fqdn}"
}

output "alb_dns_name" {
  value = module.alb.alb_dns
}

output "custom_domain" {
  value = module.route53.fqdn
}

output "efs_id" {
  value = module.efs.efs_id
}

output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "environment" {
  value = var.environment
}
EOF
echo "✓ outputs.tf"

# ============================================================
# VERSIONS.TF
# ============================================================
cat > versions.tf << 'EOF'
terraform {
  required_version = ">= 1.0"
}
EOF
echo "✓ versions.tf"

# ============================================================
# MAIN.TF
# ============================================================
cat > main.tf << 'EOF'
# Security Groups
module "sg_alb" {
  source        = "./modules/sg_alb"
  vpc_id        = data.aws_vpc.default.id
  sg_alb_config = var.sg_alb_config
  environment   = var.environment
}

module "sg_ec2" {
  source        = "./modules/sg_ec2"
  vpc_id        = data.aws_vpc.default.id
  alb_sg_id     = module.sg_alb.sg_id
  sg_ec2_config = var.sg_ec2_config
  environment   = var.environment
}

module "sg_rds" {
  source        = "./modules/sg_rds"
  vpc_id        = data.aws_vpc.default.id
  ec2_sg_id     = module.sg_ec2.sg_id
  sg_rds_config = var.sg_rds_config
  environment   = var.environment
}

module "sg" {
  source        = "./modules/sg"
  vpc_id        = data.aws_vpc.default.id
  ec2_sg_id     = module.sg_ec2.sg_id
  sg_efs_config = var.sg_efs_config
  environment   = var.environment
}

# Storage & Database
module "efs" {
  source      = "./modules/efs"
  subnet_ids  = data.aws_subnets.default.ids
  efs_sg_id   = module.sg.sg_id
  efs_config  = var.efs_config
  environment = var.environment
}

module "rds" {
  source              = "./modules/rds"
  subnet_ids          = data.aws_subnets.default.ids
  rds_sg_id           = module.sg_rds.sg_id
  rds_config          = var.rds_config
  db_password         = var.db_password
  environment         = var.environment
  snapshot_identifier = var.snapshot_identifier
}

# SSM & IAM
module "ssm" {
  source         = "./modules/ssm"
  rds_config     = var.rds_config
  db_password    = var.db_password
  db_host        = module.rds.db_endpoint
  aws_region     = var.aws_region
  ssm_parameters = var.ssm_parameters
  environment    = var.environment
}

# Load Balancer
module "alb" {
  source      = "./modules/alb"
  subnet_ids  = data.aws_subnets.default.ids
  alb_sg_id   = module.sg_alb.sg_id
  vpc_id      = data.aws_vpc.default.id
  environment = var.environment
}

module "tg" {
  source      = "./modules/tg"
  vpc_id      = data.aws_vpc.default.id
  environment = var.environment
}

resource "aws_lb_listener" "wordpress" {
  load_balancer_arn = module.alb.alb_arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = module.tg.tg_arn
  }
}

# Compute
module "lt" {
  source      = "./modules/lt"
  ami_id      = data.aws_ami.amazon_linux_2023.id
  ec2_config  = var.ec2_config
  ec2_sg_id   = module.sg_ec2.sg_id
  efs_id      = module.efs.efs_id
  aws_region  = var.aws_region
  site_url    = "${var.environment}.clixx.${var.domain_name}"
  iam_profile = module.ssm.iam_instance_profile
  environment = var.environment
}

module "asg" {
  source             = "./modules/asg"
  subnet_ids         = data.aws_subnets.default.ids
  target_group_arn   = module.tg.tg_arn
  launch_template_id = module.lt.lt_id
  asg_config         = var.asg_config
  environment        = var.environment
}

# DNS
module "route53" {
  source         = "./modules/route53"
  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id
  environment    = var.environment
  alb_dns_name   = module.alb.alb_dns
  alb_zone_id    = module.alb.alb_zone_id

  providers = {
    aws = aws.route53
  }
}
EOF
echo "✓ main.tf"

# ============================================================
# MODULES
# ============================================================

# SG_ALB
cat > modules/sg_alb/main.tf << 'EOF'
variable "vpc_id" { type = string }
variable "environment" { type = string }
variable "sg_alb_config" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

resource "aws_security_group" "alb_sg" {
  name        = "clixx-${var.environment}-alb-sg"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.sg_alb_config
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "clixx-${var.environment}-alb-sg" }
}

output "sg_id" { value = aws_security_group.alb_sg.id }
EOF

# SG_EC2
cat > modules/sg_ec2/main.tf << 'EOF'
variable "vpc_id" { type = string }
variable "alb_sg_id" { type = string }
variable "environment" { type = string }
variable "sg_ec2_config" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

resource "aws_security_group" "ec2_sg" {
  name        = "clixx-${var.environment}-ec2-sg"
  description = "EC2 Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }

  dynamic "ingress" {
    for_each = var.sg_ec2_config
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "clixx-${var.environment}-ec2-sg" }
}

output "sg_id" { value = aws_security_group.ec2_sg.id }
EOF

# SG_RDS
cat > modules/sg_rds/main.tf << 'EOF'
variable "vpc_id" { type = string }
variable "ec2_sg_id" { type = string }
variable "environment" { type = string }
variable "sg_rds_config" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
  }))
}

resource "aws_security_group" "rds_sg" {
  name        = "clixx-${var.environment}-rds-sg"
  description = "RDS Security Group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.sg_rds_config
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      security_groups = [var.ec2_sg_id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "clixx-${var.environment}-rds-sg" }
}

output "sg_id" { value = aws_security_group.rds_sg.id }
EOF

# SG (EFS)
cat > modules/sg/main.tf << 'EOF'
variable "vpc_id" { type = string }
variable "ec2_sg_id" { type = string }
variable "environment" { type = string }
variable "sg_efs_config" {
  type = map(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
  }))
}

resource "aws_security_group" "efs_sg" {
  name        = "clixx-${var.environment}-efs-sg"
  description = "EFS Security Group"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.sg_efs_config
    content {
      description     = ingress.value.description
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      security_groups = [var.ec2_sg_id]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "clixx-${var.environment}-efs-sg" }
}

output "sg_id" { value = aws_security_group.efs_sg.id }
EOF

# EFS
cat > modules/efs/main.tf << 'EOF'
variable "subnet_ids" { type = list(string) }
variable "efs_sg_id" { type = string }
variable "environment" { type = string }
variable "efs_config" { type = map(any) }

resource "aws_efs_file_system" "wordpress" {
  creation_token = "clixx-${var.environment}-efs"
  encrypted      = var.efs_config["encrypted"]
  tags           = { Name = "clixx-${var.environment}-efs" }
}

resource "aws_efs_mount_target" "wordpress" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [var.efs_sg_id]
}

output "efs_id" { value = aws_efs_file_system.wordpress.id }
EOF

# RDS - WITH SNAPSHOT SUPPORT
cat > modules/rds/main.tf << 'EOF'
variable "subnet_ids" { type = list(string) }
variable "rds_sg_id" { type = string }
variable "environment" { type = string }
variable "rds_config" { type = map(any) }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "snapshot_identifier" {
  type    = string
  default = ""
}

resource "aws_db_subnet_group" "wordpress" {
  name       = "clixx-${var.environment}-db-subnet"
  subnet_ids = var.subnet_ids
  tags       = { Name = "clixx-${var.environment}-db-subnet" }
}

resource "aws_db_instance" "wordpress" {
  identifier             = "clixx-${var.environment}-db"
  snapshot_identifier    = var.snapshot_identifier != "" ? var.snapshot_identifier : null
  instance_class         = var.rds_config["instance_class"]
  db_subnet_group_name   = aws_db_subnet_group.wordpress.name
  vpc_security_group_ids = [var.rds_sg_id]
  skip_final_snapshot    = var.rds_config["skip_final_snapshot"]
  multi_az               = var.rds_config["multi_az"]
  publicly_accessible    = var.rds_config["publicly_accessible"]
  tags                   = { Name = "clixx-${var.environment}-db" }
}

output "db_endpoint" { value = aws_db_instance.wordpress.address }
EOF

# SSM
cat > modules/ssm/main.tf << 'EOF'
variable "rds_config" { type = map(any) }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_host" { type = string }
variable "aws_region" { type = string }
variable "ssm_parameters" { type = map(string) }
variable "environment" { type = string }

resource "aws_ssm_parameter" "db_name" {
  name      = var.ssm_parameters["db_name"]
  type      = "String"
  value     = var.rds_config["db_name"]
  overwrite = true
  tags      = { Environment = var.environment }
}

resource "aws_ssm_parameter" "db_user" {
  name      = var.ssm_parameters["db_user"]
  type      = "String"
  value     = var.rds_config["db_username"]
  overwrite = true
  tags      = { Environment = var.environment }
}

resource "aws_ssm_parameter" "db_pass" {
  name      = var.ssm_parameters["db_pass"]
  type      = "SecureString"
  value     = var.db_password
  overwrite = true
  tags      = { Environment = var.environment }
}

resource "aws_ssm_parameter" "db_host" {
  name      = var.ssm_parameters["db_host"]
  type      = "String"
  value     = var.db_host
  overwrite = true
  tags      = { Environment = var.environment }
}

resource "aws_iam_role" "ec2" {
  name = "clixx-${var.environment}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "ssm" {
  name = "clixx-${var.environment}-ssm-policy"
  role = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = ["arn:aws:ssm:${var.aws_region}:*:parameter/clixx/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "clixx-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

output "iam_instance_profile" { value = aws_iam_instance_profile.ec2.name }
EOF

# ALB
cat > modules/alb/main.tf << 'EOF'
variable "subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "vpc_id" { type = string }
variable "environment" { type = string }

resource "aws_lb" "wordpress" {
  name               = "clixx-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.subnet_ids
  tags               = { Name = "clixx-${var.environment}-alb" }
}

output "alb_arn" { value = aws_lb.wordpress.arn }
output "alb_dns" { value = aws_lb.wordpress.dns_name }
output "alb_zone_id" { value = aws_lb.wordpress.zone_id }
EOF

# TG
cat > modules/tg/main.tf << 'EOF'
variable "vpc_id" { type = string }
variable "environment" { type = string }

resource "aws_lb_target_group" "wordpress" {
  name     = "clixx-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200,301,302"
  }

  tags = { Name = "clixx-${var.environment}-tg" }
}

output "tg_arn" { value = aws_lb_target_group.wordpress.arn }
EOF

# LT - Launch Template
cat > modules/lt/main.tf << 'EOF'
variable "ami_id" { type = string }
variable "ec2_config" { type = map(any) }
variable "ec2_sg_id" { type = string }
variable "efs_id" { type = string }
variable "aws_region" { type = string }
variable "site_url" { type = string }
variable "iam_profile" { type = string }
variable "environment" { type = string }

resource "aws_launch_template" "wordpress" {
  name_prefix   = "clixx-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.ec2_config["instance_type"]

  iam_instance_profile { name = var.iam_profile }
  vpc_security_group_ids = [var.ec2_sg_id]

  user_data = base64encode(templatefile("${path.root}/scripts/clixx_bootstrap.sh", {
    efs_id     = var.efs_id
    aws_region = var.aws_region
    site_url   = var.site_url
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "clixx-${var.environment}-instance" }
  }
}

output "lt_id" { value = aws_launch_template.wordpress.id }
EOF

# ASG
cat > modules/asg/main.tf << 'EOF'
variable "subnet_ids" { type = list(string) }
variable "target_group_arn" { type = string }
variable "launch_template_id" { type = string }
variable "environment" { type = string }
variable "asg_config" { type = map(number) }

resource "aws_autoscaling_group" "wordpress" {
  name                      = "clixx-${var.environment}-asg"
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = var.asg_config["health_check_grace_period"]
  min_size                  = var.asg_config["min_size"]
  max_size                  = var.asg_config["max_size"]
  desired_capacity          = var.asg_config["desired_capacity"]

  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "clixx-${var.environment}-asg-instance"
    propagate_at_launch = true
  }
}
EOF

# ROUTE53
cat > modules/route53/main.tf << 'EOF'
terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

variable "domain_name" { type = string }
variable "hosted_zone_id" { type = string }
variable "environment" { type = string }
variable "alb_dns_name" { type = string }
variable "alb_zone_id" { type = string }

resource "aws_route53_record" "wordpress" {
  zone_id = var.hosted_zone_id
  name    = "${var.environment}.clixx.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

output "fqdn" { value = aws_route53_record.wordpress.fqdn }
EOF

echo "✓ All modules created"

# ============================================================
# BOOTSTRAP SCRIPT - FIXED WITH MYSQL CLIENT
# ============================================================
cat > scripts/clixx_bootstrap.sh << 'EOFSCRIPT'
#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -xe

EFS_ID="${efs_id}"
REGION="${aws_region}"
SITE_URL="${site_url}"
MOUNT_POINT="/var/www/html"

echo "=== CLiXX Bootstrap Starting ==="
echo "EFS: $EFS_ID | Region: $REGION | Site: $SITE_URL"

# Install packages INCLUDING mysql client
dnf update -y
dnf install -y httpd php php-mysqli php-json php-gd php-mbstring php-xml \
    nfs-utils unzip wget cronie mariadb105

systemctl enable --now httpd
systemctl enable --now crond

# Mount EFS
mkdir -p $${MOUNT_POINT}
echo "$${EFS_ID}.efs.$${REGION}.amazonaws.com:/ $${MOUNT_POINT} nfs4 defaults,_netdev 0 0" >> /etc/fstab
mount -a
sleep 10

# Get DB credentials from SSM
DB_NAME=$(aws ssm get-parameter --name "/clixx/DB_NAME" --region $${REGION} --query "Parameter.Value" --output text)
DB_USER=$(aws ssm get-parameter --name "/clixx/DB_USER" --region $${REGION} --query "Parameter.Value" --output text)
DB_PASS=$(aws ssm get-parameter --with-decryption --name "/clixx/DB_PASS" --region $${REGION} --query "Parameter.Value" --output text)
DB_HOST=$(aws ssm get-parameter --name "/clixx/DB_HOST" --region $${REGION} --query "Parameter.Value" --output text)

echo "DB_NAME=$DB_NAME | DB_USER=$DB_USER | DB_HOST=$DB_HOST"

# Check if wp-config.php exists (from EFS)
if [ -f "$${MOUNT_POINT}/wp-config.php" ]; then
    echo "wp-config.php exists - updating DB settings"
    
    # Update existing wp-config.php with current DB settings
    sed -i "s/define( *'DB_NAME'.*/define( 'DB_NAME', '$${DB_NAME}' );/" "$${MOUNT_POINT}/wp-config.php"
    sed -i "s/define( *'DB_USER'.*/define( 'DB_USER', '$${DB_USER}' );/" "$${MOUNT_POINT}/wp-config.php"
    sed -i "s/define( *'DB_PASSWORD'.*/define( 'DB_PASSWORD', '$${DB_PASS}' );/" "$${MOUNT_POINT}/wp-config.php"
    sed -i "s/define( *'DB_HOST'.*/define( 'DB_HOST', '$${DB_HOST}' );/" "$${MOUNT_POINT}/wp-config.php"
else
    echo "No wp-config.php - installing WordPress"
    wget https://wordpress.org/latest.zip -O /tmp/wp.zip
    unzip -o /tmp/wp.zip -d /tmp/
    cp -R /tmp/wordpress/* $${MOUNT_POINT}/
    cp $${MOUNT_POINT}/wp-config-sample.php $${MOUNT_POINT}/wp-config.php
    
    sed -i "s/database_name_here/$${DB_NAME}/" "$${MOUNT_POINT}/wp-config.php"
    sed -i "s/username_here/$${DB_USER}/" "$${MOUNT_POINT}/wp-config.php"
    sed -i "s/password_here/$${DB_PASS}/" "$${MOUNT_POINT}/wp-config.php"
    sed -i "s/localhost/$${DB_HOST}/" "$${MOUNT_POINT}/wp-config.php"
    
    # Generate salts
    SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
    printf '%s\n' "g/put your unique phrase here/d" a "$SALT" . w | ed -s "$${MOUNT_POINT}/wp-config.php" 2>/dev/null || true
fi

# Create cron script for SSM sync
cat > $${MOUNT_POINT}/wp_config_check.sh << 'CRONEOF'
#!/bin/bash
REGION="REGION_PLACEHOLDER"
WP_CONFIG="/var/www/html/wp-config.php"
LOG="/var/log/wp_config_check.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TS] Syncing SSM to wp-config.php" >> $LOG

DB_NAME=$(aws ssm get-parameter --name "/clixx/DB_NAME" --region "$REGION" --query "Parameter.Value" --output text 2>/dev/null)
DB_USER=$(aws ssm get-parameter --name "/clixx/DB_USER" --region "$REGION" --query "Parameter.Value" --output text 2>/dev/null)
DB_PASS=$(aws ssm get-parameter --name "/clixx/DB_PASS" --region "$REGION" --with-decryption --query "Parameter.Value" --output text 2>/dev/null)
DB_HOST=$(aws ssm get-parameter --name "/clixx/DB_HOST" --region "$REGION" --query "Parameter.Value" --output text 2>/dev/null)

if [ -n "$DB_NAME" ] && [ -n "$DB_PASS" ]; then
    sed -i "s/define( *'DB_NAME'.*/define( 'DB_NAME', '$DB_NAME' );/" "$WP_CONFIG"
    sed -i "s/define( *'DB_USER'.*/define( 'DB_USER', '$DB_USER' );/" "$WP_CONFIG"
    sed -i "s/define( *'DB_PASSWORD'.*/define( 'DB_PASSWORD', '$DB_PASS' );/" "$WP_CONFIG"
    sed -i "s/define( *'DB_HOST'.*/define( 'DB_HOST', '$DB_HOST' );/" "$WP_CONFIG"
    echo "[$TS] Sync complete" >> $LOG
else
    echo "[$TS] ERROR: Failed to get SSM params" >> $LOG
fi
CRONEOF

sed -i "s/REGION_PLACEHOLDER/$${REGION}/" $${MOUNT_POINT}/wp_config_check.sh
chmod +x $${MOUNT_POINT}/wp_config_check.sh

# Setup cron
crontab -l > /tmp/mycron 2>/dev/null || true
grep -q "wp_config_check.sh" /tmp/mycron || echo "* * * * * /var/www/html/wp_config_check.sh" >> /tmp/mycron
crontab /tmp/mycron
rm -f /tmp/mycron

# Install WP-CLI
curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# Update site URL
sleep 30
cd $${MOUNT_POINT}
wp option update siteurl "http://$${SITE_URL}" --allow-root 2>/dev/null || true
wp option update home "http://$${SITE_URL}" --allow-root 2>/dev/null || true

# Permissions
chown -R apache:apache $${MOUNT_POINT}
chmod 755 $${MOUNT_POINT}

# SELinux
setsebool -P httpd_can_network_connect on 2>/dev/null || true
setsebool -P httpd_can_network_connect_db on 2>/dev/null || true
setsebool -P httpd_use_nfs on 2>/dev/null || true

systemctl restart httpd

echo "=== Bootstrap Complete! Site: http://$${SITE_URL} ==="
EOFSCRIPT

chmod +x scripts/clixx_bootstrap.sh
echo "✓ Bootstrap script created"

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              SETUP COMPLETE!                                  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. terraform destroy -auto-approve"
echo "  2. terraform init"
echo "  3. terraform apply -auto-approve"
echo ""
echo "Site will be at: http://dev.clixx.stack-simi.com"
echo ""
