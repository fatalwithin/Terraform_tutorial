#-------------------------------------------------------------------------------
# My Terraform 
#
# Data sources - you can get a lot of information from them
# 
# How to know VPC ID knowing only its tag? And how to create new subnet in given
# cidr?
#-------------------------------------------------------------------------------
provider "aws" {

}

data "aws_availability_zones" "working" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {
  current = true
}
data "aws_vpcs" "available_vpcs" {}

data "aws_vpc" "selected_vpc" {
  tags = {
    "Name" = "prod"
  }

}

resource "aws_subnet" "prod_subnet_1" {
  vpc_id            = data.aws_vpc.selected_vpc.id
  availability_zone = data.aws_availability_zones.working.names[0]
  cidr_block        = "10.0.1.0/24"
  tags = {
    Name    = "Subnet 1 in ${data.aws_availability_zones.working.names[0]}"
    Account = "Subnet in Account ${data.aws_caller_identity.current.account_id}"
    Region  = data.aws_region.currnet.description
  }
}

resource "aws_subnet" "prod_subnet_2" {
  vpc_id            = data.aws_vpc.selected_vpc.id
  availability_zone = data.aws_availability_zones.working.names[1]
  cidr_block        = "10.0.2.0/24"
  tags = {
    Name    = "Subnet 2 in ${data.aws_availability_zones.working.names[0]}"
    Account = "Subnet in Account ${data.aws_caller_identity.current.account_id}"
    Region  = data.aws_region.currnet.description
  }
}

output "data_aws_availability_zones" {
  value = data.aws_availability_zones.working.names
}

output "account_id" {
  value = "${data.aws_caller_identity.current.account_id}"
}

output "data_aws_region_name" {
  value = data.aws_region.current.name
}

output "data_aws_region_description" {
  value = data.aws_region.current.description
}

output "aws_vpcs" {
  value = data.aws_vpcs.available_vpcs.ids
}

output "prod_vpc_id" {
  value = data.aws_vpc.selected_vpc.id
}

output "prod_vpc_cidr_block" {
  value = data.aws_vpc.selected_vpc.cidr_block
}
