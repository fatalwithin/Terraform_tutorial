variable "aws_region" {
  description = "Please enter AWS region where app resources should be deployed"
  type        = string
  default     = "ca-central-1"
}

variable "aws_resource_prefix" {
  description = "Prefix to be used in the naming of some of the created AWS resources e.g. demo-webapp"
}

variable "aws_access_key" {
  description = "Please enter AWS Access key"
  type        = string
}

variable "aws_secret_key" {
  description = "Please enter AWS Secret key"
  type        = string
}

variable "aws_account_id" {}

# Application variables
variable "allow_ports" {
  description = "List of ports to open"
  type        = list
  default     = ["80", "443", "8080", "22"]
}

# Common variables
variable "common_tags" {
  description = "Common tags for all resources"
  type        = map

  default = {
    Owner       = "Andrey Strelnikov"
    Project     = "devops-test"
    CostCenter  = "Free Tier"
    Environment = "dev"
  }
}
