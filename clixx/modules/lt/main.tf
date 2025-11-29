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

  # Force new version on every apply
  lifecycle {
    create_before_destroy = true
  }
}

output "lt_id" { value = aws_launch_template.wordpress.id }
output "lt_latest_version" { value = aws_launch_template.wordpress.latest_version }
