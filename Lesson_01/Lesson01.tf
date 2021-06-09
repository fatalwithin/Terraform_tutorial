provider "aws" {
  access_key = "lskajdhflkasjdhflkasjdhf"
  secret_key = "sdfasdflkashd;lfjkhasd"
  region     = "eu-central-1"
}

resource "aws_instance" "my_Ubuntu" {
  count         = 3                     // count of instances
  ami           = "ami-934598374958345" //image
  instance_type = "t3.micro"            //flavour

  tags = {
    Name    = "My Ubuntu Server"
    Owner   = "Overlord"
    Project = "AWS Lessons"
  }
}

resource "aws_instance" "my_Amazon_Linux" {
  ami           = "ami-934598374958344"
  instance_type = "t3.micro"

  tags = {
    Name    = "My AWS Server"
    Owner   = "Overlord"
    Project = "AWS Lessons"
  }
}

// aws instance snippet
data "aws_instance" "foo" {
  instance_id = "i-instanceid"

  filter {
    name   = "image-id"
    values = ["ami-xxxxxxxx"]
  }

  filter {
    name   = "tag:Name"
    values = ["instance-name-tag"]
  }
}



/*
terraform init - checking syntax, plugins, downloads plugins

terraform plan - creates an execution plan - "what-if", shows applicable changes

terraform apply - execs an execution plan, creates terraform.tfstate

terraform destroy - deletes all resources

terraform show - output of .tfstate - what can be shown in output section
*/
