variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "node_subnet_ids" {
  description = "Subnet IDs for the EKS node group"
  type        = list(string)
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS nodes"
  type        = string
  default     = "c7i-flex.large"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 4
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "addons" {
  description = "EKS add-on configuration"

  type = object({
    ebs_csi = optional(object({
      enabled = optional(bool, true)
      version = optional(string, "v1.66.0-eksbuild.1")
    }), {})
  })

  default = {}
}

#variable "cluster_name" {
#  description = "Name of the EKS cluster"
 # type        = string
#}

variable "environment" {
  description = "Environment name (dev/staging/production)"
  type        = string
  default     = "dev"
}
