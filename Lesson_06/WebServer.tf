#-------------------------------------------------------------------------------
# My Terraform 
#
# Build Web server during bootstrap 
# Implementing lifecycle
#
#-------------------------------------------------------------------------------

provider "aws" {
  access_key = "AWS ACCESS KEY"
  secret_key = "AWS SECRET KEY"
  region     = "eu-central-1"
}

resource "aws_eip" "my_static_ip" {
  instance = aws_instance.my_webserver.id
}

resource "aws_instance" "my_webserver" {
  ami                    = "ami-w984750398457"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  user_data = templatefile("user_data.sh.tpl", {
    f_name = "Overlord",
    l_name = "Of the Universe",
    names  = ["John", "Johnnie", "Jack", "Ronald", "Donald"]
  })
  //using external file with templates

  tags = {
    Name  = "WebServer built by Terraform"
    Owner = "Overlord"
  }
}

// lifecycle control
lifecycle {
  prevent_destroy       = true
  ignore_changes        = ["ami", "user_data"] // parameters for which changes are ignored
  create_before_destroy = true                 // do not delete old instance of the resource until the new one creates
}

resource "aws_security_group" "my_webserver" {
  name        = "webserver security group"
  description = "webserver security group"
  vpc_id      = aws_vpc.main.id // creates in default VPC if not set

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

