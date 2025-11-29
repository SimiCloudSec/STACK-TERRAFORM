# ============================================================
# KEY PAIR MODULE - BLOG WordPress
# ============================================================

variable "key_name" {
  description = "Name of the key pair"
  type        = string
}

resource "tls_private_key" "blog_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "blog_key" {
  key_name   = var.key_name
  public_key = tls_private_key.blog_key.public_key_openssh

  tags = {
    Name = var.key_name
  }
}

resource "local_file" "private_key" {
  content         = tls_private_key.blog_key.private_key_pem
  filename        = "${path.root}/${var.key_name}.pem"
  file_permission = "0400"
}

output "key_name" {
  value = aws_key_pair.blog_key.key_name
}

output "private_key_path" {
  value = local_file.private_key.filename
}
