# ============================================================
# main.tf - Docker ECS Infrastructure as Code
# ============================================================
# This Terraform file automates the SAME Docker ECS deployment
# we did manually step-by-step in the AWS Console.
#
# What it creates:
#   1. ECR Repository (to store Docker images)
#   2. IAM Roles (permissions for ECS)
#   3. Security Group (ports 22, 80, 8000)
#   4. ECS Cluster + EC2 instances
#   5. Task Definition (container config)
#   6. Network Load Balancer + Target Group
#   7. ECS Service (keeps 2 tasks running)
#   8. CloudWatch Log Group
#   9. Route 53 DNS Record (ecs.stack-simi.com → NLB)
#
# Prerequisites:
#   - VPC and Subnets already exist
#   - Docker image already pushed to ECR
#   - RDS database already running
#   - Key pair already created
# ============================================================


# ---------------------------
# DATA SOURCES
# ---------------------------
# Get your AWS account ID automatically
data "aws_caller_identity" "current" {}

# Get the latest ECS-optimized AMI (Amazon Linux 2 for ECS)
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# Get Amazon Linux 2023 AMI for the Docker build instance
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}


# ============================================================
# 1. ECR REPOSITORY
# ============================================================
# This is where your Docker image lives (like Docker Hub but AWS)
# Manual step: aws ecr create-repository --repository-name clixx-repository

resource "aws_ecr_repository" "clixx" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name = "clixx-ecr-repo"
  }
}


# ============================================================
# 1b. DOCKER BUILD INSTANCE
# ============================================================
# This EC2 instance automatically:
#   - Installs Docker and Git
#   - Clones the CliXX repo from GitHub
#   - Creates the Dockerfile
#   - Builds the Docker image
#   - Pushes it to ECR
# After push is done, ECS can pull the image and run containers.

resource "aws_instance" "docker_build" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro"
  key_name               = var.key_pair_name
  subnet_id              = var.public_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.ecs_instances.id]
  iam_instance_profile   = aws_iam_instance_profile.ecs_instance_profile.name

  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -xe

    echo "=== Installing Docker and Git ==="
    dnf update -y
    dnf install -y docker git
    systemctl enable --now docker

    echo "=== Cloning CliXX Repository ==="
    cd /home/ec2-user
    git clone https://github.com/stackitgit/CliXX_Retail_Repository.git clixx-app
    cd clixx-app

    echo "=== Updating wp-config.php with correct DB credentials ==="
    WP_CONFIG="wp-config.php"
    if [ -f "$WP_CONFIG" ]; then
      sed -i "s|define( *'DB_NAME', *'[^']*' *);|define( 'DB_NAME', '${var.db_name}' );|g" "$WP_CONFIG"
      sed -i "s|define( *'DB_USER', *'[^']*' *);|define( 'DB_USER', '${var.db_user}' );|g" "$WP_CONFIG"
      sed -i "s|define( *'DB_PASSWORD', *'[^']*' *);|define( 'DB_PASSWORD', '${var.db_password}' );|g" "$WP_CONFIG"
      sed -i "s|define( *'DB_HOST', *'[^']*' *);|define( 'DB_HOST', '${var.db_host}' );|g" "$WP_CONFIG"
      echo "wp-config.php updated with correct DB credentials"
    fi

    echo "=== Creating Dockerfile ==="
    cat > Dockerfile << 'DOCKERFILE'
    FROM wordpress:php8.0-apache
    COPY . /var/www/html/
    RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html
    EXPOSE 80
    DOCKERFILE

    echo "=== Logging into ECR ==="
    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com

    echo "=== Building Docker Image ==="
    docker build -t clixx-image .

    echo "=== Tagging Image ==="
    docker tag clixx-image:latest ${aws_ecr_repository.clixx.repository_url}:${var.docker_image_tag}

    echo "=== Pushing to ECR ==="
    docker push ${aws_ecr_repository.clixx.repository_url}:${var.docker_image_tag}

    echo "=== DONE! Image pushed to ECR ==="

    chown -R ec2-user:ec2-user /home/ec2-user/clixx-app
  EOF

  tags = {
    Name = "clixx-docker-build"
  }

  # Make sure ECR repo exists before this instance tries to push to it
  depends_on = [aws_ecr_repository.clixx]
}


# ============================================================
# 2. IAM ROLES FOR ECS
# ============================================================
# ECS needs permissions to pull images, write logs, etc.

# --- Role for EC2 instances to join the ECS cluster ---
resource "aws_iam_role" "ecs_instance_role" {
  name = "clixx-ecs-instance-role"

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

  tags = {
    Name = "clixx-ecs-instance-role"
  }
}

# Attach the AWS-managed ECS policy to the instance role
resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Allow EC2 instances to push/pull images from ECR
resource "aws_iam_role_policy_attachment" "ecr_power_user" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Instance profile (wrapper that lets EC2 use the role)
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "clixx-ecs-instance-profile"
  role = aws_iam_role.ecs_instance_role.name
}

# --- Role for ECS tasks (container-level permissions) ---
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "clixx-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "clixx-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# ============================================================
# 3. SECURITY GROUP
# ============================================================
# Same ports we opened manually: 22, 80, 8000

resource "aws_security_group" "ecs_instances" {
  name        = "clixx-ecs-instance-sg"
  description = "Security group for ECS container instances"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Container port (host port mapping)
  ingress {
    description = "Container Host Port"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "clixx-ecs-instance-sg"
  }
}


# ============================================================
# 4. ECS CLUSTER + EC2 INSTANCES
# ============================================================
# Manual step: ECS Console → Create Cluster → EC2 instances
# In Terraform we need: Cluster + Launch Template + Auto Scaling Group

resource "aws_ecs_cluster" "clixx" {
  name = "Clixx-ECS-Cluster"

  tags = {
    Name = "Clixx-ECS-Cluster"
  }
}

# Launch Template tells AWS what kind of EC2 instances to launch
resource "aws_launch_template" "ecs_instances" {
  name          = "clixx-ecs-launch-template"
  image_id      = data.aws_ami.ecs_optimized.id
  instance_type = "t2.small"
  key_name      = var.key_pair_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ecs_instances.id]
  }

  # This user data tells the EC2 instance which ECS cluster to join
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.clixx.name} >> /etc/ecs/ecs.config
  EOF
  )

  tags = {
    Name = "clixx-ecs-launch-template"
  }
}

# Auto Scaling Group launches and maintains the EC2 instances
resource "aws_autoscaling_group" "ecs_instances" {
  name                = "clixx-ecs-asg"
  desired_capacity    = 2
  min_size            = 1
  max_size            = 3
  vpc_zone_identifier = var.public_subnet_ids

  launch_template {
    id      = aws_launch_template.ecs_instances.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "clixx-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }
}


# ============================================================
# 5. CLOUDWATCH LOG GROUP
# ============================================================
# So we can see container logs (like docker logs)

resource "aws_cloudwatch_log_group" "ecs_clixx" {
  name              = "/ecs/clixx-task-def"
  retention_in_days = 7

  tags = {
    Name = "clixx-ecs-logs"
  }
}


# ============================================================
# 6. ECS TASK DEFINITION
# ============================================================
# Manual step: ECS → Task Definitions → Create new
# This defines WHAT container to run and HOW to run it

resource "aws_ecs_task_definition" "clixx" {
  family             = "clixx-task-def"
  network_mode       = "bridge"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  cpu                = "512"   # 0.5 vCPU
  memory             = "1024"  # 1 GB

  container_definitions = jsonencode([
    {
      name      = "clixx-container"
      image     = "${aws_ecr_repository.clixx.repository_url}:${var.docker_image_tag}"
      cpu       = 512
      memory    = 1024
      essential = true

      # Port mapping: container port 80 → host port 8000
      # Same as: docker run -p 8000:80
      portMappings = [
        {
          containerPort = 80
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      # Environment variables for WordPress DB connection
      environment = [
        {
          name  = "WORDPRESS_DB_HOST"
          value = var.db_host
        },
        {
          name  = "WORDPRESS_DB_USER"
          value = var.db_user
        },
        {
          name  = "WORDPRESS_DB_PASSWORD"
          value = var.db_password
        },
        {
          name  = "WORDPRESS_DB_NAME"
          value = var.db_name
        }
      ]

      # Send container logs to CloudWatch
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/clixx-task-def"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "clixx-task-def"
  }
}


# ============================================================
# 7. NETWORK LOAD BALANCER
# ============================================================
# Manual step: EC2 → Load Balancers → Create NLB

resource "aws_lb" "clixx_nlb" {
  name               = "clixx-ecs-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids

  tags = {
    Name = "clixx-ecs-nlb"
  }
}

# Target Group - where the NLB sends traffic
resource "aws_lb_target_group" "clixx" {
  name        = "clixx-ecs-tg"
  port        = 8000
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    protocol            = "HTTP"
    port                = "8000"
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name = "clixx-ecs-tg"
  }
}

# Listener - NLB listens on port 80 and forwards to target group
resource "aws_lb_listener" "clixx" {
  load_balancer_arn = aws_lb.clixx_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.clixx.arn
  }
}


# ============================================================
# 8. ECS SERVICE
# ============================================================
# Manual step: ECS → Cluster → Services → Create
# This keeps 2 containers running and registers them with NLB

resource "aws_ecs_service" "clixx" {
  name            = "clixx-service"
  cluster         = aws_ecs_cluster.clixx.id
  task_definition = aws_ecs_task_definition.clixx.arn
  desired_count   = 2
  launch_type     = "EC2"

  # Connect the service to the NLB
  load_balancer {
    target_group_arn = aws_lb_target_group.clixx.arn
    container_name   = "clixx-container"
    container_port   = 80
  }

  # Wait for NLB listener to be ready before creating service
  depends_on = [aws_lb_listener.clixx]

  tags = {
    Name = "clixx-service"
  }
}


# ============================================================
# 9. ROUTE 53 DNS RECORD
# ============================================================
# Manual step: Route 53 → Hosted Zone → Create A Record (Alias)
# Points ecs.stack-simi.com → NLB
# Uses the route53 provider because hosted zone is in management account

resource "aws_route53_record" "ecs_clixx" {
  provider = aws.route53

  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.clixx_nlb.dns_name
    zone_id                = aws_lb.clixx_nlb.zone_id
    evaluate_target_health = true
  }
}
