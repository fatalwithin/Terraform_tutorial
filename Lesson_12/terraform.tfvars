# auto-fill parameters for DEV

/*
Files can be named as:
terraform.tfvars
prod.auto.tfvars
dev.auto.tfvars
*/

region                     = "ca-central-1"
instance_type              = "t2.micro"
enable_detailed_monitoring = false
allow_ports                = ["80", "443", "8080"]
common_tags = {
  Name        = "Server IP"
  Owner       = "Overlord"
  Project     = "Phoenix"
  CostCenter  = "1233565"
  Environment = "dev"
}
