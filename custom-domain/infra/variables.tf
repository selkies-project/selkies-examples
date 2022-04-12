variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "name" {
  default = "broker"
  type    = string
}

variable "region" {
  description = "GCP Region where the cluster is created"
  type        = string
}

variable "lb_domains" {
  description = "List of domains separated by commas, to create managed SSL certificates and configure in the Load Balancer"
  type        = string
  default     = null
}
variable "custom_domain" {
  description = "Custom domain for the App Launcher Portal"
  type        = string
  default     = null
}