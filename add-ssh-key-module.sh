#!/bin/bash
# Update all environments to use auto-generated SSH key
# Run from terraform-restructured/ directory

set -e

echo "Updating environments to use auto-generated SSH key..."

# Create SSH key module directory
mkdir -p modules/ssh_key

# Write SSH key module - main.tf
cat > modules/ssh_key/main.tf << 'EOF'
# Generate a new SSH key pair for the project
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair from generated public key
resource "aws_key_pair" "this" {
  key_name_prefix = var.key_name_prefix
  public_key      = tls_private_key.this.public_key_openssh

  tags = merge(var.tags, {
    Name = "${var.key_name_prefix}-key"
  })
}

# Save private key to local file (optional, for user convenience)
resource "local_file" "private_key" {
  content         = tls_private_key.this.private_key_pem
  filename        = "${path.root}/${var.key_name_prefix}-key.pem"
  file_permission = "0400"
}
EOF

# Write SSH key module - variables.tf
cat > modules/ssh_key/variables.tf << 'EOF'
variable "key_name_prefix" {
  description = "Prefix for the SSH key name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
EOF

# Write SSH key module - outputs.tf
cat > modules/ssh_key/outputs.tf << 'EOF'
output "key_name" {
  description = "Name of the AWS key pair"
  value       = aws_key_pair.this.key_name
}

output "private_key_pem" {
  description = "Private key in PEM format (sensitive)"
  value       = tls_private_key.this.private_key_pem
  sensitive   = true
}

output "public_key_openssh" {
  description = "Public key in OpenSSH format"
  value       = tls_private_key.this.public_key_openssh
}

output "private_key_file" {
  description = "Path to the generated private key file"
  value       = local_file.private_key.filename
}
EOF

# Function to update environment main.tf
update_env_main_tf() {
    local env=$1
    local main_file="environments/${env}/main.tf"

    if [ ! -f "$main_file" ]; then
        echo "Warning: $main_file not found, skipping..."
        return
    fi

    # Check if ssh_key module already exists
    if grep -q "module \"ssh_key\"" "$main_file"; then
        echo "SSH key module already exists in ${env}, skipping..."
        return
    fi

    # Add ssh_key module after the vpc module block
    awk '
    /module "vpc"/ { in_vpc=1 }
    in_vpc && /^}/ { 
        print
        print ""
        print "module \"ssh_key\" {"
        print "  source          = \"../../modules/ssh_key\""
        print "  key_name_prefix = local.name_prefix"
        print "  tags            = local.common_tags"
        print "}"
        in_vpc=0
        next
    }
    { print }
    ' "$main_file" > "${main_file}.tmp" && mv "${main_file}.tmp" "$main_file"

    echo "Updated ${main_file} with SSH key module"
}

# Function to update jumphost module call
update_jumphost_call() {
    local env=$1
    local main_file="environments/${env}/main.tf"

    if [ ! -f "$main_file" ]; then
        return
    fi

    # Update key_name to use the generated key
    if grep -q 'key_name.*=.*"pc"' "$main_file"; then
        sed -i 's/key_name.*=.*"pc"/key_name = module.ssh_key.key_name/' "$main_file"
        echo "Updated jumphost key_name in ${env}"
    fi
}

# Function to update outputs.tf
update_outputs() {
    local env=$1
    local outputs_file="environments/${env}/outputs.tf"

    if [ ! -f "$outputs_file" ]; then
        return
    fi

    # Check if ssh outputs already exist
    if grep -q "SSH Key" "$outputs_file"; then
        echo "SSH outputs already exist in ${env}, skipping..."
        return
    fi

    cat >> "$outputs_file" << 'EOF'

# SSH Key Outputs
output "ssh_key_name" {
  description = "Name of the generated SSH key pair"
  value       = module.ssh_key.key_name
}

output "ssh_private_key_file" {
  description = "Path to the generated private key file"
  value       = module.ssh_key.private_key_file
}

output "ssh_command" {
  description = "SSH command to connect to jumphost"
  value       = "ssh -i ${module.ssh_key.private_key_file} ec2-user@${module.jumphost.public_ip}"
}
EOF
    echo "Updated ${outputs_file} with SSH outputs"
}

# Update all environments
for env in dev staging production; do
    echo ""
    echo "=== Processing environment: ${env} ==="
    update_env_main_tf "$env"
    update_jumphost_call "$env"
    update_outputs "$env"
done

echo ""
echo "======================================"
echo "   SSH KEY MODULE SETUP COMPLETE"
echo "======================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Initialize Terraform in each environment:"
echo "   cd environments/dev"
echo "   terraform init"
echo ""
echo "2. Run plan to see the new SSH key:"
echo "   terraform plan"
echo ""
echo "3. Apply to create the key:"
echo "   terraform apply"
echo ""
echo "4. After apply, the private key will be saved as:"
echo "   environments/dev/<env>-key.pem"
echo ""
echo "5. SSH to the jumphost:"
echo "   ssh -i environments/dev/dev-key.pem ec2-user@<jumphost-ip>"
echo ""
echo "Note: You can also get the SSH command from terraform output:"
echo "   terraform output ssh_command"
