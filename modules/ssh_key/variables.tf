variable "key_name_prefix" {
  description = "Prefix for the SSH key name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
