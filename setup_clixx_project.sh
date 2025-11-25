#!/bin/bash

echo "🚀 Setting up CLIXX Terraform Project Structure..."

# Base directory (your current folder)
BASE_DIR=$(pwd)

# Create main directory
mkdir -p $BASE_DIR/clixx

# Create main Terraform files inside /clixx
touch $BASE_DIR/clixx/main.tf
touch $BASE_DIR/clixx/providers.tf
touch $BASE_DIR/clixx/versions.tf
touch $BASE_DIR/clixx/variables.tf
touch $BASE_DIR/clixx/outputs.tf
touch $BASE_DIR/clixx/datasources.tf
touch $BASE_DIR/clixx/terraform.tfvars

# Create modules folder + all module subfolders
mkdir -p $BASE_DIR/clixx/modules/{sg,rds,efs,alb,tg,lt,asg,keypair}

# Create placeholder files inside each module
for module in sg rds efs alb tg lt asg keypair
do
    touch $BASE_DIR/clixx/modules/$module/main.tf
    touch $BASE_DIR/clixx/modules/$module/variables.tf
    touch $BASE_DIR/clixx/modules/$module/outputs.tf
done

# Create scripts directory
mkdir -p $BASE_DIR/clixx/scripts

# Create bootstrap script + parameter store script placeholders
touch $BASE_DIR/clixx/scripts/clixx_bootstrap.sh
touch $BASE_DIR/clixx/scripts/wp_config_check.sh

# Make scripts executable
chmod +x $BASE_DIR/clixx/scripts/clixx_bootstrap.sh
chmod +x $BASE_DIR/clixx/scripts/wp_config_check.sh

echo "✅ CLIXX Terraform project structure created successfully!"
echo "📁 Location: $BASE_DIR/clixx"
echo ""
echo "You can now start adding code to each module and begin your pull requests."

