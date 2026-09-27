variable "cluster_name" {
  type = string
}

variable "cluster_endpoint" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_issuer_url" {
  type = string
}

variable "cluster_security_group_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "karpenter_version" {
  type    = string
  default = "1.12.1"
}
