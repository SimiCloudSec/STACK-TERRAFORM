packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_instance_type" {
  default = "t2.small"
}

variable "ami_name" {
  default = "ami-stack-51"
}

variable "component" {
  default = "clixx"
}

variable "aws_accounts" {
  type    = list(string)
  default = ["289390529512"]  # Your Dev account
}

variable "ami_regions" {
  type    = list(string)
  default = ["us-east-1"]
}

variable "aws_region" {
  default = "us-east-1"
}

data "amazon-ami" "source_ami" {
  filters = {
    name                = "al2023-ami-*-x86_64"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["amazon"]
  region      = var.aws_region
}

source "amazon-ebs" "amazon_ebs" {
  ami_name       = var.ami_name
  ami_regions    = var.ami_regions
  ami_users      = var.aws_accounts
  snapshot_users = var.aws_accounts
  encrypt_boot   = false
  instance_type  = var.aws_instance_type

  launch_block_device_mappings {
    delete_on_termination = true
    device_name           = "/dev/xvda"
    encrypted             = false
    volume_size           = 30
    volume_type           = "gp2"
  }

  region       = var.aws_region
  source_ami   = data.amazon-ami.source_ami.id
  ssh_pty      = true
  ssh_timeout  = "5m"
  ssh_username = "ec2-user"

  tags = {
    Name      = "CliXX-Golden-AMI"
    Component = var.component
    ManagedBy = "Packer"
  }
}

build {
  sources = ["source.amazon-ebs.amazon_ebs"]

  provisioner "shell" {
    script = "../scripts/setup.sh"
  }
}
