variable "dockerhub_username" {
  description = "Docker Hub username"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "service_names" {
  description = "List of microservice names"
  type        = list(string)
}
