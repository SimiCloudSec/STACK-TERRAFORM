#!/bin/bash
###############################################################################
# COMPLETE_FIX.sh - One script to fix everything permanently
###############################################################################
# This script:
# 1. Updates terraform.tfvars with correct password (W3lcome123)
# 2. Fixes bootstrap script to clone CLiXX repo and set correct DB values
# 3. Updates launch template to trigger new instances
###############################################################################

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   COMPLETE FIX - CLiXX WordPress Terraform                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================
# FIX 1: Update terraform.tfvars with correct password
# ============================================================
echo "Fixing terraform.tfvars..."
sed -i 's/db_password = ".*"/db_password = "W3lcome123"/' terraform.tfvars
echo "✓ Password set to W3lcome123"

# ============================================================
# FIX 2: Create corrected bootstrap script
# ============================================================
echo "Creating fixed bootstrap script..."

cat > scripts/clixx_bootstrap.sh << 'EOFSCRIPT'
#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -xe

EFS_ID="${efs_id}"
REGION="${aws_region}"
SITE_URL="${site_url}"
MOUNT_POINT="/var/www/html"

echo "=== CLiXX Bootstrap Starting ==="
echo "EFS: $EFS_ID | Region: $REGION | Site: $SITE_URL"

# Install packages INCLUDING mysql client and git
dnf update -y
dnf install -y httpd php php-mysqli php-json php-gd php-mbstring php-xml \
    nfs-utils unzip wget cronie mariadb105 git

systemctl enable --now httpd
systemctl enable --now crond

# Mount EFS
mkdir -p $${MOUNT_POINT}
# Remove any existing fstab entry for this mount point
sed -i "\|$${MOUNT_POINT}|d" /etc/fstab
echo "$${EFS_ID}.efs.$${REGION}.amazonaws.com:/ $${MOUNT_POINT} nfs4 defaults,_netdev 0 0" >> /etc/fstab
mount -a || mount -t nfs4 -o nfsvers=4.1 $${EFS_ID}.efs.$${REGION}.amazonaws.com:/ $${MOUNT_POINT}
sleep 10

# Get DB credentials from SSM
echo "Getting DB credentials from SSM..."
DB_NAME=$(aws ssm get-parameter --name "/clixx/DB_NAME" --region $${REGION} --query "Parameter.Value" --output text)
DB_USER=$(aws ssm get-parameter --name "/clixx/DB_USER" --region $${REGION} --query "Parameter.Value" --output text)
DB_PASS=$(aws ssm get-parameter --with-decryption --name "/clixx/DB_PASS" --region $${REGION} --query "Parameter.Value" --output text)
DB_HOST=$(aws ssm get-parameter --name "/clixx/DB_HOST" --region $${REGION} --query "Parameter.Value" --output text)

echo "DB_NAME=$DB_NAME | DB_USER=$DB_USER | DB_HOST=$DB_HOST"

# Check if CLiXX files exist on EFS
if [ ! -f "$${MOUNT_POINT}/wp-config.php" ] || [ ! -f "$${MOUNT_POINT}/index.php" ]; then
    echo "WordPress files missing - cloning CLiXX repo..."
    
    # Clean the mount point first
    rm -rf $${MOUNT_POINT}/*
    rm -rf $${MOUNT_POINT}/.[!.]* 2>/dev/null || true
    
    # Clone CLiXX repo
    cd /tmp
    rm -rf CliXX_Retail_Repository
    git clone https://github.com/stackitgit/CliXX_Retail_Repository.git
    cp -r CliXX_Retail_Repository/* $${MOUNT_POINT}/
    rm -rf CliXX_Retail_Repository
    
    echo "CLiXX repo cloned successfully"
fi

# ALWAYS update wp-config.php with correct DB settings from SSM
WP_CONFIG="$${MOUNT_POINT}/wp-config.php"

if [ -f "$${WP_CONFIG}" ]; then
    echo "Updating wp-config.php with SSM values..."
    
    # Backup original
    cp "$${WP_CONFIG}" "$${WP_CONFIG}.bak"
    
    # Use sed with different delimiter to handle special chars
    sed -i "s|define( *'DB_NAME', *'[^']*' *);|define( 'DB_NAME', '$${DB_NAME}' );|g" "$${WP_CONFIG}"
    sed -i "s|define( *'DB_USER', *'[^']*' *);|define( 'DB_USER', '$${DB_USER}' );|g" "$${WP_CONFIG}"
    sed -i "s|define( *'DB_PASSWORD', *'[^']*' *);|define( 'DB_PASSWORD', '$${DB_PASS}' );|g" "$${WP_CONFIG}"
    sed -i "s|define( *'DB_HOST', *'[^']*' *);|define( 'DB_HOST', '$${DB_HOST}' );|g" "$${WP_CONFIG}"
    
    # Verify the changes
    echo "Verifying wp-config.php:"
    grep -E "DB_NAME|DB_USER|DB_HOST|DB_PASSWORD" "$${WP_CONFIG}"
else
    echo "ERROR: wp-config.php not found!"
    exit 1
fi

# Create health check file
echo "OK" > $${MOUNT_POINT}/health.html

# Create cron script for SSM sync
cat > $${MOUNT_POINT}/wp_config_check.sh << 'CRONEOF'
#!/bin/bash
REGION="REGION_PLACEHOLDER"
WP_CONFIG="/var/www/html/wp-config.php"
LOG="/var/log/wp_config_check.log"
TS=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TS] Syncing SSM to wp-config.php" >> $LOG

DB_NAME=$(aws ssm get-parameter --name "/clixx/DB_NAME" --region "$REGION" --query "Parameter.Value" --output text 2>/dev/null)
DB_USER=$(aws ssm get-parameter --name "/clixx/DB_USER" --region "$REGION" --query "Parameter.Value" --output text 2>/dev/null)
DB_PASS=$(aws ssm get-parameter --name "/clixx/DB_PASS" --region "$REGION" --with-decryption --query "Parameter.Value" --output text 2>/dev/null)
DB_HOST=$(aws ssm get-parameter --name "/clixx/DB_HOST" --region "$REGION" --query "Parameter.Value" --output text 2>/dev/null)

if [ -n "$DB_NAME" ] && [ -n "$DB_PASS" ] && [ -f "$WP_CONFIG" ]; then
    sed -i "s|define( *'DB_NAME', *'[^']*' *);|define( 'DB_NAME', '$DB_NAME' );|g" "$WP_CONFIG"
    sed -i "s|define( *'DB_USER', *'[^']*' *);|define( 'DB_USER', '$DB_USER' );|g" "$WP_CONFIG"
    sed -i "s|define( *'DB_PASSWORD', *'[^']*' *);|define( 'DB_PASSWORD', '$DB_PASS' );|g" "$WP_CONFIG"
    sed -i "s|define( *'DB_HOST', *'[^']*' *);|define( 'DB_HOST', '$DB_HOST' );|g" "$WP_CONFIG"
    echo "[$TS] Sync complete" >> $LOG
else
    echo "[$TS] ERROR: Failed to get SSM params or wp-config missing" >> $LOG
fi
CRONEOF

sed -i "s/REGION_PLACEHOLDER/$${REGION}/" $${MOUNT_POINT}/wp_config_check.sh
chmod +x $${MOUNT_POINT}/wp_config_check.sh

# Setup cron
(crontab -l 2>/dev/null | grep -v "wp_config_check.sh"; echo "* * * * * /var/www/html/wp_config_check.sh") | crontab -

# Install WP-CLI
echo "Installing WP-CLI..."
cd /tmp
curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Wait for database to be ready
echo "Waiting for database connection..."
for i in {1..30}; do
    if mysql -h $${DB_HOST} -u $${DB_USER} -p"$${DB_PASS}" $${DB_NAME} -e "SELECT 1;" 2>/dev/null; then
        echo "Database connection successful!"
        break
    fi
    echo "Attempt $i: Waiting for database..."
    sleep 10
done

# Update site URL in database
echo "Updating site URLs in database..."
mysql -h $${DB_HOST} -u $${DB_USER} -p"$${DB_PASS}" $${DB_NAME} -e "UPDATE wp_options SET option_value = 'http://$${SITE_URL}' WHERE option_name IN ('siteurl', 'home');" 2>/dev/null || true

# Permissions
chown -R apache:apache $${MOUNT_POINT}
chmod -R 755 $${MOUNT_POINT}
find $${MOUNT_POINT} -type f -exec chmod 644 {} \;
find $${MOUNT_POINT} -type d -exec chmod 755 {} \;

# SELinux
setsebool -P httpd_can_network_connect on 2>/dev/null || true
setsebool -P httpd_can_network_connect_db on 2>/dev/null || true
setsebool -P httpd_use_nfs on 2>/dev/null || true

# Restart Apache
systemctl restart httpd

echo "=== Bootstrap Complete! Site: http://$${SITE_URL} ==="
EOFSCRIPT

chmod +x scripts/clixx_bootstrap.sh
echo "✓ Bootstrap script fixed"

# ============================================================
# FIX 3: Force launch template update
# ============================================================
echo "Updating launch template module to force recreation..."

cat > modules/lt/main.tf << 'EOF'
variable "ami_id" { type = string }
variable "ec2_config" { type = map(any) }
variable "ec2_sg_id" { type = string }
variable "efs_id" { type = string }
variable "aws_region" { type = string }
variable "site_url" { type = string }
variable "iam_profile" { type = string }
variable "environment" { type = string }

resource "aws_launch_template" "wordpress" {
  name_prefix   = "clixx-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.ec2_config["instance_type"]

  iam_instance_profile { name = var.iam_profile }
  vpc_security_group_ids = [var.ec2_sg_id]

  user_data = base64encode(templatefile("${path.root}/scripts/clixx_bootstrap.sh", {
    efs_id     = var.efs_id
    aws_region = var.aws_region
    site_url   = var.site_url
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "clixx-${var.environment}-instance" }
  }

  # Force new version on every apply
  lifecycle {
    create_before_destroy = true
  }
}

output "lt_id" { value = aws_launch_template.wordpress.id }
output "lt_latest_version" { value = aws_launch_template.wordpress.latest_version }
EOF

echo "✓ Launch template module updated"

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   ALL FIXES APPLIED!                                          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Now run:"
echo ""
echo "  terraform destroy -auto-approve"
echo "  terraform apply -auto-approve"
echo ""
echo "Wait 5-10 minutes for RDS to restore and instances to bootstrap."
echo "Then visit: http://dev.clixx.stack-simi.com"
echo ""
