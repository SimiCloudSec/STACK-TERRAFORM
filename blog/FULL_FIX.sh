#!/bin/bash

echo "Getting instance IP..."
INSTANCE_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=blog-wordpress-asg-instance" "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

echo "Instance IP: $INSTANCE_IP"

cat > /tmp/fix_wordpress.sh << 'FIXSCRIPT'
#!/bin/bash
set -x

# CORRECT database settings
DB_HOST="blog-wordpress-db.c89kycay8m25.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_PASS="Alienpython123"
DB_NAME="wordpress_db"
NEW_URL="http://dev.blog.stack-simi.com"
WP_CONFIG="/var/www/html/wp-config.php"

echo "=== Fixing wp-config.php ==="
sudo sed -i "s|define( 'DB_NAME', '.*' );|define( 'DB_NAME', '$DB_NAME' );|g" $WP_CONFIG
sudo sed -i "s|define( 'DB_PASSWORD', '.*' );|define( 'DB_PASSWORD', '$DB_PASS' );|g" $WP_CONFIG
sudo sed -i "s|define( 'DB_HOST', '.*' );|define( 'DB_HOST', '$DB_HOST' );|g" $WP_CONFIG

echo "=== Verifying wp-config.php ==="
sudo grep -i 'DB_' $WP_CONFIG

echo "=== Testing DB connection ==="
mysql -h $DB_HOST -u $DB_USER -p"$DB_PASS" $DB_NAME -e "SELECT 1;" || { echo "DB CONNECTION FAILED!"; exit 1; }

echo "=== Current URLs in database ==="
mysql -h $DB_HOST -u $DB_USER -p"$DB_PASS" $DB_NAME -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"

echo "=== Updating ALL URLs ==="
mysql -h $DB_HOST -u $DB_USER -p"$DB_PASS" $DB_NAME <<EOFMYSQL
UPDATE wp_options SET option_value = '$NEW_URL' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = '$NEW_URL' WHERE option_name = 'home';
UPDATE wp_posts SET post_content = REPLACE(post_content, 'http://52.91.133.130', '$NEW_URL');
UPDATE wp_posts SET guid = REPLACE(guid, 'http://52.91.133.130', '$NEW_URL');
UPDATE wp_postmeta SET meta_value = REPLACE(meta_value, 'http://52.91.133.130', '$NEW_URL');
EOFMYSQL

echo "=== Verifying URLs ==="
mysql -h $DB_HOST -u $DB_USER -p"$DB_PASS" $DB_NAME -e "SELECT option_name, option_value FROM wp_options WHERE option_name IN ('siteurl', 'home');"

echo "=== Restarting Apache ==="
sudo systemctl restart httpd

echo "=== DONE! ==="
FIXSCRIPT

scp -i blog-wordpress-key.pem -o StrictHostKeyChecking=no /tmp/fix_wordpress.sh ec2-user@$INSTANCE_IP:/tmp/
ssh -i blog-wordpress-key.pem -o StrictHostKeyChecking=no ec2-user@$INSTANCE_IP "chmod +x /tmp/fix_wordpress.sh && /tmp/fix_wordpress.sh"

echo ""
echo "============================================"
echo "Now open: http://dev.blog.stack-simi.com"
echo "============================================"
