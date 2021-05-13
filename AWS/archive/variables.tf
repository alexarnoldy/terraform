# Input variable definitions

variable "vpc_name" {
  description = "Name of VPC"
  type        = string
  default     = "example-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_azs" {
  description = "Availability zones for VPC"
  type        = list(string)
  default     = ["us-west-1a", "us-west-1b", "us-west-1c"]
}

variable "vpc_private_subnets" {
  description = "Private subnets for VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "vpc_public_subnets" {
  description = "Public subnets for VPC"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "vpc_enable_nat_gateway" {
  description = "Enable NAT gateway for VPC"
  type        = bool
  default     = false
}

variable "vpc_tags" {
  description = "Tags to apply to resources created by VPC module"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
  }
}

#variable "instance_name_prefix" {
#  description = "Name prefix for instances"
#  type	      = string
#  default     = "my-ec2-cluster"
#}

variable "small_name_prefix" {
  description = "Name prefix for instances"
  type	      = string
  default     = "my-ec2-cluster"
}

variable "medium_name_prefix" {
  description = "Name prefix for instances"
  type	      = string
  default     = "my-ec2-cluster"
}

variable "instance_ami" {
  description = "AMI for the instance"
  type	      = string
  default     = "ami-05c558c169cfe8d99"
}
 
variable "instance_type" {
  description = "Type for the instance"
  type	      = string
  default     = "t2.micro"
}

variable "instance_type_map" {
  description	= "Map of AMIs and instance types to create"
  type		= map(string)
  default	= {
    instance-1	= "t2.small"
    instance-2	= "t2.medium"
    instance-3	= "t2.medium"
  }
}    
