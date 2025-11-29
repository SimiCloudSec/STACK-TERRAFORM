#!/bin/bash

echo "🚀 Creating 13 CLIXX JIRA Branches..."

branches=(
"CLIX_DEPLOYMENT-Create_Security_Group"
"CLIX_DEPLOYMENT-Restore_database_from_snapshot"
"CLIX_DEPLOYMENT-Create_EFS"
"CLIX_DEPLOYMENT-Create_Target_Group"
"CLIX_DEPLOYMENT-Create_A_Load_Balancer"
"CLIX_DEPLOYMENT-Update_main_tf_with_Listener"
"CLIX_DEPLOYMENT-Create_Launch_Template"
"CLIX_DEPLOYMENT-Create_AutoScaling_Group"
"CLIX_DEPLOYMENT-Create_Key_Pair"
"CLIX_DEPLOYMENT-Ingest_domain_name_into_Terraform"
"CLIX_DEPLOYMENT-Provider_Role_Switch"
"CLIX_DEPLOYMENT-Parameter_Store_Script_Cronjob"
"CLIX_DEPLOYMENT-Final_Testing_and_Validation"
)

for branch in "${branches[@]}"
do
    git checkout -b "$branch"
    git push origin "$branch"
done

echo "✅ All CLIXX branches created & pushed to GitHub successfully!"

