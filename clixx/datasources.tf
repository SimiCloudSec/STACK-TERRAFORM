# =============================================================================
# DATA SOURCES - CLIXX (Using Golden AMI from Packer)
# =============================================================================
data "aws_ami" "golden_ami" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["stack-ami-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
