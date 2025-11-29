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
