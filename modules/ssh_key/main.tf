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
