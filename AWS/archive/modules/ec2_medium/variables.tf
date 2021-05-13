variable "instance_ami" {
  description = "AMI for the instance"
  type        = string
  default     = "ami-05c558c169cfe8d99"
}

variable "instance_type" {
  description = "Type for the instance"
  type        = string
  default     = "t2.micro"
}

