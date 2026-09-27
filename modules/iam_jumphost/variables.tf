variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "enable_admin_access" {
  description = "Enable AdministratorAccess policy (dev only)"
  type        = bool
  default     = false
}

variable "additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
