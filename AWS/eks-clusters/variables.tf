#variable "profile" {
#  description = "AWS profile"
#  default = "your-aws-profile"
#  type        = string
#}

variable "region" {
  description = "AWS region to deploy to"
  default = "us-west-1"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones for the clusters"
  default = ["us-west-1a", "us-west-1b"]
  type  = list(string)
}

variable "cluster_name1" {
  description = "EKS cluster name"
#  default = "usandthem"
  type = string
}

#variable "cluster_name2" {
#  description = "EKS cluster name"
#  default = "alpha"
#  type = string
#}
