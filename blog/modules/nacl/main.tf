# =============================================================================
# NACL MODULE - Network Access Control Lists (Matches AWS VPC Lab)
# =============================================================================

variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "private_subnet_ids" { type = list(string) }
variable "environment" { type = string }

# Public NACL
resource "aws_network_acl" "public" {
  vpc_id     = var.vpc_id
  subnet_ids = var.public_subnet_ids

  # Inbound: SSH
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = "0.0.0.0/0"
  }
  # Inbound: HTTP
  ingress {
    rule_no    = 200
    action     = "allow"
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
  }
  # Inbound: HTTPS
  ingress {
    rule_no    = 300
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }
  # Inbound: Ephemeral Ports
  ingress {
    rule_no    = 400
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }
  # Inbound: ICMP
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

  # Outbound: HTTP
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
  }
  # Outbound: HTTPS
  egress {
    rule_no    = 200
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }
  # Outbound: Ephemeral
  egress {
    rule_no    = 300
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }
  # Outbound: SSH to VPC
  egress {
    rule_no    = 400
    action     = "allow"
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = var.vpc_cidr
  }
  # Outbound: ICMP
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

# Private NACL
resource "aws_network_acl" "private" {
  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Inbound: SSH from VPC
  ingress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 22
    to_port    = 22
    cidr_block = var.vpc_cidr
  }
  # Inbound: HTTP from VPC
  ingress {
    rule_no    = 200
    action     = "allow"
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = var.vpc_cidr
  }
  # Inbound: MySQL from VPC
  ingress {
    rule_no    = 300
    action     = "allow"
    protocol   = "tcp"
    from_port  = 3306
    to_port    = 3306
    cidr_block = var.vpc_cidr
  }
  # Inbound: NFS from VPC
  ingress {
    rule_no    = 400
    action     = "allow"
    protocol   = "tcp"
    from_port  = 2049
    to_port    = 2049
    cidr_block = var.vpc_cidr
  }
  # Inbound: Ephemeral (return from NAT)
  ingress {
    rule_no    = 500
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }
  # Inbound: ICMP from VPC
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

  # Outbound: HTTP
  egress {
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    from_port  = 80
    to_port    = 80
    cidr_block = "0.0.0.0/0"
  }
  # Outbound: HTTPS
  egress {
    rule_no    = 200
    action     = "allow"
    protocol   = "tcp"
    from_port  = 443
    to_port    = 443
    cidr_block = "0.0.0.0/0"
  }
  # Outbound: MySQL
  egress {
    rule_no    = 300
    action     = "allow"
    protocol   = "tcp"
    from_port  = 3306
    to_port    = 3306
    cidr_block = var.vpc_cidr
  }
  # Outbound: NFS
  egress {
    rule_no    = 400
    action     = "allow"
    protocol   = "tcp"
    from_port  = 2049
    to_port    = 2049
    cidr_block = var.vpc_cidr
  }
  # Outbound: Ephemeral
  egress {
    rule_no    = 500
    action     = "allow"
    protocol   = "tcp"
    from_port  = 1024
    to_port    = 65535
    cidr_block = "0.0.0.0/0"
  }
  # Outbound: ICMP
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

output "public_nacl_id" { value = aws_network_acl.public.id }
output "private_nacl_id" { value = aws_network_acl.private.id }
