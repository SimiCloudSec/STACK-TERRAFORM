# =============================================================================
# MAIN.TF - CliXX WordPress Infrastructure
# Author: Simi Talabi
# =============================================================================

# =============================================================================
# SECURITY GROUPS
# =============================================================================

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "clixx-${var.environment}-alb-sg"
  description = "ALB Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
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

  tags = { Name = "clixx-${var.environment}-alb-sg" }
}

# EC2 Security Group
resource "aws_security_group" "ec2" {
  name        = "clixx-${var.environment}-ec2-sg"
  description = "EC2 Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  ingress {
    description = "SSH access"
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

  tags = { Name = "clixx-${var.environment}-ec2-sg" }
}

# RDS Security Group
resource "aws_security_group" "rds" {
  name        = "clixx-${var.environment}-rds-sg"
  description = "RDS Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "clixx-${var.environment}-rds-sg" }
}

# EFS Security Group
resource "aws_security_group" "efs" {
  name        = "clixx-${var.environment}-efs-sg"
  description = "EFS Security Group"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "NFS from EC2"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "clixx-${var.environment}-efs-sg" }
}

# =============================================================================
# IAM ROLE & INSTANCE PROFILE
# =============================================================================

# IAM Role for EC2
resource "aws_iam_role" "ec2" {
  name = "clixx-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for SSM Parameter Store Access
resource "aws_iam_role_policy" "ssm" {
  name = "clixx-${var.environment}-ssm-policy"
  role = aws_iam_role.ec2.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:*:parameter/clixx/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = "*"
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2" {
  name = "clixx-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# =============================================================================
# SSM PARAMETER STORE
# =============================================================================

resource "aws_ssm_parameter" "db_name" {
  name      = "/clixx/DB_NAME"
  type      = "String"
  value     = var.db_name
  overwrite = true
  tags      = { Environment = var.environment }
}

resource "aws_ssm_parameter" "db_user" {
  name      = "/clixx/DB_USER"
  type      = "String"
  value     = var.db_username
  overwrite = true
  tags      = { Environment = var.environment }
}

resource "aws_ssm_parameter" "db_pass" {
  name      = "/clixx/DB_PASS"
  type      = "SecureString"
  value     = var.db_password
  overwrite = true
  tags      = { Environment = var.environment }
}

resource "aws_ssm_parameter" "db_host" {
  name      = "/clixx/DB_HOST"
  type      = "String"
  value     = split(":", aws_db_instance.wordpress.endpoint)[0]
  overwrite = true

  tags = { Name = "clixx-${var.environment}-efs" }
}

resource "aws_efs_mount_target" "wordpress" {
  count           = 2
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = aws_subnet.private_webapp[count.index].id
  security_groups = [aws_security_group.efs.id]
}

# =============================================================================
# RDS DATABASE
# =============================================================================

resource "aws_db_subnet_group" "wordpress" {
  name       = "clixx-${var.environment}-db-subnet"
  subnet_ids = aws_subnet.private_webapp[*].id

  tags = { Name = "clixx-${var.environment}-db-subnet" }
}

resource "aws_db_instance" "wordpress" {
  identifier          = "clixx-${var.environment}-db"
  instance_class      = var.rds_config["instance_class"]
  snapshot_identifier = var.snapshot_identifier
  
  db_subnet_group_name   = aws_db_subnet_group.wordpress.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  multi_az            = false
  publicly_accessible = false
  skip_final_snapshot = true

  tags = { Name = "clixx-${var.environment}-db" }
}

# =============================================================================
# APPLICATION LOAD BALANCER
# =============================================================================

resource "aws_lb" "wordpress" {
  name               = "clixx-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = { Name = "clixx-${var.environment}-alb" }
}

resource "aws_lb_target_group" "wordpress" {
  name     = "clixx-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

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

resource "aws_lb_listener" "wordpress" {
  load_balancer_arn = aws_lb.wordpress.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wordpress.arn
  }
}

# =============================================================================
# LAUNCH TEMPLATE & AUTO SCALING GROUP
# =============================================================================

resource "aws_launch_template" "wordpress" {
  name_prefix   = "clixx-${var.environment}-"
  image_id      = data.aws_ami.golden_ami.id
  instance_type = var.ec2_config["instance_type"]

  vpc_security_group_ids = [aws_security_group.ec2.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  user_data = base64encode(templatefile("${path.module}/scripts/clixx_bootstrap.sh", {
    efs_id     = aws_efs_file_system.wordpress.id
    aws_region = var.aws_region
    site_url   = "${var.environment}.clixx.${var.domain_name}"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = { Name = "clixx-${var.environment}-instance" }
  }
}

resource "aws_autoscaling_group" "wordpress" {
  name                = "clixx-${var.environment}-asg"
  desired_capacity    = var.asg_config["desired_capacity"]
  max_size            = var.asg_config["max_size"]
  min_size            = var.asg_config["min_size"]
  vpc_zone_identifier = aws_subnet.private_webapp[*].id
  target_group_arns   = [aws_lb_target_group.wordpress.arn]

  health_check_type         = "ELB"
  health_check_grace_period = var.asg_config["health_check_grace_period"]

  launch_template {
    id      = aws_launch_template.wordpress.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "clixx-${var.environment}-asg-instance"
    propagate_at_launch = true
  }
}

# =============================================================================
# ROUTE53 DNS RECORD
# =============================================================================

resource "aws_route53_record" "wordpress" {
  provider = aws.route53
  
  zone_id = var.hosted_zone_id
  name    = "${var.environment}.clixx.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.wordpress.dns_name
    zone_id                = aws_lb.wordpress.zone_id
    evaluate_target_health = true
  }
}
