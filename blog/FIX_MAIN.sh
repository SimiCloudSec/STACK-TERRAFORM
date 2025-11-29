#!/bin/bash

# Fix main.tf - remove subdomain line
sed -i '/subdomain/d' main.tf 2>/dev/null || true

# Also remove from variables.tf if it exists
sed -i '/variable "subdomain"/,/^}/d' variables.tf 2>/dev/null || true

# Remove from terraform.tfvars if it exists
sed -i '/subdomain/d' terraform.tfvars 2>/dev/null || true

echo "✅ Fixed! Run: terraform plan"
