#!/bin/bash
# Fix script for CliXX

# Backup originals
cp clixx/main.tf clixx/main.tf.bak
cp clixx/scripts/clixx_bootstrap.sh clixx/scripts/clixx_bootstrap.sh.bak

# Fix main.tf - Add IAM policy attachments after the instance profile
sed -i '/resource "aws_iam_instance_profile" "ec2" {/,/^}/a\
\
# Managed policies for SSM and EFS\
resource "aws_iam_role_policy_attachment" "ssm_core" {\
  role       = aws_iam_role.ec2.name\
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"\
}\
\
resource "aws_iam_role_policy_attachment" "efs_access" {\
  role       = aws_iam_role.ec2.name\
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientReadWriteAccess"\
}' clixx/main.tf

# Fix health check path and grace period
sed -i 's|path                = "/"|path                = "/wp-admin/install.php"|g' clixx/main.tf
sed -i 's|matcher             = "200,301,302"|matcher             = "200,301,302,403"|g' clixx/main.tf
sed -i 's|health_check_grace_period = var.asg_config\["health_check_grace_period"\]|health_check_grace_period = 600|g' clixx/main.tf

# Fix bootstrap - add SSM agent install at the beginning
sed -i '/# Install packages/i\
# Install SSM agent for debugging\
yum install -y amazon-ssm-agent 2>/dev/null || dnf install -y amazon-ssm-agent 2>/dev/null\
systemctl enable amazon-ssm-agent\
systemctl start amazon-ssm-agent\
' clixx/scripts/clixx_bootstrap.sh

# Add wait before EFS mount
sed -i '/# Mount EFS/a\
echo "Waiting for EFS mount targets..."\
sleep 30' clixx/scripts/clixx_bootstrap.sh

# Commit and push
git add -A
git commit -m "Fix IAM policies, health checks, bootstrap"
git push origin dev

echo "Done! Now run DESTROY then APPLY from Jenkins"
