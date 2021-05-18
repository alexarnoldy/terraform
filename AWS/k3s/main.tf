# Terraform configuration

terraform {
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
#      version = "1.14.0"
    }
  }
}


provider "aws" {
  region = "us-west-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.21.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs             = var.vpc_azs
#  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = var.vpc_enable_nat_gateway

  tags = var.vpc_tags
}

module "ec2_instances" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.12.0"

  name           	= var.instance_name_prefix
  instance_count 	= var.instance_count
  ami                   = var.instance_ami
  instance_type         = var.instance_type
  key_name		= "aarnoldy_laptop"
#  key_name		= "rancher-server"
#  key_name		= aws_key_pair.aarnoldy_laptop.id
  vpc_security_group_ids = [aws_security_group.K3s_sg.id]
  subnet_id             = module.vpc.public_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

#resource "aws_key_pair" "aarnoldy_laptop" {
#  key_name   = var.ssh_authorized_keys
#  public_key = var.ssh_public_key
#}

resource "aws_security_group" "K3s_sg" {
  name        = "${var.instance_name_prefix}-sg"
  description = "Allow SSH K3s nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
#    cidr_blocks = var.my_public_ip
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}

#module "rancher_cluster" {
#  source = "./modules/rancher2"
#}

provider "rancher2" {
  alias      = "rancher-demo"
  api_url    = "https://rancher-demo.susealliances.com/v3"
}
resource "rancher2_cluster" "k3s-cluster-instance" {
  provider = "rancher2.rancher-demo"
  name = "k3s-${var.edge_location}"
  description = "K3s imported cluster"
  labels = var.cluster_labels
#  labels = tomap({"location" = "north", "customer" = "BigMoney"})
}

data "rancher2_cluster" "k3s-cluster" {
  provider = rancher2.rancher-demo
  name = "k3s-${var.edge_location}"
  depends_on = [rancher2_cluster.k3s-cluster-instance]
}

#module "website_s3_bucket" {
#  source = "./modules/aws-s3-static-website-bucket"
#
#  bucket_name = "aarnoldy-20210509"
#
#  tags = {
#    Terraform   = "true"
#    Environment = "dev"
#  }
#}
