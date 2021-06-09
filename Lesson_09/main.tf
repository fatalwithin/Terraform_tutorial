#-------------------------------------------------------------------------------
# My Terraform 
#
# Find latest AMI ID of:
#   - Ubuntu 18.04
#   - Amazon Linux 2
#   - Windows Server 2016 Base
#-------------------------------------------------------------------------------

provider "aws" {
  region = "ca-central-1"
}

data "aws_ami" "latest_ubuntu" {
  most_recent      = true // most important
  executable_users = ["self"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["/ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  owners = ["self"]
}

data "aws_ami" "latest_amazon_linux" {
  most_recent      = true // most important
  executable_users = ["self"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  owners = ["self"]
}

data "aws_ami" "latest_windows_server_2016" {
  most_recent      = true // most important
  executable_users = ["self"]
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["Windows_Server-2016-English-Full-Base*"]
  }
  owners = ["self"]
}

output "latest_ubuntu_ami_id" {
  value = data.aws_ami.latest_ubuntu.id
}

output "latest_ubuntu_ami_name" {
  value = data.aws_ami.latest_ubuntu.name
}

output "latest_amazon_linux_ami_id" {
  value = data.aws_ami.latest_amazon_linux.id
}

output "latest_amazon_linux_ami_name" {
  value = data.aws_ami.latest_amazon_linux.name
}

output "latest_amazon_windows_server_id" {
  value = data.aws_ami.latest_windows_server_2016.id
}

output "latest_amazon_windows_server_name" {
  value = data.aws_ami.latest_windows_server_2016.name
}
