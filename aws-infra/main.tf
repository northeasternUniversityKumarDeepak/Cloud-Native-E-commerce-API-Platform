module "mynetwork" {
  source = "./modules/networking"

  vpc_cidr_block         = var.vpc_cidr_block
  profile                = var.profile
  region                 = var.region
  public_subnets_cidr    = var.public_subnets_cidr
  private_subnets_cidr   = var.private_subnets_cidr
  availability_zones     = local.production_availability_zones
  destination_cidr_block = var.destination_cidr_block
  ami                    = var.ami
  port                   = var.port
  instance_type          = var.instance_type
  instance_vol_type      = var.instance_vol_type
  instance_vol_size      = var.instance_vol_size
  key_name               = var.key_name
  database_username      = var.database_username
  database_password      = var.database_password
  database_name          = var.database_name
  db_identifier          = var.db_identifier
  root_domain            = var.root_domain
  aws_account_number     = var.aws_account_number
}
locals {
  production_availability_zones = ["${var.region}a", "${var.region}b", "${var.region}c"]
}
