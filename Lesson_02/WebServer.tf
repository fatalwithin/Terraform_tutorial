#-------------------------------------------------------------------------------
# My Terraform 
#
# Build Web server during bootstrap 
# Using in-line bash script
#
#-------------------------------------------------------------------------------

provider "aws" {
  access_key = "AWS ACCESS KEY"
  secret_key = "AWS SECRET KEY"
  region     = "eu-central-1"
}

resource "aws_instance" "my_webserver" {
  ami                    = "ami-w984750398457"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  user_data              = <<EOF
#!/bin/bash
yum -y update
yum -y install httpd
myip = `curl http://169.254.169.254/latest/meta-data/local-ipv4`
echo "<h2>WebServer with IP: $myip</h2><br>Build by Terraform!" > /var/www/html/index.html
sudo service httpd restart
chconfig httpd on

EOF

  tags = {
    Name  = "WebServer built by Terraform"
    Owner = "Overlord"
  }
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
