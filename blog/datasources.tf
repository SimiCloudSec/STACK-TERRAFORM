# =============================================================================
# DATA SOURCES - BLOG (Using Golden AMI from Packer)
# =============================================================================
data "aws_ami" "golden_ami" {
  most_recent = true
  owners      = ["289390529512"]
  filter {
    name   = "name"
    values = ["ami-stack-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
