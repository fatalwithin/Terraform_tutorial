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

resource "aws_launch_configuration" "as_conf" { // launch config for autoscaling group
  // name            = ""
  name_prefix     = "web_config_highly_available_lc-" // left part of name with autoincrement
  image_id        = data.aws_ami.latest_amazon_linux.image_id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.my_webserver.id]
  user_data       = file("user_data.sh")

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name_prefix          = "asg-${aws_launch_configuration.as_conf.name}" // depends on launch config name
  launch_configuration = aws_launch_configuration.as_conf.name
  min_size             = 2
  max_size             = 2
  min_elb_capacity     = 2
  vpc_zone_identifier  = [aws_default_subnet.default_subnet_az1.id, aws_default_subnet.default_subnet_az2.id]
  health_check_type    = "ELB"
  load_balancers       = [aws_elb.web_lb.name]

  dynamic "tag" {
    for_each = {
      Name   = "Webserver_in_ASG"
      Owner  = "Overlord"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_elb" "web_lb" {
  name = "webserver_ha_elb"
  availability_zones = [data.aws_availability_zones.available.names[0],
  data.aws_availability_zones.available.names[1]]
  security_groups = [aws_security_group.my_webserver.id]
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"
  }
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }
  tags = {
    Name = "webserver_ha_elb"
  }
}

resource "aws_default_subnet" "default_subnet_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_default_subnet" "default_subnet_az2" {
  availability_zone = data.aws_availability_zones.available.names[1]
}
