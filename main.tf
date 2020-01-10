provider "aws" {
  region = "us-west-1"
}

variable "server_port" {
  description = "The port to be applied to the security group"
  type = number
  default = 22
}

resource "aws_vpc" "aarnoldy" {
  cidr_block = "10.10.0.0/16"

  tags = {
    Name = "aarnoldy"
  }
}

resource "aws_subnet" "aarnoldy" {
  vpc_id            = "${aws_vpc.aarnoldy.id}"
  cidr_block        = "10.10.10.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "aarnoldy"
  }
}

resource "aws_network_interface" "aarnoldy" {
  subnet_id = "${aws_subnet.aarnoldy.id}"
  private_ips = ["10.10.10.10"]
  security_groups = ["${aws_security_group.aarnoldy_security_group.id}"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "example" {
  ami = "ami-03ae0350e0478db29"
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = "${aws_network_interface.aarnoldy.id}"
    device_index = 0
  }


  tags = {
    Name = "aarnoldy-instance"
  }

}

resource "aws_security_group" "aarnoldy_security_group" {
  name = "terraform_security_group"
  vpc_id = "${aws_vpc.aarnoldy.id}"

  ingress {
    from_port = var.server_port
    to_port   = var.server_port
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "aarnoldy_SG"
}
}

output "public_ip" {
  value = aws_instance.example.public_ip
  description = "The public IP of the server"
}
