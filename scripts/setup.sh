#!/bin/bash
set -e

## Install packages for Amazon Linux 2023
sudo dnf update -y
sudo dnf install -y git
sudo dnf install -y httpd
sudo dnf install -y php php-mysqli php-json php-gd php-mbstring php-xml
sudo dnf install -y mariadb105-server
sudo dnf install -y nfs-utils amazon-efs-utils

## Start and enable Apache
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl is-enabled httpd

## Start and enable MariaDB
sudo systemctl start mariadb
sudo systemctl enable mariadb

## Add ec2-user to Apache group and grant permissions to /var/www
sudo usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;
find /var/www -type f -exec sudo chmod 0664 {} \;

## Update httpd.conf
sudo sed -i '151s/None/All/' /etc/httpd/conf/httpd.conf

## Grant file ownership of /var/www & its contents to apache user
sudo chown -R apache /var/www
sudo chgrp -R apache /var/www
sudo chmod 2775 /var/www
find /var/www -type d -exec sudo chmod 2775 {} \;
sudo find /var/www -type f -exec sudo chmod 0664 {} \;

## Restart Apache
sudo systemctl restart httpd

## TCP keepalive settings
sudo /sbin/sysctl -w net.ipv4.tcp_keepalive_time=200 net.ipv4.tcp_keepalive_intvl=200 net.ipv4.tcp_keepalive_probes=5

echo "=== Setup Complete ==="
