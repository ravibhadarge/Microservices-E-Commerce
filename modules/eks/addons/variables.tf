variable "cluster_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_issuer_url" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "addons" {
  type = object({
    ebs_csi = optional(object({
      enabled = optional(bool, true)
      version = optional(string, "v1.66.0-eksbuild.1")
    }), {})
  })
  default = {}
}
