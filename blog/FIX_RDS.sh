#!/bin/bash

# Fix RDS module to prevent database recreation

cat > modules/rds/main.tf << 'RDSEOF'
# ============================================================
# RDS MODULE - BLOG WordPress (Restore from Snapshot)
# ============================================================

variable "db_snapshot_id" {
  description = "Snapshot ID to restore from"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "RDS Security Group ID"
  type        = string
}

resource "aws_db_subnet_group" "blog_db_subnet" {
  name       = "blog-wordpress-db-subnet"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "blog-wordpress-db-subnet"
  }
}

resource "aws_db_instance" "blog_db" {
  identifier             = "blog-wordpress-db"
  snapshot_identifier    = var.db_snapshot_id
  instance_class         = var.db_instance_class
  db_subnet_group_name   = aws_db_subnet_group.blog_db_subnet.name
  vpc_security_group_ids = [var.rds_sg_id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = false
  storage_encrypted      = true

  lifecycle {
    ignore_changes = [
      snapshot_identifier,
      storage_encrypted
    ]
  }

  tags = {
    Name = "blog-wordpress-db"
  }
}

output "db_endpoint" {
  value = aws_db_instance.blog_db.address
}

output "db_arn" {
  value = aws_db_instance.blog_db.arn
}
RDSEOF

echo "✅ RDS module fixed!"
echo ""
echo "Run: terraform apply"
