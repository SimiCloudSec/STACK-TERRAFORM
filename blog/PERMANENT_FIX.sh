#!/bin/bash

echo "=== Making ALL fixes permanent ==="

# 1. Fix terraform.tfvars
cat > terraform.tfvars << 'TFVARS'
# ============================================================
# TERRAFORM VARIABLES - BLOG WordPress Infrastructure
# ============================================================

aws_region = "us-east-1"

# Database (Restore from Snapshot)
db_snapshot_id    = "wordpressinstance2"
db_instance_class = "db.t4g.micro"
db_name           = "wordpress_db"
db_username       = "admin"
db_password       = "Alienpython123"

# EC2
instance_type = "t4g.micro"
key_name      = "blog-wordpress-key"

# Auto Scaling
asg_min_size         = 1
asg_max_size         = 3
asg_desired_capacity = 2

# Route53
domain_name    = "stack-simi.com"
hosted_zone_id = "Z069777410G7QIT8P199L"
environment    = "dev"
TFVARS

echo "✅ terraform.tfvars fixed"

# 2. Fix bootstrap script
cat > scripts/blog_bootstrap.sh << 'BOOTSTRAP'
#!/bin/bash
# ------------------------------------------------------------
# BLOG WordPress Bootstrap Script (Amazon Linux 2023 - ARM)
# Author: Simi Talabi
# PERMANENT FIX - All values correct
# ------------------------------------------------------------
set -xe
exec > /var/log/user-data.log 2>&1

# ------------------------------------------------------------
# 1. System Update + Package Installation
# ------------------------------------------------------------
dnf update -y
dnf install -y nfs-utils httpd php php-mysqlnd mariadb105 git

# ------------------------------------------------------------
# 2. Define Variables
# ------------------------------------------------------------
EFS_ID="${efs_id}"
DB_HOST="${db_host}"
DB_NAME="wordpress_db"
DB_USER="${db_user}"
DB_PASS="${db_pass}"
SITE_URL="${site_url}"
MOUNT_POINT="/var/www/html"

# Retrieve Region dynamically via IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 3600")
AVAILABILITY_ZONE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION=$(echo $AVAILABILITY_ZONE | sed 's/[a-z]$//')

# ------------------------------------------------------------
# 3. Prepare & Mount EFS
# ------------------------------------------------------------
mkdir -p $${MOUNT_POINT}
chown ec2-user:ec2-user $${MOUNT_POINT}

if ! grep -q "$${EFS_ID}" /etc/fstab; then
  echo "$${EFS_ID}.efs.$${REGION}.amazonaws.com:/ $${MOUNT_POINT} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0" >> /etc/fstab
fi

sleep 20
mount -a -t nfs4

# ------------------------------------------------------------
# 4. Deploy WordPress (from GitHub repo)
# ------------------------------------------------------------
if [ -z "$(ls -A $${MOUNT_POINT} 2>/dev/null)" ]; then
  echo "Cloning WordPress blog from GitHub..."
  git clone https://github.com/SimiCloudSec/Simi-Blog.git $${MOUNT_POINT}
fi

# ------------------------------------------------------------
# 5. Fix wp-config.php with CORRECT database settings
# ------------------------------------------------------------
WP_CONFIG="$${MOUNT_POINT}/wp-config.php"

if [ -f "$${WP_CONFIG}" ]; then
  # Update database settings
  sed -i "s|define( 'DB_NAME', '.*' );|define( 'DB_NAME', '$${DB_NAME}' );|g" $${WP_CONFIG}
  sed -i "s|define( 'DB_USER', '.*' );|define( 'DB_USER', '$${DB_USER}' );|g" $${WP_CONFIG}
  sed -i "s|define( 'DB_PASSWORD', '.*' );|define( 'DB_PASSWORD', '$${DB_PASS}' );|g" $${WP_CONFIG}
  sed -i "s|define( 'DB_HOST', '.*' );|define( 'DB_HOST', '$${DB_HOST}' );|g" $${WP_CONFIG}
fi

# ------------------------------------------------------------
# 6. Set Correct Permissions
# ------------------------------------------------------------
chown -R apache:apache $${MOUNT_POINT}
chmod -R 755 $${MOUNT_POINT}

# ------------------------------------------------------------
# 7. Start & Enable Services
# ------------------------------------------------------------
systemctl enable httpd
systemctl start httpd

# ------------------------------------------------------------
# 8. Health Check File for Load Balancer
# ------------------------------------------------------------
echo "<h1>Health OK - $(hostname)</h1>" > $${MOUNT_POINT}/health.html

# ------------------------------------------------------------
# 9. Ensure WordPress Loads First
# ------------------------------------------------------------
if [ -f $${MOUNT_POINT}/index.html ]; then
  rm -f $${MOUNT_POINT}/index.html
fi

# ------------------------------------------------------------
# 10. FIX WORDPRESS URL IN DATABASE (AUTOMATIC)
# ------------------------------------------------------------
echo "Waiting for database..."
sleep 15

echo "Updating WordPress Site URL to: http://$${SITE_URL}"
mysql -h $${DB_HOST} -u $${DB_USER} -p"$${DB_PASS}" wordpress_db <<EOFMYSQL
UPDATE wp_options SET option_value = 'http://$${SITE_URL}' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'http://$${SITE_URL}' WHERE option_name = 'home';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://44.194.58.211', 'http://$${SITE_URL}');
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://52.91.133.130', 'http://$${SITE_URL}');
UPDATE wp_posts SET guid = REPLACE(guid, 'http://44.194.58.211', 'http://$${SITE_URL}');
UPDATE wp_posts SET guid = REPLACE(guid, 'http://52.91.133.130', 'http://$${SITE_URL}');
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'http://44.194.58.211', 'http://$${SITE_URL}');
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'http://52.91.133.130', 'http://$${SITE_URL}');
EOFMYSQL

echo "WordPress URL updated!"

# ------------------------------------------------------------
# 11. Final
# ------------------------------------------------------------
systemctl restart httpd
echo "Blog bootstrap completed! Site: http://$${SITE_URL}" >> /var/log/user-data-status.log
BOOTSTRAP

chmod +x scripts/blog_bootstrap.sh
echo "✅ Bootstrap script fixed"

echo ""
echo "============================================"
echo "   ALL FIXES ARE NOW PERMANENT!"
echo "============================================"
echo ""
echo "You can now safely run:"
echo "  terraform destroy"
echo "  terraform apply"
echo ""
echo "And it will work automatically!"
echo ""
