variable "module_version" {
  default = "2.0.0"
}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "name" {
  default = "dev"
}

variable "public_subnet_cidrs" {
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}
#========================================================>
variable "aws_instance_count" {
  type    = list(string)
  default = ["one", "two"]
}
variable "disable_api_stop" {
  default = false
}
variable "disable_api_termination" {
  default = false
}
variable "ebs_optimized" {
  default = false
}
variable "get_password_data" {
  default = false
}
variable "hibernation" {
  default = false
}
variable "host_id" {
  default = ""
}
variable "host_resource_group_arn" {
  default = ""
}
variable "iam_instance_profile" {
  default = ""
}
variable "monitoring" {
  default = false
}
variable "tenancy" {
  default = "default"
}
variable "user_data" {
  default = ""
}
variable "ipv6_address_count" {
  default = 0
}

#========================================================>
variable "private_subnet_cidrs" {
  default = [
    "10.0.11.0/24",
    "10.0.22.0/24"
  ]
}

variable "ec2_instance_type" {
  type    = string
  default = "t2.micro"
}

data "aws_availability_zones" "available" {}
data "aws_ami" "latest_free_ami" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
