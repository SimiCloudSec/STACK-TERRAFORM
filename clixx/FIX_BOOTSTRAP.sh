#!/bin/bash
###############################################################################
# FIX_BOOTSTRAP.sh - Permanent fix for CLiXX wp-config.php format
###############################################################################

echo "Fixing bootstrap script to handle CLiXX git repo wp-config format..."

# Update the bootstrap script with better sed patterns that match CLiXX format
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

# Install packages INCLUDING mysql client
dnf update -y
dnf install -y httpd php php-mysqli php-json php-gd php-mbstring php-xml \
    nfs-utils unzip wget cronie mariadb105

systemctl enable --now httpd
systemctl enable --now crond

# Mount EFS
mkdir -p $${MOUNT_POINT}
echo "$${EFS_ID}.efs.$${REGION}.amazonaws.com:/ $${MOUNT_POINT} nfs4 defaults,_netdev 0 0" >> /etc/fstab
mount -a
sleep 10

# Get DB credentials from SSM
DB_NAME=$(aws ssm get-parameter --name "/clixx/DB_NAME" --region $${REGION} --query "Parameter.Value" --output text)
DB_USER=$(aws ssm get-parameter --name "/clixx/DB_USER" --region $${REGION} --query "Parameter.Value" --output text)
DB_PASS=$(aws ssm get-parameter --with-decryption --name "/clixx/DB_PASS" --region $${REGION} --query "Parameter.Value" --output text)
DB_HOST=$(aws ssm get-parameter --name "/clixx/DB_HOST" --region $${REGION} --query "Parameter.Value" --output text)

echo "DB_NAME=$DB_NAME | DB_USER=$DB_USER | DB_HOST=$DB_HOST"

# Check if CLiXX files exist on EFS, if not clone them
if [ ! -f "$${MOUNT_POINT}/wp-config.php" ]; then
    echo "No WordPress files - cloning CLiXX repo"
    cd $${MOUNT_POINT}
    git clone https://github.com/stackitgit/CliXX_Retail_Repository.git /tmp/clixx
    cp -r /tmp/clixx/* $${MOUNT_POINT}/
    rm -rf /tmp/clixx
fi

# ALWAYS update wp-config.php with correct DB settings
# Using broader patterns to match any format
WP_CONFIG="$${MOUNT_POINT}/wp-config.php"

echo "Updating wp-config.php with SSM values..."

# Use perl for more reliable replacement (handles special chars in password)
perl -i -pe "s/define\s*\(\s*'DB_NAME'\s*,\s*'[^']*'\s*\)/define( 'DB_NAME', '$${DB_NAME}' )/" "$${WP_CONFIG}"
perl -i -pe "s/define\s*\(\s*'DB_USER'\s*,\s*'[^']*'\s*\)/define( 'DB_USER', '$${DB_USER}' )/" "$${WP_CONFIG}"
perl -i -pe "s/define\s*\(\s*'DB_PASSWORD'\s*,\s*'[^']*'\s*\)/define( 'DB_PASSWORD', '$${DB_PASS}' )/" "$${WP_CONFIG}"
perl -i -pe "s/define\s*\(\s*'DB_HOST'\s*,\s*'[^']*'\s*\)/define( 'DB_HOST', '$${DB_HOST}' )/" "$${WP_CONFIG}"

# Verify the changes
echo "Verifying wp-config.php:"
grep -E "DB_NAME|DB_USER|DB_HOST|DB_PASSWORD" "$${WP_CONFIG}"

# Create cron script for SSM sync (also using perl)
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

if [ -n "$DB_NAME" ] && [ -n "$DB_PASS" ]; then
    perl -i -pe "s/define\s*\(\s*'DB_NAME'\s*,\s*'[^']*'\s*\)/define( 'DB_NAME', '$DB_NAME' )/" "$WP_CONFIG"
    perl -i -pe "s/define\s*\(\s*'DB_USER'\s*,\s*'[^']*'\s*\)/define( 'DB_USER', '$DB_USER' )/" "$WP_CONFIG"
    perl -i -pe "s/define\s*\(\s*'DB_PASSWORD'\s*,\s*'[^']*'\s*\)/define( 'DB_PASSWORD', '$DB_PASS' )/" "$WP_CONFIG"
    perl -i -pe "s/define\s*\(\s*'DB_HOST'\s*,\s*'[^']*'\s*\)/define( 'DB_HOST', '$DB_HOST' )/" "$WP_CONFIG"
    echo "[$TS] Sync complete" >> $LOG
else
    echo "[$TS] ERROR: Failed to get SSM params" >> $LOG
fi
CRONEOF

sed -i "s/REGION_PLACEHOLDER/$${REGION}/" $${MOUNT_POINT}/wp_config_check.sh
chmod +x $${MOUNT_POINT}/wp_config_check.sh

# Setup cron
crontab -l > /tmp/mycron 2>/dev/null || true
grep -q "wp_config_check.sh" /tmp/mycron || echo "* * * * * /var/www/html/wp_config_check.sh" >> /tmp/mycron
crontab /tmp/mycron
rm -f /tmp/mycron

# Install WP-CLI
curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar && mv wp-cli.phar /usr/local/bin/wp

# Update site URL in database
sleep 30
cd $${MOUNT_POINT}

# Try WP-CLI first, fall back to MySQL
if /usr/local/bin/wp option update siteurl "http://$${SITE_URL}" --allow-root 2>/dev/null; then
    /usr/local/bin/wp option update home "http://$${SITE_URL}" --allow-root 2>/dev/null
else
    echo "WP-CLI failed, using MySQL directly"
    mysql -h $${DB_HOST} -u $${DB_USER} -p"$${DB_PASS}" $${DB_NAME} -e "UPDATE wp_options SET option_value = 'http://$${SITE_URL}' WHERE option_name IN ('siteurl', 'home');" 2>/dev/null || true
fi

# Permissions
chown -R apache:apache $${MOUNT_POINT}
chmod 755 $${MOUNT_POINT}

# SELinux
setsebool -P httpd_can_network_connect on 2>/dev/null || true
setsebool -P httpd_can_network_connect_db on 2>/dev/null || true
setsebool -P httpd_use_nfs on 2>/dev/null || true

systemctl restart httpd

echo "=== Bootstrap Complete! Site: http://$${SITE_URL} ==="
EOFSCRIPT

chmod +x scripts/clixx_bootstrap.sh
echo "✓ Bootstrap script updated"

# Force launch template update by touching it
touch modules/lt/main.tf

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   PERMANENT FIX APPLIED!                                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Now run:"
echo "  terraform apply -auto-approve"
echo ""
echo "This will update the launch template with the fixed bootstrap."
echo "Then terminate existing instances to get new ones with the fix."
echo ""
