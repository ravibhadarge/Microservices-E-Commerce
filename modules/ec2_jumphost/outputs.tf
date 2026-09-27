output "instance_id" {
  description = "ID of the jumphost instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP of the jumphost"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP of the jumphost"
  value       = aws_instance.this.private_ip
}

output "security_group_id" {
  description = "ID of the jumphost security group"
  value       = aws_security_group.jumphost.id
}
