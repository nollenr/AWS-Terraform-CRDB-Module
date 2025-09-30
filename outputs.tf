# output "join_string" {
#   description = "the CockroachDB private IP join string"
#   value = local.join_string
# }

# output "join_string_public" {
#   description = "the CockroachDB public IP join string"
#   value = local.join_string_public
# }

# output "tls_private_key" {
#   description = "tls_private_key.crdb_ca_keys.private_key_pem -> ca.key / TLS Private Key PEM"
#   value = local.tls_private_key
#   sensitive = true
# }

# output "tls_public_key" {
#   description = "tls_private_key.crdb_ca_keys.public_key_pem -> ca.pub / TLS Public Key PEM"
#   value = local.tls_public_key
# }

# output "tls_cert" {
#   description = "tls_self_signed_cert.crdb_ca_cert.cert_pem -> ca.crt / TLS Cert PEM  /  Duplicate of tls_cert for better naming"
#   value = local.tls_cert
# }

# output "tls_user_cert" {
#   description = "tls_locally_signed_cert.user_cert.cert_pem -> client.name.crt"
#   value = local.tls_user_cert
# }

# output "tls_user_key" {
#   description = "tls_private_key.client_keys.private_key_pem -> client.name.key"
#   value = local.tls_user_key
#   sensitive = true
# }

# output "subnets" {
#   description = "Subnets"
#   value = local.subnet_list[*]
# }

# output "private_subnet_list" {
#   description = "private subnets"
#   value = local.private_subnet_list
# }

# output "public_subnet_list" {
#   description = "public subnets"
#   value = local.public_subnet_list
# }

# output "availability_zones" {
#   description = "availability zones"
#   value = data.aws_availability_zones.available.names
# }

# output "availability_zone_list" {
#   description = "availability zone list"
#   value = local.availability_zone_list
# }

# output "network_interfaces" {
#   description = "List of network interfaces"
#   value       = aws_network_interface.crdb[*].private_ip
# }


# output "vpc_id" {
#   description = "ID of the VPC created by the module"
#   value       = aws_vpc.main.id
# }

# output "route_table_public_id" {
#   description = "ID of the public route table"
#   value = aws_route_table.public_route_table.id
# }

# output "route_table_private_id" {
#   description = "ID of the private route table"
#   value = aws_route_table.private_route_table.id
# }

# output "security_group_intra_node_id" {
#   description = "ID of the security group allowing intra-node communication"
#   value = module.security-group-02.security_group_id
# }

# output "security_group_external_access_id" {
#   description = "ID of the security group allowing communication external to the VPC"
#   value = module.security-group-01.security_group_id
# }

output "haproxy_ip" {
  description = "HA Proxy Private IP"
  value       = aws_network_interface.haproxy[0].private_ip
}

output "app_node_public_ip" {
  description = "The public IP address of the app node, if created."
  value = var.include_app == "yes" && var.create_ec2_instances == "yes" ? (
    # If count is 1, access the first (and only) instance in the list
    aws_instance.app[0].public_ip
  ) : (
    # If count is 0, return null (or an empty string)
    null
  )
}

output "public_ips_by_az" {
  description = "CockroachDB Node public IPs assigned to interfaces by AZ."
  value       = crdb_public_ips_by_az
}

