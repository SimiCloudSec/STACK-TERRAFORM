///////////////////////////////////////////////////////////////////////////////
// CLIXX AMI BUILDER - Packer Template
//
// This builds an Amazon Linux 2023 AMI with:
//   - Apache (httpd)
//   - PHP 8.x
//   - WordPress dependencies
//   - AWS CLI
//   - EFS mount utilities
//
// The AMI is pre-baked so EC2 instances launch faster!
///////////////////////////////////////////////////////////////////////////////

packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

//-----------------------------------------------------------------------------
// VARIABLES
//-----------------------------------------------------------------------------
variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name (dev, staging, prod)"
}

variable "region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Instance type for building AMI"
}

//-----------------------------------------------------------------------------
// DATA SOURCES
//-----------------------------------------------------------------------------
data "amazon-ami" "amazon_linux" {
  filters = {
    name                = "al2023-ami-*-x86_64"
    virtualization-type = "hvm"
    root-device-type    = "ebs"
  }
  owners      = ["amazon"]
  most_recent = true
  region      = var.region
}

//-----------------------------------------------------------------------------
// SOURCE - EC2 Instance for Building
//-----------------------------------------------------------------------------
source "amazon-ebs" "clixx" {
  ami_name        = "clixx-wordpress-${var.environment}-{{timestamp}}"
  ami_description = "CLIXX WordPress AMI - ${var.environment} environment"
  instance_type   = var.instance_type
  region          = var.region
  source_ami      = data.amazon-ami.amazon_linux.id
  ssh_username    = "ec2-user"

  tags = {
    Name        = "clixx-wordpress-${var.environment}"
    Environment = var.environment
    Builder     = "Packer"
    Project     = "CLIXX"
  }

  # Use default VPC
  associate_public_ip_address = true
}

//-----------------------------------------------------------------------------
// BUILD - What to Install
//-----------------------------------------------------------------------------
build {
  sources = ["source.amazon-ebs.clixx"]

  # Update system
  provisioner "shell" {
    inline = [
      "echo '=== Updating System ==='",
      "sudo dnf update -y"
    ]
  }

  # Install Apache and PHP
  provisioner "shell" {
    inline = [
      "echo '=== Installing Apache and PHP ==='",
      "sudo dnf install -y httpd",
      "sudo dnf install -y php php-mysqlnd php-fpm php-json php-xml php-mbstring php-gd php-curl",
      "sudo systemctl enable httpd"
    ]
  }

  # Install EFS utilities
  provisioner "shell" {
    inline = [
      "echo '=== Installing EFS Utilities ==='",
      "sudo dnf install -y amazon-efs-utils nfs-utils"
    ]
  }

  # Install AWS CLI
  provisioner "shell" {
    inline = [
      "echo '=== Installing AWS CLI ==='",
      "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'",
      "sudo dnf install -y unzip",
      "unzip awscliv2.zip",
      "sudo ./aws/install",
      "rm -rf aws awscliv2.zip"
    ]
  }

  # Install MySQL client
  provisioner "shell" {
    inline = [
      "echo '=== Installing MySQL Client ==='",
      "sudo dnf install -y mariadb105"
    ]
  }

  # Install Git and other tools
  provisioner "shell" {
    inline = [
      "echo '=== Installing Git and Tools ==='",
      "sudo dnf install -y git jq wget"
    ]
  }

  # Set up Apache directory
  provisioner "shell" {
    inline = [
      "echo '=== Setting Up Web Directory ==='",
      "sudo mkdir -p /var/www/html",
      "sudo chown -R apache:apache /var/www/html",
      "sudo chmod -R 755 /var/www/html"
    ]
  }

  # Clean up
  provisioner "shell" {
    inline = [
      "echo '=== Cleaning Up ==='",
      "sudo dnf clean all",
      "sudo rm -rf /var/cache/dnf",
      "echo '=== AMI Build Complete ==='"
    ]
  }
}
