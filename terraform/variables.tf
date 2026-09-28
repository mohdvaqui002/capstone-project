variable "aws_region" {
  description = "AWS region for this lab."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "capstone-devops"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.project_name))
    error_message = "Use 3-31 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "admin_cidr" {
  description = "Your public IPv4 address followed by /32; permits SSH, Jenkins, Kubernetes API and the demo website."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.admin_cidr)) && can(regex("/32$", var.admin_cidr))
    error_message = "Supply a valid IPv4 /32, for example 203.0.113.10/32."
  }
}

variable "key_name" {
  description = "Existing EC2 key pair in the selected region. You must possess its private key."
  type        = string
}

variable "instance_type" {
  description = "x86_64 instance type for all four lab servers. t3.small provides 2 vCPU / 2 GiB."
  type        = string
  default     = "t3.small"
}

variable "ami_id" {
  description = "Optional pinned Ubuntu 24.04 amd64 AMI; null selects the latest Canonical image."
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Encrypted gp3 root disk size per server, in GiB."
  type        = number
  default     = 30
  validation {
    condition     = var.root_volume_size >= 20 && var.root_volume_size <= 100 && floor(var.root_volume_size) == var.root_volume_size
    error_message = "Choose a whole number between 20 and 100 GiB."
  }
}
