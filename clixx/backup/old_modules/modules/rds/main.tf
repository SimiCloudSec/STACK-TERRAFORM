variable "subnet_ids" { type = list(string) }
variable "rds_sg_id" { type = string }
variable "environment" { type = string }
variable "rds_config" { type = map(any) }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "snapshot_identifier" {
  type    = string
  default = ""
}

resource "aws_db_subnet_group" "wordpress" {
  name       = "clixx-${var.environment}-db-subnet"
  subnet_ids = var.subnet_ids
  tags       = { Name = "clixx-${var.environment}-db-subnet" }
}

resource "aws_db_instance" "wordpress" {
  identifier             = "clixx-${var.environment}-db"
  snapshot_identifier    = var.snapshot_identifier != "" ? var.snapshot_identifier : null
  instance_class         = var.rds_config["instance_class"]
  db_subnet_group_name   = aws_db_subnet_group.wordpress.name
  vpc_security_group_ids = [var.rds_sg_id]
  skip_final_snapshot    = var.rds_config["skip_final_snapshot"]
  multi_az               = var.rds_config["multi_az"]
  publicly_accessible    = var.rds_config["publicly_accessible"]
  tags                   = { Name = "clixx-${var.environment}-db" }
}

output "db_endpoint" { value = aws_db_instance.wordpress.address }
