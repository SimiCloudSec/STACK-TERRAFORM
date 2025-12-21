# =============================================================================
# BLOG WordPress - Using Custom VPC
# =============================================================================

module "sg" {
  source        = "./modules/sg"
  vpc_id        = aws_vpc.main.id
  environment   = var.environment
  sg_alb_config = var.sg_alb_config
  sg_ec2_config = var.sg_ec2_config
  sg_rds_config = var.sg_rds_config
  sg_efs_config = var.sg_efs_config
}

module "efs" {
  source      = "./modules/efs"
  environment = var.environment
  subnet_ids  = local.private_subnet_ids
  efs_sg_id   = module.sg.efs_sg_id
  efs_config  = var.efs_config
}

module "rds" {
  source      = "./modules/rds"
  environment = var.environment
  subnet_ids  = local.private_subnet_ids
  rds_sg_id   = module.sg.rds_sg_id
  rds_config  = var.rds_config
}

module "keypair" {
  source      = "./modules/keypair"
  environment = var.environment
  key_name    = var.ec2_config.key_name
}

module "alb" {
  source      = "./modules/alb"
  environment = var.environment
  subnet_ids  = local.public_subnet_ids
  alb_sg_id   = module.sg.alb_sg_id
}

module "tg" {
  source      = "./modules/tg"
  environment = var.environment
  vpc_id      = aws_vpc.main.id
}

module "lt" {
  source      = "./modules/lt"
  environment = var.environment
  ami_id      = data.aws_ami.golden_ami.id
  ec2_config  = var.ec2_config
  ec2_sg_id   = module.sg.ec2_sg_id
  key_name    = module.keypair.key_name
  efs_id      = module.efs.efs_id
  db_host     = module.rds.db_endpoint
  db_name     = var.rds_config.db_name
  db_user     = var.rds_config.db_username
  db_pass     = var.rds_config.db_password
  site_url    = "${var.environment}.blog.${var.domain_name}"
}

module "asg" {
  source             = "./modules/asg"
  environment        = var.environment
  subnet_ids         = local.private_subnet_ids
  target_group_arn   = module.tg.tg_arn
  launch_template_id = module.lt.lt_id
  asg_config         = var.asg_config
}

module "route53" {
  source         = "./modules/route53"
  environment    = var.environment
  domain_name    = var.domain_name
  hosted_zone_id = var.hosted_zone_id
  alb_dns_name   = module.alb.alb_dns
  alb_zone_id    = module.alb.alb_zone_id
}

resource "aws_lb_listener" "blog_http" {
  load_balancer_arn = module.alb.alb_arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = module.tg.tg_arn
  }
}
