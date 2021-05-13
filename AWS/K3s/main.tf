# Terraform configuration

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
  key_name		= aws_key_pair.aarnoldy_laptop.id
  vpc_security_group_ids = [aws_security_group.K3s_sg.id]
  subnet_id             = module.vpc.public_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_key_pair" "aarnoldy_laptop" {
  key_name   = "aarnoldy_laptop"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDXxkzrWJBzUnAxPX0ze+dzrCb0WMkpqQmGUnTqclrVFoPWduzr4W4KVUl1v7DTIrc0ccYHiWdKnrYvhst5E/szJTalKJjgEI6vtCDX/gN1VYOhCe9Qgxp1hSfNGNDSFOp2di1+N0A/XXlkkFqmz7B0d/ibgHnv+h+9vniKmXs7SW2GuuvpRoBaL38N4fkC5GHmLeIuPuwPCG2OVOHpAixr2obYm5QCl0n4mM77QlDpLtgh8ZD3xmOY1sRCGDvqafbZ0CuGfloApTBxxupDrU/XyLfXDNZR7wrxzw3Gom+oZR1pfKwXW/ym3/ko/Gfsex8AOTwPLFiaGynkT6OWgfnV aarnoldy@aarnoldy-laptop"
}

resource "aws_security_group" "K3s_sg" {
  name        = "${var.instance_name_prefix}-sg"
  description = "Allow SSH K3s nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
#    cidr_blocks = [data.aws_vpc.vpc.cidr_block}]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


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
