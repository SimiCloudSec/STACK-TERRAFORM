#!/bin/bash

echo "🚀 Setting up BLOG (WordPress) Terraform Project Structure..."

BASE_DIR=$(pwd)

# Create blog folder
mkdir -p $BASE_DIR/blog

# Create top-level Terraform files
touch $BASE_DIR/blog/main.tf
touch $BASE_DIR/blog/providers.tf
touch $BASE_DIR/blog/versions.tf
touch $BASE_DIR/blog/variables.tf
touch $BASE_DIR/blog/outputs.tf
touch $BASE_DIR/blog/datasources.tf
touch $BASE_DIR/blog/terraform.tfvars

# Create module directories
mkdir -p $BASE_DIR/blog/modules/{sg,rds,efs,alb,tg,lt,asg,keypair}

# Create placeholder module files
for module in sg rds efs alb tg lt asg keypair
do
    touch $BASE_DIR/blog/modules/$module/main.tf
    touch $BASE_DIR/blog/modules/$module/variables.tf
    touch $BASE_DIR/blog/modules/$module/outputs.tf
done

# Create scripts folder + empty bash scripts
mkdir -p $BASE_DIR/blog/scripts
touch $BASE_DIR/blog/scripts/wordpress_bootstrap.sh
touch $BASE_DIR/blog/scripts/wp_config_check.sh

chmod +x $BASE_DIR/blog/scripts/wordpress_bootstrap.sh
chmod +x $BASE_DIR/blog/scripts/wp_config_check.sh

echo "✅ BLOG folder structure created successfully!"
echo ""

echo "🚀 Creating 13 BLOG JIRA Branches..."

branches=(
"BLOG_DEPLOYMENT-Create_Security_Group"
"BLOG_DEPLOYMENT-Restore_database_from_snapshot"
"BLOG_DEPLOYMENT-Create_EFS"
"BLOG_DEPLOYMENT-Create_Target_Group"
"BLOG_DEPLOYMENT-Create_Load_Balancer"
"BLOG_DEPLOYMENT-Update_main_tf_with_Listener"
"BLOG_DEPLOYMENT-Create_Launch_Template"
"BLOG_DEPLOYMENT-Create_AutoScaling_Group"
"BLOG_DEPLOYMENT-Create_Key_Pair"
"BLOG_DEPLOYMENT-Ingest_domain_name_into_Terraform"
"BLOG_DEPLOYMENT-Provider_Role_Switch"
"BLOG_DEPLOYMENT-Parameter_Store_Script_Cronjob"
"BLOG_DEPLOYMENT-Final_Testing_and_Validation"
)

for branch in "${branches[@]}"
do
    git checkout -b "$branch"
    git push origin "$branch"
done

echo "✅ All BLOG branches created & pushed to GitHub!"

