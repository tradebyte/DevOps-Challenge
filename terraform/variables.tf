variable "vpc_Name" {
    description = "Name of the VPC."
    type = string
}

variable "vpc_cidr_block" {
    description = "CIDR block for the VPC."
    type = string
}

variable "public_subnets_cidr" {
    description = "List of CIDR blocks for public subnets."
    type = list(string)
}

variable "availability_Zones_subnet" {
    description = "List of Availability Zones for subnets."
    type = list(string)
}

variable "ec2_Name" {
    description = "Name of the EC2 instance."
    type = list(string)
}

variable "ami_id" {
    description = "AMI ID for the EC2 instance."
    type = string
}

variable "instance_type" {
    description = "Type of EC2 instance."
    type = string
}

variable "key_Name" {
    description = "SSH key pair name for instance access."
    type = string
}

