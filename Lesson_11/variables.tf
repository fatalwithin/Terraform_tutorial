variable "region" {
  description = "Please enter AWS region where server should be deployed"
  type        = string
  default     = "ca-central-1"
}

variable "instance_type" {
  description = "Enter server instance type"
  type        = string
  default     = "t3.micro"
}

variable "allow_ports" {
  description = "List of ports to open"
  type        = list
  default     = ["80", "443", "8080", "22"]
}

variable "enable_detailed_monitoring" {
  description = "Enabled server monitoring"
  type        = boolean
  default     = true

}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map

  default = {
    Name        = "Server IP"
    Owner       = "Overlord"
    Project     = "Phoenix"
    CostCenter  = "1233565"
    Environment = "dev"
  }
}
