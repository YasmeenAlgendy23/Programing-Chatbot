variable "aws_region" {
  default = "us-east-1"
}
variable "netid" {
  default = "25vrqw"
}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
variable "public_subnet_cidr_1" {
  default = "10.0.1.0/24"
}
variable "public_subnet_cidr_2" {
  default = "10.0.2.0/24"
}
variable "my_ip" {
  default = "0.0.0.0/0"
}
variable "enable_emr" {
  type    = bool
  default = false
}
variable "enable_ec2" {
  type    = bool
  default = false
}
variable "ec2_instance_type" {
  default = "t3.xlarge"
}