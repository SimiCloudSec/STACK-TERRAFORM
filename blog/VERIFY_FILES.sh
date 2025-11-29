#!/bin/bash

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║   VERIFYING ALL TERRAFORM FILES ARE CORRECT                  ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0

# Check terraform.tfvars
echo "=== Checking terraform.tfvars ==="

if grep -q 'db_name.*=.*"wordpress_db"' terraform.tfvars; then
    echo "✅ db_name = wordpress_db"
else
    echo "❌ db_name is WRONG"
    ERRORS=$((ERRORS+1))
fi

if grep -q 'db_password.*=.*"Alienpython123"' terraform.tfvars; then
    echo "✅ db_password = Alienpython123"
else
    echo "❌ db_password is WRONG"
    ERRORS=$((ERRORS+1))
fi

if grep -q 'hosted_zone_id.*=.*"Z069777410G7QIT8P199L"' terraform.tfvars; then
    echo "✅ hosted_zone_id = Z069777410G7QIT8P199L"
else
    echo "❌ hosted_zone_id is WRONG"
    ERRORS=$((ERRORS+1))
fi

if grep -q 'environment.*=.*"dev"' terraform.tfvars; then
    echo "✅ environment = dev"
else
    echo "❌ environment is WRONG"
    ERRORS=$((ERRORS+1))
fi

echo ""
echo "=== Checking bootstrap script ==="

if grep -q 'DB_NAME="wordpress_db"' scripts/blog_bootstrap.sh; then
    echo "✅ DB_NAME = wordpress_db"
else
    echo "❌ DB_NAME is WRONG"
    ERRORS=$((ERRORS+1))
fi

if grep -q 'mariadb105' scripts/blog_bootstrap.sh; then
    echo "✅ Using mariadb105 (correct for ARM)"
else
    echo "❌ mysql package is WRONG (should be mariadb105)"
    ERRORS=$((ERRORS+1))
fi

if grep -q 'mysql -h.*wordpress_db' scripts/blog_bootstrap.sh; then
    echo "✅ MySQL command uses wordpress_db"
else
    echo "❌ MySQL command uses wrong database"
    ERRORS=$((ERRORS+1))
fi

if grep -q 'UPDATE wp_options' scripts/blog_bootstrap.sh; then
    echo "✅ URL fix included in bootstrap"
else
    echo "❌ URL fix MISSING from bootstrap"
    ERRORS=$((ERRORS+1))
fi

if grep -q 'site_url' scripts/blog_bootstrap.sh; then
    echo "✅ site_url variable present"
else
    echo "❌ site_url variable MISSING"
    ERRORS=$((ERRORS+1))
fi

echo ""
echo "=== Checking modules/lt/main.tf ==="

if grep -q 'site_url' modules/lt/main.tf; then
    echo "✅ Launch template passes site_url"
else
    echo "❌ Launch template MISSING site_url"
    ERRORS=$((ERRORS+1))
fi

echo ""
echo "=== Checking modules/rds/main.tf ==="

if grep -q 'storage_encrypted.*=.*true' modules/rds/main.tf; then
    echo "✅ RDS storage_encrypted = true"
else
    echo "❌ RDS storage_encrypted MISSING"
    ERRORS=$((ERRORS+1))
fi

if grep -q 'ignore_changes' modules/rds/main.tf; then
    echo "✅ RDS lifecycle ignore_changes present"
else
    echo "❌ RDS lifecycle ignore_changes MISSING"
    ERRORS=$((ERRORS+1))
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
if [ $ERRORS -eq 0 ]; then
    echo "║   ✅ ALL CHECKS PASSED! Ready for terraform apply           ║"
else
    echo "║   ❌ $ERRORS ERROR(S) FOUND! Fix before running terraform     ║"
fi
echo "╚═══════════════════════════════════════════════════════════════╝"
