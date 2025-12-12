# ============================================================
# RDS MODULE - BLOG WordPress (Restore from Snapshot)
# ============================================================

variable "environment" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "rds_sg_id" {
  type = string
}

variable "rds_config" {
  type = object({
    identifier          = string
    instance_class      = string
    allocated_storage   = number
    storage_type        = string
    engine              = string
    engine_version      = string
    db_name             = string
    db_username         = string
    db_password         = string
    snapshot_identifier = string
    snapshot_arn        = string
    multi_az            = bool
    skip_final_snapshot = bool
    publicly_accessible = bool
    storage_encrypted   = bool
  })
}

resource "aws_db_subnet_group" "blog_db_subnet" {
  name       = "blog-${var.environment}-db-subnet"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "blog-${var.environment}-db-subnet"
  }
}

resource "aws_db_instance" "blog_db" {
  identifier             = var.rds_config.identifier
  snapshot_identifier    = var.rds_config.snapshot_identifier
  instance_class         = var.rds_config.instance_class
  db_subnet_group_name   = aws_db_subnet_group.blog_db_subnet.name
  vpc_security_group_ids = [var.rds_sg_id]
  skip_final_snapshot    = var.rds_config.skip_final_snapshot
  publicly_accessible    = var.rds_config.publicly_accessible
  multi_az               = var.rds_config.multi_az
  storage_encrypted      = var.rds_config.storage_encrypted

  lifecycle {
    ignore_changes = [
      snapshot_identifier,
      storage_encrypted
    ]
  }

  tags = {
    Name         = var.rds_config.identifier
    Environment  = var.environment
    SnapshotARN  = var.rds_config.snapshot_arn
  }
}

output "db_endpoint" {
  value = aws_db_instance.blog_db.address
}

output "db_arn" {
  value = aws_db_instance.blog_db.arn
}

output "db_name" {
  value = var.rds_config.db_name
}

output "db_username" {
  value = var.rds_config.db_username
}

output "db_password" {
  value     = var.rds_config.db_password
  sensitive = true
}
