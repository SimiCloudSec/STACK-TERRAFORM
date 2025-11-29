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
