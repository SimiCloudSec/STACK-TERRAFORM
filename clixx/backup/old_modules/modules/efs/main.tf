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
