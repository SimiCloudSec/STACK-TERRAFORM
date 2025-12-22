# =============================================================================
# BLOG WordPress Infrastructure - Flat Structure
# Author: Simi Talabi
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "blog-${var.environment}-vpc" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "blog-${var.environment}-igw" }
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags                    = { Name = "blog-${var.environment}-public-${count.index + 1}" }
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags              = { Name = "blog-${var.environment}-private-${count.index + 1}" }
}

resource "aws_eip" "nat" {
  domain     = "vpc"
  tags       = { Name = "blog-${var.environment}-nat-eip" }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "blog-${var.environment}-nat-gw" }
  depends_on    = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "blog-${var.environment}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = { Name = "blog-${var.environment}-private-rt" }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = "0.0.0.0/0"
  }
  ingress {
    rule_no    = 200
    action     = "allow"
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
  }
  ingress {
    rule_no    = 300
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }
  ingress {
    rule_no    = 400
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }
  ingress {
    rule_no    = 500
    action     = "allow"
    protocol   = "icmp"
    from_port  = 0
    to_port    = 0
    icmp_type  = -1
    icmp_code  = -1
    cidr_block = "0.0.0.0/0"
  }
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
  }
  egress {
    rule_no    = 200
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }
  egress {
    rule_no    = 300
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }
  egress {
    rule_no    = 400
    action     = "allow"
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = var.vpc_cidr
  }
  egress {
    rule_no    = 500
    action     = "allow"
    protocol   = "icmp"
    from_port  = 0
    to_port    = 0
    icmp_type  = -1
    icmp_code  = -1
    cidr_block = "0.0.0.0/0"
  }
  tags = { Name = "blog-${var.environment}-public-nacl" }
}

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = var.vpc_cidr
  }
  ingress {
    rule_no    = 200
    action     = "allow"
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = var.vpc_cidr
  }
  ingress {
    rule_no    = 300
    action     = "allow"
    protocol   = "tcp"
    from_port  = 3306
    to_port    = 3306
    cidr_block = var.vpc_cidr
  }
  ingress {
    rule_no    = 400
    action     = "allow"
    protocol   = "tcp"
    from_port  = 2049
    to_port    = 2049
    cidr_block = var.vpc_cidr
  }
  ingress {
    rule_no    = 500
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }
  ingress {
    rule_no    = 600
    action     = "allow"
    protocol   = "icmp"
    from_port  = 0
    to_port    = 0
    icmp_type  = -1
    icmp_code  = -1
    cidr_block = var.vpc_cidr
  }
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
  }
  egress {
    rule_no    = 200
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }
  egress {
    rule_no    = 300
    action     = "allow"
    protocol   = "tcp"
    from_port  = 3306
    to_port    = 3306
    cidr_block = var.vpc_cidr
  }
  egress {
    rule_no    = 400
    action     = "allow"
    protocol   = "tcp"
    from_port  = 2049
    to_port    = 2049
    cidr_block = var.vpc_cidr
  }
  egress {
    rule_no    = 500
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }
  egress {
    rule_no    = 600
    action     = "allow"
    protocol   = "icmp"
    from_port  = 0
    to_port    = 0
    icmp_type  = -1
    icmp_code  = -1
    cidr_block = var.vpc_cidr
  }
  tags = { Name = "blog-${var.environment}-private-nacl" }
}

resource "aws_security_group" "alb" {
  name        = "blog-${var.environment}-alb-sg"
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
  tags = { Name = "blog-${var.environment}-alb-sg" }
}

resource "aws_security_group" "ec2" {
  name        = "blog-${var.environment}-ec2-sg"
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
  tags = { Name = "blog-${var.environment}-ec2-sg" }
}

resource "aws_security_group" "rds" {
  name        = "blog-${var.environment}-rds-sg"
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
  tags = { Name = "blog-${var.environment}-rds-sg" }
}

resource "aws_security_group" "efs" {
  name        = "blog-${var.environment}-efs-sg"
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
  tags = { Name = "blog-${var.environment}-efs-sg" }
}

resource "aws_iam_role" "ec2" {
  name = "blog-${var.environment}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "blog-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "efs_access" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadWriteAccess"
}

resource "aws_efs_file_system" "wordpress" {
  creation_token   = "blog-${var.environment}-efs"
  encrypted        = var.efs_config.encrypted
  throughput_mode  = var.efs_config.throughput_mode
  performance_mode = var.efs_config.performance_mode
  tags = { Name = "blog-${var.environment}-efs" }
}

resource "aws_efs_mount_target" "wordpress" {
  count           = length(var.private_subnet_cidrs)
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_db_subnet_group" "wordpress" {
  name       = "blog-${var.environment}-db-subnet"
  subnet_ids = aws_subnet.private[*].id
  tags = { Name = "blog-${var.environment}-db-subnet" }
}

resource "aws_db_instance" "wordpress" {
  identifier             = var.rds_config.identifier
  instance_class         = var.rds_config.instance_class
  snapshot_identifier    = var.rds_config.snapshot_arn
  db_subnet_group_name   = aws_db_subnet_group.wordpress.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = var.rds_config.multi_az
  publicly_accessible    = var.rds_config.publicly_accessible
  skip_final_snapshot    = var.rds_config.skip_final_snapshot
  tags = { Name = "blog-${var.environment}-db" }
}

resource "tls_private_key" "blog" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "blog" {
  key_name   = var.ec2_config.key_name
  public_key = tls_private_key.blog.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.blog.private_key_pem
  filename        = "${path.module}/${var.ec2_config.key_name}.pem"
  file_permission = "0600"
}

resource "aws_lb" "wordpress" {
  name               = "blog-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  tags = { Name = "blog-${var.environment}-alb" }
}

resource "aws_lb_target_group" "wordpress" {
  name     = "blog-${var.environment}-tg"
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
  tags = { Name = "blog-${var.environment}-tg" }
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

resource "aws_launch_template" "wordpress" {
  name_prefix            = "blog-${var.environment}-"
  image_id               = data.aws_ami.golden_ami.id
  instance_type          = var.ec2_config.instance_type
  key_name               = aws_key_pair.blog.key_name
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile { name = aws_iam_instance_profile.ec2.name }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.ec2_config.volume_size
      volume_type = var.ec2_config.volume_type
      encrypted   = true
    }
  }
  user_data = base64encode(templatefile("${path.module}/scripts/blog_bootstrap.sh", {
    efs_id   = aws_efs_file_system.wordpress.id
    db_host  = split(":", aws_db_instance.wordpress.endpoint)[0]
    db_user  = var.rds_config.db_username
    db_pass  = var.rds_config.db_password
    site_url = "${var.environment}.blog.${var.domain_name}"
  }))
  tag_specifications {
    resource_type = "instance"
    tags = { Name = "blog-${var.environment}-instance" }
  }
  monitoring { enabled = var.ec2_config.enable_monitoring }
}

resource "aws_autoscaling_group" "wordpress" {
  name                      = "blog-${var.environment}-asg"
  desired_capacity          = var.asg_config.desired_capacity
  max_size                  = var.asg_config.max_size
  min_size                  = var.asg_config.min_size
  vpc_zone_identifier       = aws_subnet.private[*].id
  target_group_arns         = [aws_lb_target_group.wordpress.arn]
  health_check_type         = "ELB"
  health_check_grace_period = var.asg_config.health_check_grace_period
  launch_template {
    id      = aws_launch_template.wordpress.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "blog-${var.environment}-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_route53_record" "wordpress" {
  zone_id = var.hosted_zone_id
  name    = "${var.environment}.blog.${var.domain_name}"
  type    = "A"
  alias {
    name                   = aws_lb.wordpress.dns_name
    zone_id                = aws_lb.wordpress.zone_id
    evaluate_target_health = true
  }
}
