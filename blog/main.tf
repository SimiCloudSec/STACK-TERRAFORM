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
  site_url      = "${var.environment}.blog.${var.domain_name}"
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
  environment    = var.environment
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
