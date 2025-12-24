data "aws_ami" "golden_ami" {
  most_recent = true
  owners      = ["227764537934", "289390529512"]

  filter {
    name   = "name"
    values = ["ami-stack-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
