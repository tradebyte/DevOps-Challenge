
output "vpc_id" {
    value = aws_vpc.aws_vpc.id
}
output "public_subnet_ids" {
    description = "List with IDs of the public subnets"
    value = aws_subnet.public_subnet.*.id
}
