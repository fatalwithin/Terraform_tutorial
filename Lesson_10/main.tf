#-------------------------------------------------------------------------------
# My Terraform 
#
# Provision highly-available website within any region in AWS Default VPC
# Create:
#   - security groups for web server
#   - launch config with Auto AMI lookup
#   - auto scaling group using 2 AZ
#   - classic load balancer in 2 AZ
#
#-------------------------------------------------------------------------------

provider "aws" {
  region = "ca-central-1"
}

data "aws_availability_zones" "available" {

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

resource "aws_security_group" "my_webserver" {
  name = "Dynamic Security Group"

  dynamic "ingress" {
    for_each = ["80", "443", "8080", "1541", "9092"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "WebServer built by Terraform"
    Owner = "Overlord"
  }
}

resource "aws_launch_configuration" "as_conf" {
  name            = "web_config_highly_available_lc"
  image_id        = data.aws_ami.latest_amazon_linux.image_id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.my_webserver.id]
  user_data       = file("user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}
