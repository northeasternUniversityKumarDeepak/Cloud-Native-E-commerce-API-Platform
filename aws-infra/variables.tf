variable "profile" {
  description = "Profile for CLI"
}

variable "region" {
  description = "AWS region"
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
}

variable "public_subnets_cidr" {
  description = "Public subnets cidr"
}

variable "private_subnets_cidr" {
  description = "Private subnets cidr"
}

variable "destination_cidr_block" {
  description = "Destination public cidr"
}

variable "ami" {
  description = "AMI"
}

variable "instance_type" {
  description = "EC2 instance type"
}

variable "instance_vol_type" {
  description = "EC2 volume type"
}

variable "instance_vol_size" {
  description = "EC2 volume size"
}

variable "key_name" {
  description = "Name of ssh key"
}

variable "port" {
  description = "App port"
}
variable "database_username" {
  description = "The username of the database"
}

variable "database_password" {
  description = "The password of the database"
}
variable "database_name" {
  description = "The name of the database"
}

variable "db_identifier" {
  description = "The identifier of the database"
}

variable "root_domain" {
  description = "Root domain"
}

variable "aws_account_number" {
  description = "AWS account number"
}
