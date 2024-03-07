variable "env" {}
variable "domain" {}
variable "az_count" {}
variable "vpc_cidr" {}
variable "db_user_password" {}
variable "db_user_name" {}
variable "project_name" {}
variable "volume_size" {}
variable "instance_type" {}
variable "instance_types" {}
variable "my_custom_ami" {}
variable "max_size" {}
variable "min_size" {}
variable "desired_capacity" {}
variable "github_token" {}

variable "ami_owners" {
  default = ["099720109477"]
}
variable "ami_regex" {
  default = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
}
