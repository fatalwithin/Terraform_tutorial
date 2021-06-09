provider "aws" {
    access_key = "lskajdhflkasjdhflkasjdhf"
    secret_key = "sdfasdflkashd;lfjkhasd"
    region = "eu-central-1"
}

resource "aws_instance" "my_Ubuntu" {
    count = 3
    ami = "ami-934598374958345"
    instance_type = "t3.micro"
}

resource "aws_instance" "my_Amazon" {
    ami = "ami-934598374958344"
    instance_type = "t3.micro"
}



