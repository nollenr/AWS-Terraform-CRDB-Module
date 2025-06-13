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
  ebs_block_device {
    device_name = "/dev/sds"
    delete_on_termination = true
    encrypted = true
    volume_type = var.crdb_store_volume_type
    volume_size = var.crdb_store_volume_size
    iops       = var.crdb_store_volume_type == "gp3" ? var.crdb_store_volume_iops : null
    throughput = var.crdb_store_volume_type == "gp3" ? var.crdb_store_volume_throughput : null
  }
  user_data = <<EOF
#!/bin/bash -xe
# Prepare, Mount, and Add a Disk to fstab (with XFS formatting and disk check)
# 1. Set disk information 
export DISK_NAME="/dev/nvme1n1"
export MOUNT_POINT="/mnt/crdb-data"
#4.  
echo "Formatting $DISK_NAME with XFS..."
mkfs -t xfs "$DISK_NAME"
if [ $? -ne 0 ]; then
echo "Error: Failed to format $DISK_NAME."
exit 1
else
echo "Disk $DISK_NAME successfully formatted with XFS."
fi
# 5. Create mount point if it doesn't exist
if [ ! -d "$MOUNT_POINT" ]; then
echo "Creating mount point $MOUNT_POINT..."
mkdir -p "$MOUNT_POINT"
if [ $? -ne 0 ]; then
echo "Error: Failed to create mount point $MOUNT_POINT."
exit 1
fi
fi
# 6. Mount the partition and change permissions
echo "Mounting $DISK_NAME to $MOUNT_POINT..."
mount "$DISK_NAME" "$MOUNT_POINT"
if [ $? -ne 0 ]; then
echo "Error: Failed to mount $DISK_NAME to $MOUNT_POINT."
exit 1
fi
sudo chown ec2-user:ec2-user "$MOUNT_POINT"
# 7. Get UUID of the partition
UUID=$(blkid -s UUID -o value "$DISK_NAME")
# 8. Add entry to fstab (with XFS)
echo "Adding entry to /etc/fstab..."
echo "UUID=$UUID $MOUNT_POINT xfs defaults,nofail 0 2" | tee -a /etc/fstab
echo "Disk $DISK_NAME (partition $DISK_NAME) successfully prepared, mounted to $MOUNT_POINT, and added to fstab."

echo "Setting variables"
echo "export COCKROACH_CERTS_DIR=/home/ec2-user/certs" >> /home/ec2-user/.bashrc
echo 'export CLUSTER_PRIVATE_IP_LIST="${local.ip_list}" ' >> /home/ec2-user/.bashrc
echo 'export JOIN_STRING="${local.join_string}" ' >> /home/ec2-user/.bashrc
echo "export ip_local=${local.interface_map[aws_network_interface.crdb[count.index].id].private_ip}" >> /home/ec2-user/.bashrc
echo "export aws_region=${local.subnet_map[local.interface_map[aws_network_interface.crdb[count.index].id].subnet_id].region}" >> /home/ec2-user/.bashrc
echo "export aws_az=${local.subnet_map[local.interface_map[aws_network_interface.crdb[count.index].id].subnet_id].availability_zone}" >> /home/ec2-user/.bashrc
export CLUSTER_PRIVATE_IP_LIST="${local.ip_list}"
echo "export CRDBNODE=${count.index}" >> /home/ec2-user/.bashrc
export CRDBNODE=${count.index}
counter=1;for IP in $CLUSTER_PRIVATE_IP_LIST; do echo "export NODE$counter=$IP" >> /home/ec2-user/.bashrc; (( counter++ )); done

echo "Downloading and installing CockroachDB along with the Geo binaries"
if [ "${var.crdb_arm_release}" = "no" ]
then
  curl https://binaries.cockroachdb.com/cockroach-v${var.crdb_version}.linux-amd64.tgz | tar -xz && cp -i cockroach-v${var.crdb_version}.linux-amd64/cockroach /usr/local/bin/
  mkdir -p /usr/local/lib/cockroach
  cp -i cockroach-v${var.crdb_version}.linux-amd64/lib/libgeos.so /usr/local/lib/cockroach/
  cp -i cockroach-v${var.crdb_version}.linux-amd64/lib/libgeos_c.so /usr/local/lib/cockroach/
else
  curl https://binaries.cockroachdb.com/cockroach-v${var.crdb_version}.linux-arm64.tgz | tar -xz && cp -i cockroach-v${var.crdb_version}.linux-arm64/cockroach /usr/local/bin/
  mkdir -p /usr/local/lib/cockroach
  cp -i cockroach-v${var.crdb_version}.linux-arm64/lib/libgeos.so /usr/local/lib/cockroach/
  cp -i cockroach-v${var.crdb_version}.linux-arm64/lib/libgeos_c.so /usr/local/lib/cockroach/
fi

echo "Creating the public and private keys"
su ec2-user -c 'mkdir /home/ec2-user/certs; mkdir /home/ec2-user/my-safe-directory'
echo '${local.tls_private_key}' >> /home/ec2-user/my-safe-directory/ca.key
echo '${local.tls_public_key}' >> /home/ec2-user/certs/ca.pub
echo '${local.tls_cert}}' >> /home/ec2-user/certs/ca.crt
echo "Changing ownership on permissions on keys and certs"
chown ec2-user:ec2-user /home/ec2-user/certs/ca.crt
chown ec2-user:ec2-user /home/ec2-user/certs/ca.pub
chown ec2-user:ec2-user /home/ec2-user/my-safe-directory/ca.key
chmod 640 /home/ec2-user/certs/ca.crt
chmod 640 /home/ec2-user/certs/ca.pub
chmod 600 /home/ec2-user/my-safe-directory/ca.key     
echo "Copying the ca.key to .ssh/id_rsa, generating the public key and adding it to authorized keys for passwordless ssh between nodes"
cp /home/ec2-user/my-safe-directory/ca.key /home/ec2-user/.ssh/id_rsa
ssh-keygen -y -f /home/ec2-user/.ssh/id_rsa >> /home/ec2-user/.ssh/authorized_keys
chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa

echo "Creating the systemd service file"
echo '[Unit]' > /etc/systemd/system/securecockroachdb.service
echo 'Description=Cockroach Database cluster node' >> /etc/systemd/system/securecockroachdb.service
echo 'Requires=network.target' >> /etc/systemd/system/securecockroachdb.service
echo '[Service]' >> /etc/systemd/system/securecockroachdb.service
echo 'Type=notify' >> /etc/systemd/system/securecockroachdb.service
echo 'WorkingDirectory=/home/ec2-user' >> /etc/systemd/system/securecockroachdb.service
echo 'ExecStart=/usr/local/bin/cockroach start --locality=region="${local.subnet_map[local.interface_map[aws_network_interface.crdb[count.index].id].subnet_id].region}",zone="${local.subnet_map[local.interface_map[aws_network_interface.crdb[count.index].id].subnet_id].availability_zone}" --certs-dir=certs --advertise-addr=${local.interface_map[aws_network_interface.crdb[count.index].id].private_ip} --join=${local.join_string} --max-offset=250ms --store=/mnt/crdb-data' >> /etc/systemd/system/securecockroachdb.service
echo 'TimeoutStopSec=300' >> /etc/systemd/system/securecockroachdb.service
echo 'Restart=no' >> /etc/systemd/system/securecockroachdb.service
echo 'RestartSec=10' >> /etc/systemd/system/securecockroachdb.service
echo 'StandardOutput=syslog' >> /etc/systemd/system/securecockroachdb.service
echo 'StandardError=syslog' >> /etc/systemd/system/securecockroachdb.service
echo 'SyslogIdentifier=cockroach' >> /etc/systemd/system/securecockroachdb.service
echo 'User=ec2-user' >> /etc/systemd/system/securecockroachdb.service
echo '[Install]' >> /etc/systemd/system/securecockroachdb.service
echo 'WantedBy=default.target' >> /etc/systemd/system/securecockroachdb.service

echo "Creating the CREATENODECERT bashrc function"
echo "CREATENODECERT() {" >> /home/ec2-user/.bashrc
echo "  cockroach cert create-node \\" >> /home/ec2-user/.bashrc
echo '  $ip_local \' >> /home/ec2-user/.bashrc
echo '  $ip_public \' >> /home/ec2-user/.bashrc
echo "  localhost \\" >> /home/ec2-user/.bashrc
echo "  127.0.0.1 \\" >> /home/ec2-user/.bashrc
echo "Adding haproxy to the CREATENODECERT function if var.include_ha_proxy is yes"
if [ "${var.include_ha_proxy}" = "yes" ]; then echo "  ${aws_network_interface.haproxy[0].private_ip} \\" >> /home/ec2-user/.bashrc; fi
echo "  --certs-dir=certs \\" >> /home/ec2-user/.bashrc
echo "  --ca-key=my-safe-directory/ca.key" >> /home/ec2-user/.bashrc
echo "}" >> /home/ec2-user/.bashrc

echo "Creating the CREATEROOTCERT bashrc function"
echo "CREATEROOTCERT() {" >> /home/ec2-user/.bashrc
echo "  cockroach cert create-client \\" >> /home/ec2-user/.bashrc
echo '  root \' >> /home/ec2-user/.bashrc
echo "  --certs-dir=certs \\" >> /home/ec2-user/.bashrc
echo "  --ca-key=my-safe-directory/ca.key" >> /home/ec2-user/.bashrc
echo "}" >> /home/ec2-user/.bashrc   

echo "Creating the STARTCRDB, STOPCRDB, KILLCRDB, KILLAZCRDB, STARTAZCRDB bashrc functions"
echo "STARTCRDB() {" >> /home/ec2-user/.bashrc
echo "  sudo systemctl start securecockroachdb" >> /home/ec2-user/.bashrc
echo " }" >> /home/ec2-user/.bashrc
echo "STOPCRDB() {" >> /home/ec2-user/.bashrc
echo "  sudo systemctl stop securecockroachdb" >> /home/ec2-user/.bashrc
echo " }" >> /home/ec2-user/.bashrc
echo "KILLCRDB() {" >> /home/ec2-user/.bashrc
echo "  sudo systemctl kill -s SIGKILL securecockroachdb" >> /home/ec2-user/.bashrc
echo " }" >> /home/ec2-user/.bashrc
echo 'KILLAZCRDB() {' >> /home/ec2-user/.bashrc
echo 'for ip in $CLUSTER_PRIVATE_IP_LIST; do' >> /home/ec2-user/.bashrc
echo '  echo "Connecting to $ip..."' >> /home/ec2-user/.bashrc
echo '  ssh -o ConnectTimeout=5 "$ip" "KILLCRDB"' >> /home/ec2-user/.bashrc
echo '  echo "CRDB Killed on  $ip"' >> /home/ec2-user/.bashrc
echo 'done' >> /home/ec2-user/.bashrc
echo '}' >> /home/ec2-user/.bashrc
echo 'STOPAZCRDB() {' >> /home/ec2-user/.bashrc
echo 'for ip in $CLUSTER_PRIVATE_IP_LIST; do' >> /home/ec2-user/.bashrc
echo '  echo "Connecting to $ip..."' >> /home/ec2-user/.bashrc
echo '  ssh -o ConnectTimeout=5 "$ip" "STOPCRDB"' >> /home/ec2-user/.bashrc
echo '  echo "CRDB Stopped on  $ip"' >> /home/ec2-user/.bashrc
echo 'done' >> /home/ec2-user/.bashrc
echo '}' >> /home/ec2-user/.bashrc
echo 'STARTAZCRDB() {' >> /home/ec2-user/.bashrc
echo 'for ip in $CLUSTER_PRIVATE_IP_LIST; do' >> /home/ec2-user/.bashrc
echo '  echo "Connecting to $ip..."' >> /home/ec2-user/.bashrc
echo '  ssh -o ConnectTimeout=5 "$ip" "STARTCRDB"' >> /home/ec2-user/.bashrc
echo '  echo "CRDB Started on  $ip"' >> /home/ec2-user/.bashrc
echo 'done' >> /home/ec2-user/.bashrc
echo '}' >> /home/ec2-user/.bashrc

echo "Creating the node cert, root cert and starting CRDB"
sleep 20; su ec2-user -lc 'CREATENODECERT; CREATEROOTCERT; STARTCRDB'

echo "SETCRDBVARS() {" >> /home/ec2-user/.bashrc
echo "  cockroach node status | awk -F ':' 'FNR > 1 { print \$1 }' | awk '{ print \$1, \$2 }' |  while read line; do" >> /home/ec2-user/.bashrc
echo "    node_number=\`echo \$line | awk '{ print \$1 }'\`" >> /home/ec2-user/.bashrc
echo "    variable_name=CRDBNODE\$node_number" >> /home/ec2-user/.bashrc
echo "    ip=\`echo \$line | awk '{ print \$2 }'\`" >> /home/ec2-user/.bashrc
echo "    echo export \$variable_name=\$ip >> crdb_node_list" >> /home/ec2-user/.bashrc
echo "  done" >> /home/ec2-user/.bashrc
echo "  source ./crdb_node_list" >> /home/ec2-user/.bashrc
echo "}" >> /home/ec2-user/.bashrc

echo "Validating if init needs to be run"
echo "RunInit: ${var.run_init}  Count.Index: ${count.index}   Count: ${var.crdb_nodes}"
if [[ '${var.run_init}' = 'yes' && ${count.index + 1} -eq ${var.crdb_nodes} ]]; then echo "Initializing Cockroach Database" && su ec2-user -lc 'cockroach init'; fi
if [[ '${var.run_init}' = 'yes' && ${count.index + 1} -eq ${var.crdb_nodes} && ${var.create_admin_user} = 'yes' ]]; then echo "Creating admin user ${var.admin_user_name}" && su ec2-user -lc 'cockroach sql --execute "create user ${var.admin_user_name}; grant admin to ${var.admin_user_name}"'; fi
if [[ '${var.run_init}' = 'yes' && ${count.index + 1} -eq ${var.crdb_nodes} && ${var.install_enterprise_keys} = 'yes' ]]; then echo "Installing enterprise license keys: ${var.cluster_organization} & ${var.enterprise_license}" && su ec2-user -lc 'cockroach sql --execute "SET CLUSTER SETTING cluster.organization = '\''${var.cluster_organization}'\''; "'; fi
if [[ '${var.run_init}' = 'yes' && ${count.index + 1} -eq ${var.crdb_nodes} && ${var.install_enterprise_keys} = 'yes' ]]; then echo "Installing enterprise license keys: ${var.cluster_organization} & ${var.enterprise_license}" && su ec2-user -lc 'cockroach sql --execute "SET CLUSTER SETTING enterprise.license = '\''${var.enterprise_license}'\''; "'; fi
EOF
}

    # if [[ '${var.run_init}' = 'yes' && ${count.index + 1} -eq ${var.crdb_nodes} && ${var.install_enterprise_keys} = 'yes' ]]; then echo "Installing enterprise license keys" && su ec2-user -lc 'cockroach sql --execute "SET CLUSTER SETTING cluster.organization = '${var.cluster_organization}'; SET CLUSTER SETTING enterprise.license = '${var.enterprise_license}'"'; fi

