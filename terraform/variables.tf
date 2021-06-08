resource "random_id" "random-string" {
  byte_length = 4
}

variable "user_id" {
  default = "sorin"
}

variable "aws_region" {
  default = "eu-west-1"
}

variable "aws_az" {
  default = "eu-west-1a"
}

variable "aws_az1" {
  default = "eu-west-1b"
}

variable "management_subnet_cidr" {
  description = "CIDR for the Management subnet"
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet"
  default     = "10.0.3.0/24"
}

variable "cluster-name" {
  default = "terraform-eks"
  type    = string
}

variable "key_name" {
  default = "NGINX"
  type    = string
}

variable "key_path" {
  default = "~/eks.key.pub"
  type    = string
}

resource "aws_key_pair" "main" {
  key_name   = "kp${var.key_name}-${random_id.random-string.dec}"
  public_key = file(var.key_path)
}

