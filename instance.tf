# CRDB Nodes
resource "aws_instance" "crdb" {
  count         = var.create_ec2_instances == "yes" ? var.crdb_nodes : 0
  user_data_replace_on_change = true
  tags = merge(local.tags, {Name = "${var.owner}-crdb-instance-${count.index}"})
  ami           = local.ami_id
  instance_type = var.crdb_instance_type
  network_interface {
    # network_interface_id = data.aws_network_interface.details[count.index].id
    network_interface_id = aws_network_interface.crdb[count.index].id
    device_index = 0
  }
  key_name      = var.crdb_instance_key_name
  root_block_device {
    delete_on_termination = true
    encrypted = true
    volume_type = var.crdb_root_volume_type
    volume_size = var.crdb_root_volume_size
  }
  dynamic ebs_block_device {   #  changing this to count so that the volume is created only if we're adding WAL failover.   # Adding variable to tfvarws
    for_each = var.crdb_wal_failover == "yes" ? [1] : []
    content {
      device_name = "/dev/sdf"
      delete_on_termination = true
      encrypted = true
      volume_type = "gp3"
      volume_size = "25"
      tags = merge(local.tags, {Name = "crdb-data", Role = "wal"})
    }
  }

  ebs_block_device {
    device_name = "/dev/sdg"
    delete_on_termination = true
    encrypted = true
    volume_type = var.crdb_store_volume_type
    volume_size = var.crdb_store_volume_size
    iops       = var.crdb_store_volume_type == "gp3" ? var.crdb_store_volume_iops : null
    throughput = var.crdb_store_volume_type == "gp3" ? var.crdb_store_volume_throughput : null
    tags = merge(local.tags, {Name = "crdb-data", Role = "data"})
  }
  user_data = join("\n", [
    "#!/bin/bash -xe",
    templatefile("${path.module}/scripts/initialize_disks_by_order.sh", {
      wal_failover = var.crdb_wal_failover,}),
    templatefile("${path.module}/scripts/setting_required_variables.sh", {
      ip_local=local.interface_map[aws_network_interface.crdb[count.index].id].private_ip, 
      aws_region=local.subnet_map[local.interface_map[aws_network_interface.crdb[count.index].id].subnet_id].region,
      aws_az=local.subnet_map[local.interface_map[aws_network_interface.crdb[count.index].id].subnet_id].availability_zone,
      cluster_private_ip_list=local.ip_list,
      crdbnode=count.index,
      join_string=local.join_string,}),
    templatefile("${path.module}/scripts/download_and_install_cockroach.sh", {
      crdb_arm_release_yn=var.crdb_arm_release, 
      crdb_version=var.crdb_version,}),
    templatefile("${path.module}/scripts/create_public_and_private_keys.sh", {
      tls_private_key=local.tls_private_key, 
      tls_public_key=local.tls_public_key,
      tls_cert=local.tls_cert,}),
    templatefile("${path.module}/scripts/create_systemd_service_file.sh", {
      is_single_node     = var.crdb_nodes == 1 ? "true" : "false",
      region=local.subnet_map[local.interface_map[aws_network_interface.crdb[count.index].id].subnet_id].region, 
      availability_zone=local.subnet_map[local.interface_map[aws_network_interface.crdb[count.index].id].subnet_id].availability_zone,
      advertise_address=local.interface_map[aws_network_interface.crdb[count.index].id].private_ip,
      join_string=local.join_string,
      wal_failover = var.crdb_wal_failover,}),    
    templatefile("${path.module}/scripts/wal_failover_diagnostic_logging_config.sh", {
      wal_failover = var.crdb_wal_failover,}),
    templatefile("${path.module}/scripts/create_cert_functions.sh", {
      include_ha_proxy    = var.include_ha_proxy,
      ha_proxy_private_ip = aws_network_interface.haproxy[0].private_ip}),
    file("${path.module}/scripts/create_crdb_control_functions.sh"),
    file("${path.module}/scripts/create_certs_and_start_crdb.sh"),
    templatefile("${path.module}/scripts/init_and_licensing.sh", {
      run_init    = var.run_init,
      index = count.index,
      crdb_nodes = var.crdb_nodes,
      create_admin_user = var.create_admin_user,
      admin_user_name = var.admin_user_name,
      install_enterprise_keys = var.install_enterprise_keys,
      cluster_organization = var.cluster_organization,
      enterprise_license = var.enterprise_license,}),
  ])
}

    # if [[ '${var.run_init}' = 'yes' && ${count.index + 1} -eq ${var.crdb_nodes} && ${var.install_enterprise_keys} = 'yes' ]]; then echo "Installing enterprise license keys" && su ec2-user -lc 'cockroach sql --execute "SET CLUSTER SETTING cluster.organization = '${var.cluster_organization}'; SET CLUSTER SETTING enterprise.license = '${var.enterprise_license}'"'; fi

