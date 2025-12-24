#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -x

EFS_ID="${efs_id}"
REGION="${aws_region}"
SITE_URL="${site_url}"
MOUNT_POINT="/var/www/html"

echo "=== CLiXX Bootstrap Starting ==="
echo "EFS: $EFS_ID | Region: $REGION | Site: $SITE_URL"

# Start services (already installed in golden AMI)
systemctl enable --now httpd || true
systemctl enable --now crond || true

# Mount EFS
echo "Waiting for EFS mount targets..."
sleep 30
mkdir -p $MOUNT_POINT
sed -i "\|$MOUNT_POINT|d" /etc/fstab
echo "$EFS_ID.efs.$REGION.amazonaws.com:/ $MOUNT_POINT nfs4 defaults,_netdev 0 0" >> /etc/fstab
mount -a || mount -t nfs4 -o nfsvers=4.1 $EFS_ID.efs.$REGION.amazonaws.com:/ $MOUNT_POINT
sleep 10

# Get DB credentials from SSM
DB_NAME=$(aws ssm get-parameter --name "/clixx/DB_NAME" --region $REGION --query "Parameter.Value" --output text)
DB_USER=$(aws ssm get-parameter --name "/clixx/DB_USER" --region $REGION --query "Parameter.Value" --output text)
DB_PASS=$(aws ssm get-parameter --with-decryption --name "/clixx/DB_PASS" --region $REGION --query "Parameter.Value" --output text)
DB_HOST=$(aws ssm get-parameter --name "/clixx/DB_HOST" --region $REGION --query "Parameter.Value" --output text)

echo "DB_NAME=$DB_NAME | DB_USER=$DB_USER | DB_HOST=$DB_HOST"

# Clone CLiXX repo if WordPress files don't exist
if [ ! -f "$MOUNT_POINT/wp-config.php" ]; then
    echo "WordPress files missing - cloning CLiXX repo..."
    rm -rf $MOUNT_POINT/*
    cd /tmp
    git clone https://github.com/stackitgit/CliXX_Retail_Repository.git
    cp -r CliXX_Retail_Repository/* $MOUNT_POINT/
    rm -rf CliXX_Retail_Repository
fi

# Update wp-config.php with correct DB settings
WP_CONFIG="$MOUNT_POINT/wp-config.php"
if [ -f "$WP_CONFIG" ]; then
    sed -i "s|define( *'DB_NAME', *'[^']*' *);|define( 'DB_NAME', '$DB_NAME' );|g" "$WP_CONFIG"
    sed -i "s|define( *'DB_USER', *'[^']*' *);|define( 'DB_USER', '$DB_USER' );|g" "$WP_CONFIG"
    sed -i "s|define( *'DB_PASSWORD', *'[^']*' *);|define( 'DB_PASSWORD', '$DB_PASS' );|g" "$WP_CONFIG"
    sed -i "s|define( *'DB_HOST', *'[^']*' *);|define( 'DB_HOST', '$DB_HOST' );|g" "$WP_CONFIG"
    echo "wp-config.php updated"
fi

# Wait for database and update site URL
echo "Waiting for database..."
for i in {1..30}; do
    if mysql -h $DB_HOST -u $DB_USER -p"$DB_PASS" $DB_NAME -e "SELECT 1;" 2>/dev/null; then
        echo "Database connected!"
        mysql -h $DB_HOST -u $DB_USER -p"$DB_PASS" $DB_NAME -e "UPDATE wp_options SET option_value = 'http://$SITE_URL' WHERE option_name IN ('siteurl', 'home');" 2>/dev/null || true
        break
    fi
    echo "Attempt $i - waiting for database..."
    sleep 10
done

# Permissions
chown -R apache:apache $MOUNT_POINT
chmod -R 755 $MOUNT_POINT

# SELinux
setsebool -P httpd_can_network_connect on 2>/dev/null || true
setsebool -P httpd_can_network_connect_db on 2>/dev/null || true
setsebool -P httpd_use_nfs on 2>/dev/null || true

systemctl restart httpd

echo "=== Bootstrap Complete! Site: http://$SITE_URL ==="
