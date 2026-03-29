#!/bin/bash
set -xe
exec > /var/log/user-data.log 2>&1

EFS_ID="${efs_id}"
DB_HOST="${db_host}"
DB_NAME="wordpress_db"
DB_USER="${db_user}"
DB_PASS="${db_pass}"
SITE_URL="${site_url}"
MOUNT_POINT="/var/www/html"

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 3600")
AVAILABILITY_ZONE=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
REGION=$(echo $AVAILABILITY_ZONE | sed 's/[a-z]$//')

mkdir -p $MOUNT_POINT
chown ec2-user:ec2-user $MOUNT_POINT

if ! grep -q "$EFS_ID" /etc/fstab; then
  echo "$EFS_ID.efs.$REGION.amazonaws.com:/ $MOUNT_POINT nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0" >> /etc/fstab
fi

sleep 20
mount -a -t nfs4

if [ -z "$(ls -A $MOUNT_POINT 2>/dev/null)" ]; then
  git clone https://github.com/SimiCloudSec/Simi-Blog.git $MOUNT_POINT
fi

WP_CONFIG="$MOUNT_POINT/wp-config.php"
if [ -f "$WP_CONFIG" ]; then
  sed -i "s|define( 'DB_NAME', '.*' );|define( 'DB_NAME', '$DB_NAME' );|g" $WP_CONFIG
  sed -i "s|define( 'DB_USER', '.*' );|define( 'DB_USER', '$DB_USER' );|g" $WP_CONFIG
  sed -i "s|define( 'DB_PASSWORD', '.*' );|define( 'DB_PASSWORD', '$DB_PASS' );|g" $WP_CONFIG
  sed -i "s|define( 'DB_HOST', '.*' );|define( 'DB_HOST', '$DB_HOST' );|g" $WP_CONFIG
fi

chown -R apache:apache $MOUNT_POINT
chmod -R 755 $MOUNT_POINT

systemctl enable httpd
systemctl start httpd

echo "<h1>Health OK</h1>" > $MOUNT_POINT/health.html
chown apache:apache $MOUNT_POINT/health.html
[ -f $MOUNT_POINT/index.html ] && rm -f $MOUNT_POINT/index.html

sleep 15
mysql -h $DB_HOST -u $DB_USER -p"$DB_PASS" wordpress_db <<EOFMYSQL || echo "DB update skipped"
UPDATE wp_options SET option_value = 'http://$SITE_URL' WHERE option_name = 'siteurl';
UPDATE wp_options SET option_value = 'http://$SITE_URL' WHERE option_name = 'home';
EOFMYSQL

systemctl restart httpd
echo "Blog bootstrap completed!" >> /var/log/user-data-status.log
