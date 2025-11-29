#!/bin/bash

# Fix bootstrap script - remove mysql, use mariadb105

cat > scripts/blog_bootstrap.sh << 'BOOTSTRAP'
#!/bin/bash
# ------------------------------------------------------------
# BLOG WordPress Bootstrap Script (Amazon Linux 2023 - ARM)
# Author: Simi Talabi
# Fully automated - fixes WordPress URL automatically
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
DB_NAME="${db_name}"
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
  chown -R apache:apache $${MOUNT_POINT}
  chmod -R 755 $${MOUNT_POINT}
else
  echo "EFS already contains files — skipping clone."
fi

# ------------------------------------------------------------
# 5. Update wp-config.php with database settings
# ------------------------------------------------------------
WP_CONFIG="$${MOUNT_POINT}/wp-config.php"

if [ -f "$${WP_CONFIG}" ]; then
  sed -i "s/database_name_here/$${DB_NAME}/" $${WP_CONFIG}
  sed -i "s/username_here/$${DB_USER}/" $${WP_CONFIG}
  sed -i "s/password_here/$${DB_PASS}/" $${WP_CONFIG}
  sed -i "s/localhost/$${DB_HOST}/" $${WP_CONFIG}
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
if [ ! -f $${MOUNT_POINT}/health.html ]; then
  echo "<h1>Health OK - $(hostname)</h1>" > $${MOUNT_POINT}/health.html
fi

# ------------------------------------------------------------
# 9. Ensure WordPress Loads First
# ------------------------------------------------------------
if [ -f $${MOUNT_POINT}/index.html ]; then
  rm -f $${MOUNT_POINT}/index.html
fi

# ------------------------------------------------------------
# 10. FIX WORDPRESS URL IN DATABASE (AUTOMATIC)
# ------------------------------------------------------------
echo "Updating WordPress Site URL to: http://$${SITE_URL}"

# Wait for database to be ready
sleep 10

# Update WordPress siteurl and home using mariadb client
mysql -h $${DB_HOST} -u $${DB_USER} -p"$${DB_PASS}" $${DB_NAME} <<EOFMYSQL
UPDATE wp_options SET option_value = 'http://$${SITE_URL}' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'http://$${SITE_URL}' WHERE option_name = 'home';
EOFMYSQL

echo "WordPress URL updated successfully!"

# ------------------------------------------------------------
# 11. Final Verification Log
# ------------------------------------------------------------
echo "Blog WordPress bootstrap completed successfully on $(hostname)" >> /var/log/user-data-status.log
echo "Site URL: http://$${SITE_URL}" >> /var/log/user-data-status.log
BOOTSTRAP

chmod +x scripts/blog_bootstrap.sh
echo "✅ Bootstrap script fixed!"
echo ""
echo "Now run:"
echo "  terraform apply"
echo "  Then terminate old instances"
