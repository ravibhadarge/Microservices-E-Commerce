output "dockerhub_username" {
  description = "Docker Hub username"
  value       = var.dockerhub_username
}

output "repository_prefix" {
  description = "Prefix for Docker Hub repositories"
  value       = "${var.dockerhub_username}/ecommerce-${var.environment}"
}

output "service_repositories" {
  description = "Map of service names to Docker Hub repository URLs"
  value       = { for service in var.service_names : service => "${var.dockerhub_username}/ecommerce-${var.environment}-${service}" }
}
