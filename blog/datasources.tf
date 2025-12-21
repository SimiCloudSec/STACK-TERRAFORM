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
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

cd /c/automation/TERRAFORM/TF

# Update CliXX to use correct AMI filter
cat > clixx/datasources.tf << 'EOF'
# =============================================================================
# DATA SOURCES - CLIXX (Using Golden AMI from Packer)
# =============================================================================
data "aws_ami" "golden_ami" {
  most_recent = true
  owners      = ["289390529512"]
  filter {
    name   = "name"
    values = ["ami-stack-*"]
  }
  filter {
    values = ["hvm"]
  }
}
