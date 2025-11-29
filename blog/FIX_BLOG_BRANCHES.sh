#!/bin/bash

# Each branch gets a meaningful commit message that matches its purpose
declare -A BRANCH_MESSAGES=(
    ["BLOG_DEPLOYMENT-Create_Security_Group"]="Add security group module for ALB, EC2, RDS, and EFS"
    ["BLOG_DEPLOYMENT-Create_Target_Group"]="Add target group module for ALB health checks"
    ["BLOG_DEPLOYMENT-Create_Load_Balancer"]="Add application load balancer module"
    ["BLOG_DEPLOYMENT-Create_EFS"]="Add EFS module for shared WordPress storage"
    ["BLOG_DEPLOYMENT-Create_Key_Pair"]="Add EC2 key pair module for SSH access"
    ["BLOG_DEPLOYMENT-Create_Launch_Template"]="Add launch template module with user data bootstrap"
    ["BLOG_DEPLOYMENT-Create_AutoScaling_Group"]="Add auto scaling group module for high availability"
    ["BLOG_DEPLOYMENT-Update_main_tf_with_Listener"]="Add ALB listener configuration to main.tf"
    ["BLOG_DEPLOYMENT-Provider_Role_Switch"]="Add provider configuration for AWS account access"
    ["BLOG_DEPLOYMENT-Restore_database_from_snapshot"]="Add RDS module with snapshot restore capability"
    ["BLOG_DEPLOYMENT-Ingest_domain_name_into_Terraform"]="Add Route53 module for domain management"
    ["BLOG_DEPLOYMENT-Parameter_Store_Script_Cronjob"]="Add parameter store configuration for secrets"
    ["BLOG_DEPLOYMENT-Final_Testing_and_Validation"]="Add final configuration and validation checks"
)

echo ""
echo "=== FIXING BLOG BRANCH COMMITS ==="
echo ""

for branch in "${!BRANCH_MESSAGES[@]}"; do
    echo "----------------------------------------"
    echo "Processing: $branch"
    
    git checkout "$branch" 2>/dev/null || continue
    
    # Reset the last commit
    git reset --soft HEAD~1
    
    # Create new commit with meaningful message
    git add -A
    git commit -m "${BRANCH_MESSAGES[$branch]}"
    
    # Force push to overwrite
    git push --force
    
    echo "   ✅ Fixed: ${BRANCH_MESSAGES[$branch]}"
done

git checkout dev

echo ""
echo "=== ALL BLOG BRANCHES FIXED ==="
