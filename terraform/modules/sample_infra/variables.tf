variable "project_name" {
  description = "Project identifier used in tags and names."
  type        = string
}

variable "environment" {
  description = "Environment name (dev or prod)."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name."
  type        = string
}

variable "force_destroy" {
  description = "Allow bucket deletion even when objects exist."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags to apply to resources."
  type        = map(string)
  default     = {}
}
