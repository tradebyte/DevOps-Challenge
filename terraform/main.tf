module "vpc" {
  source = "./modules/vpc"
  vpc_Name = var.vpc_Name
  vpc_cidr_block = var.vpc_cidr_block
  public_subnets_cidr = var.public_subnets_cidr
  availability_Zones_subnet = var.availability_Zones_subnet
}
module "ec2" {
  source = "./modules/ec2"
  ec2_Name = var.ec2_Name
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  ami_id = var.ami_id
  key_Name = var.key_Name
  instance_type = var.instance_type
}