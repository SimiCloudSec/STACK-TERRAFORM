#!/bin/bash
###############################################################################
# BLOG WordPress Terraform - Complete Project Setup Script
# Author: Simi Talabi
# 
# Creates entire Terraform infrastructure for Blog WordPress deployment
###############################################################################

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   BLOG WordPress on AWS - Complete Project Setup             ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Create directory structure
echo "Creating directory structure..."
mkdir -p modules/{alb,asg,efs,keypair,lt,rds,route53,sg,tg}
mkdir -p scripts
echo "✓ Directories created"
echo ""

###############################################################################
# ROOT FILES
###############################################################################

echo "Creating root configuration files..."

# main.tf
cat > main.tf << 'EOF'
# ============================================================
# MAIN TERRAFORM CONFIGURATION - BLOG WordPress Infrastructure
# Author: Simi Talabi
# ============================================================

# Security Groups
module "sg" {
  source = "./modules/sg"
  vpc_id = data.aws_vpc.default.id
}

# EFS File System
module "efs" {
  source     = "./modules/efs"
  subnet_ids = data.aws_subnets.default.ids
  efs_sg_id  = module.sg.efs_sg_id
}

# RDS Database (restored from snapshot)
module "rds" {
  source            = "./modules/rds"
  db_snapshot_id    = var.db_snapshot_id
  db_instance_class = var.db_instance_class
  subnet_ids        = data.aws_subnets.default.ids
  rds_sg_id         = module.sg.rds_sg_id
}

# Key Pair
module "keypair" {
  source   = "./modules/keypair"
  key_name = var.key_name
}

# Application Load Balancer
module "alb" {
  source     = "./modules/alb"
  subnet_ids = data.aws_subnets.default.ids
  alb_sg_id  = module.sg.alb_sg_id
}

# Target Group
module "tg" {
  source = "./modules/tg"
  vpc_id = data.aws_vpc.default.id
}

# Launch Template
module "lt" {
  source        = "./modules/lt"
  ami_id        = data.aws_ami.amazon_linux_2023_arm.id
  instance_type = var.instance_type
  ec2_sg_id     = module.sg.ec2_sg_id
  efs_id        = module.efs.efs_id
  key_name      = module.keypair.key_name
  db_host       = module.rds.db_endpoint
  db_name       = var.db_name
  db_user       = var.db_username
  db_pass       = var.db_password
}

# Auto Scaling Group
module "asg" {
  source             = "./modules/asg"
  subnet_ids         = data.aws_subnets.default.ids
  target_group_arn   = module.tg.tg_arn
  launch_template_id = module.lt.lt_id
  min_size           = var.asg_min_size
  max_size           = var.asg_max_size
  desired_capacity   = var.asg_desired_capacity
}

# Route53 DNS
module "route53" {
  source         = "./modules/route53"
  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id
  subdomain      = var.subdomain
  alb_dns_name   = module.alb.alb_dns
  alb_zone_id    = module.alb.alb_zone_id
}

# ALB HTTP Listener
resource "aws_lb_listener" "blog_http" {
  load_balancer_arn = module.alb.alb_arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = module.tg.tg_arn
  }
}
EOF

# variables.tf
cat > variables.tf << 'EOF'
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

variable "subdomain" {
  description = "Subdomain for blog"
  type        = string
  default     = "blog"
}
EOF

# outputs.tf
cat > outputs.tf << 'EOF'
# ============================================================
# OUTPUTS - BLOG WordPress Infrastructure
# ============================================================

output "blog_url" {
  description = "Blog URL"
  value       = "http://${module.route53.fqdn}"
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
}

output "efs_id" {
  description = "EFS file system ID"
  value       = module.efs.efs_id
}

output "key_pair_name" {
  description = "EC2 Key Pair name"
  value       = module.keypair.key_name
}

output "private_key_file" {
  description = "Private key file location"
  value       = module.keypair.private_key_path
}
EOF

# providers.tf
cat > providers.tf << 'EOF'
# ============================================================
# PROVIDERS - BLOG WordPress Infrastructure
# ============================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
EOF

# datasources.tf
cat > datasources.tf << 'EOF'
# ============================================================
# DATA SOURCES - BLOG WordPress Infrastructure
# ============================================================

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Amazon Linux 2023 ARM AMI
data "aws_ami" "amazon_linux_2023_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}
EOF

# terraform.tfvars - WITH YOUR VALUES
cat > terraform.tfvars << 'EOF'
# ============================================================
# TERRAFORM VARIABLES - BLOG WordPress Infrastructure
# ============================================================

aws_region = "us-east-1"

# Database (Restore from Snapshot)
db_snapshot_id    = "wordpressinstance2"
db_instance_class = "db.t4g.micro"
db_name           = "wordpressdb"
db_username       = "admin"
db_password       = "Yourpassword123"

# EC2
instance_type = "t4g.micro"
key_name      = "blog-wordpress-key"

# Auto Scaling
asg_min_size         = 1
asg_max_size         = 3
asg_desired_capacity = 2

# Route53
domain_name    = "stack-simi.com"
hosted_zone_id = "Z069777410G7QJT8P199L"
subdomain      = "blog"
EOF

echo "✓ Root configuration files created"

###############################################################################
# MODULE: Security Groups
###############################################################################

echo "Creating Security Groups module..."

cat > modules/sg/main.tf << 'EOF'
# ============================================================
# SECURITY GROUPS MODULE - BLOG WordPress
# ============================================================

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "blog-alb-sg"
  description = "Security group for Blog ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blog-alb-sg"
  }
}

# EC2 Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "blog-ec2-sg"
  description = "Security group for Blog EC2"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blog-ec2-sg"
  }
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "blog-rds-sg"
  description = "Security group for Blog RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blog-rds-sg"
  }
}

# EFS Security Group
resource "aws_security_group" "efs_sg" {
  name        = "blog-efs-sg"
  description = "Security group for Blog EFS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from EC2"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "blog-efs-sg"
  }
}

output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "ec2_sg_id" {
  value = aws_security_group.ec2_sg.id
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "efs_sg_id" {
  value = aws_security_group.efs_sg.id
}
EOF

echo "✓ Security Groups module created"

###############################################################################
# MODULE: EFS
###############################################################################

echo "Creating EFS module..."

cat > modules/efs/main.tf << 'EOF'
# ============================================================
# EFS MODULE - BLOG WordPress
# ============================================================

variable "subnet_ids" {
  description = "Subnet IDs for EFS mount targets"
  type        = list(string)
}

variable "efs_sg_id" {
  description = "EFS Security Group ID"
  type        = string
}

resource "aws_efs_file_system" "blog_efs" {
  creation_token = "blog-wordpress-efs"
  encrypted      = true

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "blog-wordpress-efs"
  }
}

resource "aws_efs_mount_target" "blog_efs_mt" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.blog_efs.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [var.efs_sg_id]
}

output "efs_id" {
  value = aws_efs_file_system.blog_efs.id
}

output "efs_dns_name" {
  value = aws_efs_file_system.blog_efs.dns_name
}
EOF

echo "✓ EFS module created"

###############################################################################
# MODULE: RDS (Restore from Snapshot)
###############################################################################

echo "Creating RDS module..."

cat > modules/rds/main.tf << 'EOF'
# ============================================================
# RDS MODULE - BLOG WordPress (Restore from Snapshot)
# ============================================================

variable "db_snapshot_id" {
  description = "Snapshot ID to restore from"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "RDS Security Group ID"
  type        = string
}

resource "aws_db_subnet_group" "blog_db_subnet" {
  name       = "blog-wordpress-db-subnet"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "blog-wordpress-db-subnet"
  }
}

resource "aws_db_instance" "blog_db" {
  identifier             = "blog-wordpress-db"
  snapshot_identifier    = var.db_snapshot_id
  instance_class         = var.db_instance_class
  db_subnet_group_name   = aws_db_subnet_group.blog_db_subnet.name
  vpc_security_group_ids = [var.rds_sg_id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false

  tags = {
    Name = "blog-wordpress-db"
  }
}

output "db_endpoint" {
  value = aws_db_instance.blog_db.address
}

output "db_arn" {
  value = aws_db_instance.blog_db.arn
}
EOF

echo "✓ RDS module created"

###############################################################################
# MODULE: Key Pair
###############################################################################

echo "Creating Key Pair module..."

cat > modules/keypair/main.tf << 'EOF'
# ============================================================
# KEY PAIR MODULE - BLOG WordPress
# ============================================================

variable "key_name" {
  description = "Name of the key pair"
  type        = string
}

resource "tls_private_key" "blog_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "blog_key" {
  key_name   = var.key_name
  public_key = tls_private_key.blog_key.public_key_openssh

  tags = {
    Name = var.key_name
  }
}

resource "local_file" "private_key" {
  content         = tls_private_key.blog_key.private_key_pem
  filename        = "${path.root}/${var.key_name}.pem"
  file_permission = "0400"
}

output "key_name" {
  value = aws_key_pair.blog_key.key_name
}

output "private_key_path" {
  value = local_file.private_key.filename
}
EOF

echo "✓ Key Pair module created"

###############################################################################
# MODULE: ALB
###############################################################################

echo "Creating ALB module..."

cat > modules/alb/main.tf << 'EOF'
# ============================================================
# ALB MODULE - BLOG WordPress
# ============================================================

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "alb_sg_id" {
  description = "ALB Security Group ID"
  type        = string
}

resource "aws_lb" "blog_alb" {
  name               = "blog-wordpress-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.subnet_ids

  tags = {
    Name = "blog-wordpress-alb"
  }
}

output "alb_arn" {
  value = aws_lb.blog_alb.arn
}

output "alb_dns" {
  value = aws_lb.blog_alb.dns_name
}

output "alb_zone_id" {
  value = aws_lb.blog_alb.zone_id
}
EOF

echo "✓ ALB module created"

###############################################################################
# MODULE: Target Group
###############################################################################

echo "Creating Target Group module..."

cat > modules/tg/main.tf << 'EOF'
# ============================================================
# TARGET GROUP MODULE - BLOG WordPress
# ============================================================

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

resource "aws_lb_target_group" "blog_tg" {
  name     = "blog-wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health.html"
    matcher             = "200"
  }

  tags = {
    Name = "blog-wordpress-tg"
  }
}

output "tg_arn" {
  value = aws_lb_target_group.blog_tg.arn
}
EOF

echo "✓ Target Group module created"

###############################################################################
# MODULE: Launch Template
###############################################################################

echo "Creating Launch Template module..."

cat > modules/lt/main.tf << 'EOF'
# ============================================================
# LAUNCH TEMPLATE MODULE - BLOG WordPress
# ============================================================

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "ec2_sg_id" {
  description = "EC2 Security Group ID"
  type        = string
}

variable "efs_id" {
  description = "EFS ID"
  type        = string
}

variable "key_name" {
  description = "Key pair name"
  type        = string
}

variable "db_host" {
  description = "Database host"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_user" {
  description = "Database username"
  type        = string
}

variable "db_pass" {
  description = "Database password"
  type        = string
  sensitive   = true
}

resource "aws_launch_template" "blog_lt" {
  name_prefix   = "blog-wordpress-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [var.ec2_sg_id]

  user_data = base64encode(templatefile("${path.root}/scripts/blog_bootstrap.sh", {
    efs_id  = var.efs_id
    db_host = var.db_host
    db_name = var.db_name
    db_user = var.db_user
    db_pass = var.db_pass
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "blog-wordpress-instance"
    }
  }
}

output "lt_id" {
  value = aws_launch_template.blog_lt.id
}
EOF

echo "✓ Launch Template module created"

###############################################################################
# MODULE: Auto Scaling Group
###############################################################################

echo "Creating Auto Scaling Group module..."

cat > modules/asg/main.tf << 'EOF'
# ============================================================
# AUTO SCALING GROUP MODULE - BLOG WordPress
# ============================================================

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "target_group_arn" {
  description = "Target group ARN"
  type        = string
}

variable "launch_template_id" {
  description = "Launch template ID"
  type        = string
}

variable "min_size" {
  description = "Minimum size"
  type        = number
}

variable "max_size" {
  description = "Maximum size"
  type        = number
}

variable "desired_capacity" {
  description = "Desired capacity"
  type        = number
}

resource "aws_autoscaling_group" "blog_asg" {
  name                      = "blog-wordpress-asg"
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = [var.target_group_arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity

  launch_template {
    id      = var.launch_template_id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "blog-wordpress-asg-instance"
    propagate_at_launch = true
  }
}

output "asg_name" {
  value = aws_autoscaling_group.blog_asg.name
}
EOF

echo "✓ Auto Scaling Group module created"

###############################################################################
# MODULE: Route53
###############################################################################

echo "Creating Route53 module..."

cat > modules/route53/main.tf << 'EOF'
# ============================================================
# ROUTE53 MODULE - BLOG WordPress
# ============================================================

variable "domain_name" {
  description = "Base domain name"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID"
  type        = string
}

variable "subdomain" {
  description = "Subdomain for blog"
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB Zone ID"
  type        = string
}

resource "aws_route53_record" "blog" {
  zone_id = var.hosted_zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

output "fqdn" {
  value = aws_route53_record.blog.fqdn
}
EOF

echo "✓ Route53 module created"

###############################################################################
# BOOTSTRAP SCRIPT
###############################################################################

echo "Creating bootstrap script..."

cat > scripts/blog_bootstrap.sh << 'EOFBOOTSTRAP'
#!/bin/bash
# ------------------------------------------------------------
# BLOG WordPress Bootstrap Script (Amazon Linux 2023 - ARM)
# Author: Simi Talabi
# ------------------------------------------------------------
set -xe
exec > /var/log/user-data.log 2>&1

# ------------------------------------------------------------
# 1. System Update + Package Installation
# ------------------------------------------------------------
dnf update -y
dnf install -y nfs-utils httpd php php-mysqlnd mariadb105-server git

# ------------------------------------------------------------
# 2. Define Variables
# ------------------------------------------------------------
EFS_ID="${efs_id}"
DB_HOST="${db_host}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASS="${db_pass}"
MOUNT_POINT="/var/www/html"

# Retrieve Region dynamically via IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 3600")
AVAILABILITY_ZONE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION=$(echo $AVAILABILITY_ZONE | sed 's/[a-z]$//')

# ------------------------------------------------------------
# 3. Prepare & Mount EFS
# ------------------------------------------------------------
mkdir -p $${MOUNT_POINT}
chown ec2-user:ec2-user $${MOUNT_POINT}

if ! grep -q "$${EFS_ID}" /etc/fstab; then
  echo "$${EFS_ID}.efs.$${REGION}.amazonaws.com:/ $${MOUNT_POINT} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0" >> /etc/fstab
fi

sleep 20
mount -a -t nfs4

# ------------------------------------------------------------
# 4. Deploy WordPress (from GitHub repo)
# ------------------------------------------------------------
if [ -z "$(ls -A $${MOUNT_POINT} 2>/dev/null)" ]; then
  echo "Cloning WordPress blog from GitHub..."
  git clone https://github.com/SimiCloudSec/Simi-Blog.git $${MOUNT_POINT}
  chown -R apache:apache $${MOUNT_POINT}
  chmod -R 755 $${MOUNT_POINT}
else
  echo "EFS already contains files — skipping clone."
fi

# ------------------------------------------------------------
# 5. Update wp-config.php with database settings
# ------------------------------------------------------------
WP_CONFIG="$${MOUNT_POINT}/wp-config.php"

if [ -f "$${WP_CONFIG}" ]; then
  sed -i "s/database_name_here/$${DB_NAME}/" $${WP_CONFIG}
  sed -i "s/username_here/$${DB_USER}/" $${WP_CONFIG}
  sed -i "s/password_here/$${DB_PASS}/" $${WP_CONFIG}
  sed -i "s/localhost/$${DB_HOST}/" $${WP_CONFIG}
fi

# ------------------------------------------------------------
# 6. Set Correct Permissions
# ------------------------------------------------------------
chown -R apache:apache $${MOUNT_POINT}
chmod -R 755 $${MOUNT_POINT}

# ------------------------------------------------------------
# 7. Start & Enable Services
# ------------------------------------------------------------
systemctl enable httpd
systemctl start httpd

# ------------------------------------------------------------
# 8. Health Check File for Load Balancer
# ------------------------------------------------------------
if [ ! -f $${MOUNT_POINT}/health.html ]; then
  echo "<h1>Health OK - $(hostname)</h1>" > $${MOUNT_POINT}/health.html
fi

# ------------------------------------------------------------
# 9. Ensure WordPress Loads First
# ------------------------------------------------------------
if [ -f $${MOUNT_POINT}/index.html ]; then
  rm -f $${MOUNT_POINT}/index.html
fi

# ------------------------------------------------------------
# 10. Final Verification Log
# ------------------------------------------------------------
echo "Blog WordPress bootstrap completed successfully on $(hostname)" >> /var/log/user-data-status.log
EOFBOOTSTRAP

chmod +x scripts/blog_bootstrap.sh

echo "✓ Bootstrap script created"

###############################################################################
# COMPLETE
###############################################################################

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              BLOG PROJECT SETUP COMPLETE!                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Files created:"
echo "  ✓ main.tf, variables.tf, outputs.tf, providers.tf, datasources.tf"
echo "  ✓ terraform.tfvars (with your values)"
echo "  ✓ modules/sg, efs, rds, keypair, alb, tg, lt, asg, route53"
echo "  ✓ scripts/blog_bootstrap.sh"
echo ""
echo "NEXT STEPS:"
echo "  terraform init"
echo "  terraform plan"
echo "  terraform apply"
echo ""
echo "Your blog will be available at: http://blog.stack-simi.com"
echo ""
