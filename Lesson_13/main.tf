#-------------------------------------------------------------------------------
# My Terraform 
#
# Local variables
#
#-------------------------------------------------------------------------------

provider "aws" {
  region = var.region
}

data "aws_region" "current" {

}
data "aws_availability_zone" "available" {

}

locals { //combined variables
  full_project_name = "${var.environment}-${var.project_name}"
  project_owner     = "${var.owner} owner of ${var.project_name}"
  country           = "Canada"
  city              = "Deadmonton"
  az_list           = join(",", data.aws_availability_zone.available.names)
}

resource "aws_eip" "my_static_ip" {
  tags = {
    Name       = "Static IP"
    Owner      = "Overlord"
    Project    = local.full_project_name
    Owner      = local.owner
    City       = local.city
    region_azs = local.az_list
  }
}
