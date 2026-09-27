output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "jumphost_public_ip" {
  description = "Public IP of the jumphost"
  value       = module.jumphost.public_ip
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "dockerhub_repositories" {
  description = "Docker Hub repositories for services"
  value       = module.dockerhub.service_repositories
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_name
}

output "ssh_command" {
  description = "SSH command to connect to jumphost"
  value       = "ssh -i ~/pc.pem ec2-user@${module.jumphost.public_ip}"
}
