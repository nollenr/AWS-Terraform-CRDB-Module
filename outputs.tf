output "join_string" {
  description = "the CockroachDB join string"
  value = local.join_string
}

output "subnets" {
  description = "Subnets"
  value = local.subnet_list[*]
}

output "private_subnet_list" {
  description = "private subnets"
  value = local.private_subnet_list
}

output "public_subnet_list" {
  description = "public subnets"
  value = local.public_subnet_list
}

output "availability_zones" {
  description = "availability zones"
  value = data.aws_availability_zones.available.names
}

output "availability_zone_list" {
  description = "availability zone list"
  value = local.availability_zone_list
}

output "network_interfaces" {
  description = "List of network interfaces"
  value       = aws_network_interface.crdb[*].private_ip
}

output "haproxy_ip" {
  description = "HA Proxy Private IP"
  value       = aws_network_interface.haproxy[0].private_ip
}

output "vpc_id" {
  description = "ID of the VPC created by the module"
  value       = aws_vpc.main.id
}

output "route_table_public_id" {
  description = "ID of the public route table"
  value = aws_route_table.public_route_table.id
}

output "route_table_private_id" {
  description = "ID of the private route table"
  value = aws_route_table.private_route_table.id
}
